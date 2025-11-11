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
      print('Error getting cloud timestamp: $e');
      return null;
    }
  }

  // Smart sync based on timestamps
  Future<String> smartSync() async {
    if (!_authService.isLoggedIn) {
      throw 'Please login first to sync';
    }

    try {
      final localProfile = _dataManager.userProfile;
      final cloudLastSync = await _getCloudLastSyncedAt();

      // Nếu cloud chưa có data hoặc local newer -> upload
      if (cloudLastSync == null || localProfile.lastUpdatedAt.isAfter(cloudLastSync)) {
        await uploadToCloud();
        return 'Uploaded local data to cloud';
      } 
      // Nếu cloud newer -> download
      else if (cloudLastSync.isAfter(localProfile.lastSyncedAt)) {
        await downloadFromCloud();
        return 'Downloaded data from cloud';
      }
      // Nếu đã sync -> no action
      else {
        return 'Data already synced';
      }
    } catch (e) {
      print('Smart sync error: $e');
      throw 'Sync failed: $e';
    }
  }

  // Upload essential data to cloud (Profile + Settings + Tasks)
  Future<void> uploadToCloud() async {
    if (_userDoc == null) throw 'User not logged in';

    try {
      final now = DateTime.now();
      
      // Prepare essential data
      final allData = {
        'userProfile': _profileToMap(_dataManager.userProfile),
        'userSettings': _settingsToMap(_dataManager.userSettings),
        'scheduleTasks': _dataManager.scheduleTasks.map(_taskToMap).toList(),
        'lastSyncedAt': Timestamp.fromDate(now),
      };

      // Upload to Firebase
      await _userDoc!.set(allData, SetOptions(merge: true));

      // Update local lastSyncedAt
      final updatedProfile = _dataManager.userProfile.copyWith(lastSyncedAt: now);
      await _dataManager.saveUserProfile(updatedProfile);
      
      print('Successfully uploaded data to cloud');
    } catch (e) {
      print('Upload error: $e');
      throw 'Upload failed: $e';
    }
  }

  // Download essential data from cloud
  Future<void> downloadFromCloud() async {
    if (_userDoc == null) throw 'User not logged in';

    try {
      final doc = await _userDoc!.get();
      if (!doc.exists) {
        throw 'No cloud data found';
      }

      final data = doc.data() as Map<String, dynamic>;
      final now = DateTime.now();

      // Restore user profile
      if (data['userProfile'] != null) {
        final profile = _profileFromMap(data['userProfile']);
        await _dataManager.saveUserProfile(profile.copyWith(lastSyncedAt: now));
      }

      // Restore user settings
      if (data['userSettings'] != null) {
        final settings = _settingsFromMap(data['userSettings']);
        await _dataManager.saveUserSettings(settings);
      }

      // Restore schedule tasks
      if (data['scheduleTasks'] != null) {
        final tasks = (data['scheduleTasks'] as List)
            .map((e) => _taskFromMap(e))
            .toList();
        await _dataManager.saveScheduleTasks(tasks);
      }

      print('Successfully downloaded data from cloud');
    } catch (e) {
      print('Download error: $e');
      throw 'Download failed: $e';
    }
  }

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


}