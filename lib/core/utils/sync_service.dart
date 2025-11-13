import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'data_manager.dart';
import '../../models/index.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final DataManager _dataManager = DataManager();

  // Get user's document reference
  DocumentReference? get _userDoc {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  // Get last synced timestamp from cloud
  Future<DateTime?> _getCloudLastSyncedAt() async {
    if (_userDoc == null) return null;
    
    try {
      final doc = await _userDoc!.get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>?;
      final timestamp = data?['lastSyncedAt'] as Timestamp?;
      return timestamp?.toDate();
    } catch (e) {
      return null;
    }
  }

  // Smart sync based on timestamps - sync all data types
  Future<String> smartSync() async {
    if (!_authService.isLoggedIn) {
      throw 'Please login first to sync';
    }

    // Check if user can sync (not guest)
    if (!await _dataManager.canSync) {
      throw 'Guest users cannot sync. Please create an account.';
    }

    try {
      // Update DataManager with Firebase UID if needed
      await _ensureUserIdSync();
      
      final localProfile = _dataManager.userProfile;
      final localLastUpdated = localProfile.lastUpdatedAt;
      final localLastSynced = localProfile.lastSyncedAt;
      final cloudLastSync = await _getCloudLastSyncedAt();

      // Nếu cloud chưa có data -> upload (tài khoản mới)
      if (cloudLastSync == null) {
        await uploadToCloud();
        return 'Uploaded local data to cloud (new account)';
      } 
      // Nếu cloud đã sync trước local -> download (tài khoản cũ)
      else if (cloudLastSync.isAfter(localLastSynced)) {
        await downloadFromCloud();
        return 'Downloaded data from cloud (existing account)';
      }
      // Nếu local có cập nhật -> upload
      else if (localLastUpdated.isAfter(localLastSynced)) {
        await uploadToCloud();
        return 'Uploaded local data to cloud';
      }
      
      // Nếu đã sync và không có thay đổi
      return 'All data already synced';
    } catch (e) {
      throw 'Sync failed: $e';
    }
  }
  
  // Ensure DataManager has correct Firebase UID
  Future<void> _ensureUserIdSync() async {
    if (!_authService.isLoggedIn) return;
    
    final currentUser = _authService.currentUser!;
    final localProfile = _dataManager.userProfile;
    
    // If local profile doesn't have Firebase UID, update it
    if (localProfile.id != currentUser.uid) {
      await _dataManager.switchToLoggedInUser(
        userId: currentUser.uid,
        email: currentUser.email!,
        displayName: currentUser.displayName,
        hasCloudData: await _hasCloudData(),
      );
    }
  }
  
  // Check if user has existing data in cloud
  Future<bool> _hasCloudData() async {
    if (_userDoc == null) return false;
    
    try {
      final doc = await _userDoc!.get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Upload all data to cloud using separate collections
  Future<void> uploadAllDataToCloud() async {
    if (_userDoc == null) throw 'User not logged in';

    final now = DateTime.now();
    final userId = _authService.currentUser!.uid;

    try {
      // 1. Upload User Profile to main users collection
      await _userDoc!.set({
        'userProfile': _profileToMap(_dataManager.userProfile),
        'lastSyncedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));

      // 2. Upload User Settings to separate collection
      await _firestore
          .collection('userSettings')
          .doc(userId)
          .set(_settingsToMap(_dataManager.userSettings));

      // 3. Upload Schedule Tasks to separate collection
      final tasksCollection = _firestore
          .collection('scheduleTasks')
          .doc(userId)
          .collection('tasks');
      
      // Clear existing tasks first
      final existingTasks = await tasksCollection.get();
      for (var doc in existingTasks.docs) {
        await doc.reference.delete();
      }
      
      // Add current tasks
      final tasks = _dataManager.scheduleTasks;
      for (int i = 0; i < tasks.length; i++) {
        await tasksCollection.doc('task_$i').set(_taskToMap(tasks[i]));
      }

      // 4. Upload Emotion Diaries (simplified for now)
      final diariesCollection = _firestore
          .collection('emotionDiaries')
          .doc(userId);
      
      await diariesCollection.set({
        'count': _dataManager.emotionDiaries.length,
        'lastUpdated': Timestamp.fromDate(now),
      });

      // 5. Upload Progress Data (simplified for now)
      await _firestore
          .collection('progressData')
          .doc(userId)
          .set({
            'hasGarden': _dataManager.gardenProgress != null,
            'hasAquarium': _dataManager.aquariumProgress != null,
            'hasPainting': _dataManager.paintingProgress != null,
            'hasMusic': _dataManager.musicProgress != null,
            'lastUpdated': Timestamp.fromDate(now),
          });

      // Update local lastSyncedAt
      final updatedProfile = _dataManager.userProfile.copyWith(lastSyncedAt: now);
      await _dataManager.saveUserProfile(updatedProfile);
      
    } catch (e) {
      throw 'Upload failed: $e';
    }
  }

  // Legacy method for backward compatibility
  Future<void> uploadToCloud() => uploadAllDataToCloud();

  // Download all data from cloud using separate collections
  Future<void> downloadAllDataFromCloud() async {
    if (_userDoc == null) throw 'User not logged in';

    final userId = _authService.currentUser!.uid;
    final now = DateTime.now();

    try {

      // 1. Download User Profile
      final userDoc = await _userDoc!.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData['userProfile'] != null) {
          final profile = _profileFromMap(userData['userProfile']);
          await _dataManager.saveUserProfile(profile.copyWith(lastSyncedAt: now));
        }
      }

      // 2. Download User Settings
      final settingsDoc = await _firestore
          .collection('userSettings')
          .doc(userId)
          .get();
      if (settingsDoc.exists) {
        final settings = _settingsFromMap(settingsDoc.data()!);
        await _dataManager.saveUserSettings(settings);
      }

      // 3. Download Schedule Tasks
      final tasksSnapshot = await _firestore
          .collection('scheduleTasks')
          .doc(userId)
          .collection('tasks')
          .get();
      
      final tasks = tasksSnapshot.docs
          .map((doc) => _taskFromMap(doc.data()))
          .toList();
      await _dataManager.saveScheduleTasks(tasks);

      // 4. Download Emotion Diaries (simplified for now)
      final diariesDoc = await _firestore
          .collection('emotionDiaries')
          .doc(userId)
          .get();
      
      // For now, just clear local diaries since we need proper model structure
      if (diariesDoc.exists) {
        await _dataManager.saveEmotionDiaries([]);
      }

      // 5. Download Progress Data (simplified for now)  
      // Skip progress data for now until we implement proper conversion
      
    } catch (e) {
      throw 'Download failed: $e';
    }
  }

  // Legacy method for backward compatibility
  Future<void> downloadFromCloud() => downloadAllDataFromCloud();

  // ==================== CONVERSION HELPERS ====================
  
  Map<String, dynamic> _profileToMap(UserProfile profile) {
    return {
      'id': profile.id,
      'username': profile.username,
      'email': profile.email,
      'name': profile.name,
      'mascotName': profile.mascotName,
      'createdAt': Timestamp.fromDate(profile.createdAt),
      'lastSyncedAt': Timestamp.fromDate(profile.lastSyncedAt),
      'lastUpdatedAt': Timestamp.fromDate(profile.lastUpdatedAt),
      'unlockedScenes': profile.unlockedScenes.map((key, value) => 
          MapEntry('${key.sceneSet.name}_${key.sceneType.name}', value)),
      'currentPoints': profile.currentPoints,
      'totalPoints': profile.totalPoints,
      'lastPointsClaimDate': profile.lastPointsClaimDate != null 
          ? Timestamp.fromDate(profile.lastPointsClaimDate!) 
          : null,
    };
  }

  UserProfile _profileFromMap(Map<String, dynamic> map) {
    // Convert unlockedScenes back
    final unlockedScenes = <SceneKey, bool>{};
    if (map['unlockedScenes'] != null) {
      (map['unlockedScenes'] as Map<String, dynamic>).forEach((key, value) {
        final parts = key.split('_');
        if (parts.length == 2) {
          final sceneSet = SceneSet.values.firstWhere(
            (s) => s.name == parts[0],
            orElse: () => SceneSet.defaultSet,
          );
          final sceneType = SceneType.values.firstWhere(
            (s) => s.name == parts[1],
            orElse: () => SceneType.livingRoom,
          );
          unlockedScenes[SceneKey(sceneSet, sceneType)] = value as bool;
        }
      });
    }

    return UserProfile(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      mascotName: map['mascotName'] ?? 'Cat',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastSyncedAt: (map['lastSyncedAt'] as Timestamp).toDate(),
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp).toDate(),
      unlockedScenes: unlockedScenes,
      currentPoints: map['currentPoints'] ?? 0,
      totalPoints: map['totalPoints'] ?? 0,
      lastPointsClaimDate: map['lastPointsClaimDate'] != null 
          ? (map['lastPointsClaimDate'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> _settingsToMap(UserSettings settings) {
    return {
      'currentTheme': settings.currentTheme,
      'currentLanguage': settings.currentLanguage,
      'currentScenes': settings.currentScenes.map((scene) => 
          '${scene.sceneSet.name}_${scene.sceneType.name}').toList(),
      'bgm': settings.bgm,
      'bgmVolume': settings.bgmVolume,
      'sfxEnabled': settings.sfxEnabled,
      'sfxVolume': settings.sfxVolume,
      'sleepReminderEnabled': settings.sleepReminderEnabled,
      'sleepReminderTimeMinutes': settings.sleepReminderTimeMinutes,
      'taskReminderEnabled': settings.taskReminderEnabled,
      'taskReminderTime': settings.taskReminderTime,
    };
  }

  UserSettings _settingsFromMap(Map<String, dynamic> map) {
    // Parse currentScenes back
    final currentScenes = <SceneKey>[];
    if (map['currentScenes'] != null) {
      for (String sceneString in map['currentScenes']) {
        final parts = sceneString.split('_');
        if (parts.length >= 2) {
          final sceneSet = SceneSet.values.firstWhere(
            (s) => s.name == parts[0],
            orElse: () => SceneSet.defaultSet,
          );
          final sceneType = SceneType.values.firstWhere(
            (s) => s.name == parts[1],
            orElse: () => SceneType.livingRoom,
          );
          currentScenes.add(SceneKey(sceneSet, sceneType));
        }
      }
    }

    return UserSettings(
      currentTheme: map['currentTheme'] ?? 'pastel_blue_breeze',
      currentLanguage: map['currentLanguage'] ?? 'vi',
      currentScenes: currentScenes.isNotEmpty ? currentScenes : [
        SceneKey(SceneSet.defaultSet, SceneType.livingRoom),
        SceneKey(SceneSet.defaultSet, SceneType.garden),
        SceneKey(SceneSet.defaultSet, SceneType.aquarium),
        SceneKey(SceneSet.defaultSet, SceneType.paintingRoom),
        SceneKey(SceneSet.defaultSet, SceneType.musicRoom),
      ],
      bgm: map['bgm'] ?? 'Lofi Beats',
      bgmVolume: map['bgmVolume'] ?? 50,
      sfxEnabled: map['sfxEnabled'] ?? true,
      sfxVolume: map['sfxVolume'] ?? 50,
      sleepReminderEnabled: map['sleepReminderEnabled'] ?? false,
      sleepReminderTimeMinutes: map['sleepReminderTimeMinutes'] ?? 1320,
      taskReminderEnabled: map['taskReminderEnabled'] ?? true,
      taskReminderTime: map['taskReminderTime'] ?? 15,
    );
  }

  Map<String, dynamic> _taskToMap(ScheduleTask task) {
    return {
      'title': task.title,
      'startTimeMinutes': task.startTimeMinutes,
      'endTimeMinutes': task.endTimeMinutes,
      'isCompleted': task.isCompleted,
    };
  }

  ScheduleTask _taskFromMap(Map<String, dynamic> map) {
    return ScheduleTask(
      title: map['title'] ?? '',
      startTimeMinutes: map['startTimeMinutes'] ?? 0,
      endTimeMinutes: map['endTimeMinutes'] ?? 60,
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  // Logout and sync data before clearing
  Future<void> logoutAndSync() async {
    try {
      // Sync all data to cloud before logout if logged in
      if (_authService.isLoggedIn) {
        await uploadAllDataToCloud();
        
        // Logout from Firebase
        await _authService.logout();
        
        // Clear all local data and reset to defaults
        await _dataManager.clearAll();
        
      }
    } catch (e) {
      // Still logout even if sync fails
      await _authService.logout();
      await _dataManager.clearAll();
      throw 'Logout completed but sync failed: $e';
    }
  }


}