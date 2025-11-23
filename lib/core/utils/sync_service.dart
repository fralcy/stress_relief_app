import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'data_manager.dart';
import 'encryption_util.dart';
import '../../models/index.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final DataManager _dataManager = DataManager();
  final EncryptionUtil _encryption = EncryptionUtil.instance;

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
      final canSyncResult = await _dataManager.canSync;
      throw 'Guest users cannot sync. Please create an account. (canSync: $canSyncResult, isLoggedIn: ${_authService.isLoggedIn})';
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
      // Nếu cloud đã sync trước local với buffer 2 giây -> download (tài khoản cũ)
      else if (cloudLastSync.isAfter(localLastSynced.add(Duration(seconds: 2)))) {
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
      // Update local lastSyncedAt FIRST to ensure same timestamp
      final updatedProfile = _dataManager.userProfile.copyWith(lastSyncedAt: now);
      await _dataManager.saveUserProfile(updatedProfile);
      
      // 1. Upload User Profile to main users collection
      await _userDoc!.set({
        'userProfile': _profileToMap(updatedProfile),
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
      
      // Add current tasks (encrypted)
      final tasks = _dataManager.scheduleTasks;
      if (tasks.isNotEmpty) {
        try {
          final taskMaps = tasks.map((task) => _taskToMap(task)).toList();
          final encryptedTasks = _encryption.encryptList(taskMaps);
          await tasksCollection.doc('encrypted_data').set({
            'data': encryptedTasks,
            'count': tasks.length,
            'lastUpdated': Timestamp.fromDate(now),
          });
        } catch (e) {
          // Fallback to unencrypted if encryption fails
          for (int i = 0; i < tasks.length; i++) {
            await tasksCollection.doc('task_$i').set(_taskToMap(tasks[i]));
          }
        }
      }

      // 4. Upload Emotion Diaries (encrypted)
      final diariesCollection = _firestore
          .collection('emotionDiaries')
          .doc(userId);
      
      final diaries = _dataManager.emotionDiaries;
      if (diaries.isNotEmpty) {
        try {
          final diaryMaps = diaries.map((diary) => _diaryToMap(diary)).toList();
          final encryptedDiaries = _encryption.encryptList(diaryMaps);
          await diariesCollection.set({
            'data': encryptedDiaries,
            'count': diaries.length,
            'lastUpdated': Timestamp.fromDate(now),
          });
        } catch (e) {
          // Fallback to count only if encryption fails
          await diariesCollection.set({
            'count': diaries.length,
            'lastUpdated': Timestamp.fromDate(now),
          });
        }
      } else {
        await diariesCollection.set({
          'count': 0,
          'lastUpdated': Timestamp.fromDate(now),
        });
      }

      // 5. Upload Garden Progress
      await _firestore
          .collection('gardenProgress')
          .doc(userId)
          .set(_gardenProgressToMap(_dataManager.gardenProgress));

      // 6. Upload Aquarium Progress
      await _firestore
          .collection('aquariumProgress')
          .doc(userId)
          .set(_aquariumProgressToMap(_dataManager.aquariumProgress));

      // 7. Upload Painting Progress
      await _firestore
          .collection('paintingProgress')
          .doc(userId)
          .set(_paintingProgressToMap(_dataManager.paintingProgress));

      // 8. Upload Music Progress
      await _firestore
          .collection('musicProgress')
          .doc(userId)
          .set(_musicProgressToMap(_dataManager.musicProgress));
      
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

      // 3. Download Schedule Tasks (decrypt if available)
      final tasksSnapshot = await _firestore
          .collection('scheduleTasks')
          .doc(userId)
          .collection('tasks')
          .get();
      
      List<ScheduleTask> tasks = [];
      
      // Try to get encrypted data first
      final encryptedTaskDoc = tasksSnapshot.docs
          .where((doc) => doc.id == 'encrypted_data')
          .firstOrNull;
      
      if (encryptedTaskDoc != null && encryptedTaskDoc.exists) {
        try {
          final encryptedData = encryptedTaskDoc.data()['data'] as String?;
          if (encryptedData != null && encryptedData.isNotEmpty) {
            final decryptedList = _encryption.decryptList(encryptedData);
            tasks = decryptedList.map((map) => _taskFromMap(map as Map<String, dynamic>)).toList();
          }
        } catch (e) {
          // If decryption fails, fall back to individual task documents
          tasks = tasksSnapshot.docs
              .where((doc) => doc.id != 'encrypted_data')
              .map((doc) => _taskFromMap(doc.data()))
              .toList();
        }
      } else {
        // Legacy: read individual task documents
        tasks = tasksSnapshot.docs
            .map((doc) => _taskFromMap(doc.data()))
            .toList();
      }
      
      await _dataManager.saveScheduleTasks(tasks);

      // 4. Download Emotion Diaries (decrypt if available)
      final diariesDoc = await _firestore
          .collection('emotionDiaries')
          .doc(userId)
          .get();
      
      List<EmotionDiary> diaries = [];
      
      if (diariesDoc.exists) {
        try {
          final data = diariesDoc.data() as Map<String, dynamic>;
          final encryptedData = data['data'] as String?;
          
          if (encryptedData != null && encryptedData.isNotEmpty) {
            final decryptedList = _encryption.decryptList(encryptedData);
            diaries = decryptedList.map((map) => _diaryFromMap(map as Map<String, dynamic>)).toList();
          }
        } catch (e) {
          // If decryption fails, keep empty list
          diaries = [];
        }
      }
      
      await _dataManager.saveEmotionDiaries(diaries);

      // 5. Download Garden Progress
      final gardenDoc = await _firestore
          .collection('gardenProgress')
          .doc(userId)
          .get();
      if (gardenDoc.exists) {
        final gardenProgress = _gardenProgressFromMap(gardenDoc.data()!);
        if (gardenProgress != null) {
          await _dataManager.saveGardenProgress(gardenProgress);
        }
      }

      // 6. Download Aquarium Progress
      final aquariumDoc = await _firestore
          .collection('aquariumProgress')
          .doc(userId)
          .get();
      if (aquariumDoc.exists) {
        final aquariumProgress = _aquariumProgressFromMap(aquariumDoc.data()!);
        if (aquariumProgress != null) {
          await _dataManager.saveAquariumProgress(aquariumProgress);
        }
      }

      // 7. Download Painting Progress
      final paintingDoc = await _firestore
          .collection('paintingProgress')
          .doc(userId)
          .get();
      if (paintingDoc.exists) {
        final paintingProgress = _paintingProgressFromMap(paintingDoc.data()!);
        if (paintingProgress != null) {
          await _dataManager.savePaintingProgress(paintingProgress);
        }
      }

      // 8. Download Music Progress
      final musicDoc = await _firestore
          .collection('musicProgress')
          .doc(userId)
          .get();
      if (musicDoc.exists) {
        final musicProgress = _musicProgressFromMap(musicDoc.data()!);
        if (musicProgress != null) {
          await _dataManager.saveMusicProgress(musicProgress);
        }
      }
      
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

  Map<String, dynamic> _diaryToMap(EmotionDiary diary) {
    return {
      'date': diary.date.toIso8601String(),
      'q1': diary.q1,
      'q2': diary.q2,
      'q3': diary.q3,
      'notes': diary.notes,
    };
  }

  EmotionDiary _diaryFromMap(Map<String, dynamic> map) {
    return EmotionDiary(
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      q1: map['q1'] ?? 3,
      q2: map['q2'] ?? 3,
      q3: map['q3'] ?? 3,
      notes: map['notes'] ?? '',
    );
  }

  // ==================== GARDEN PROGRESS CONVERSION ====================
  
  Map<String, dynamic> _gardenProgressToMap(GardenProgress? progress) {
    if (progress == null) {
      return {
        'hasData': false,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      };
    }

    // Flatten 2D plots array to avoid nested arrays
    final flatPlots = <String, dynamic>{};
    for (int row = 0; row < progress.plots.length; row++) {
      for (int col = 0; col < progress.plots[row].length; col++) {
        flatPlots['${row}_$col'] = _plantCellToMap(progress.plots[row][col]);
      }
    }

    return {
      'hasData': true,
      'plots': flatPlots,
      'plotsRows': progress.plots.length,
      'plotsCols': progress.plots.isNotEmpty ? progress.plots[0].length : 0,
      'inventory': progress.inventory,
      'earnings': progress.earnings,
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
    };
  }

  GardenProgress? _gardenProgressFromMap(Map<String, dynamic> map) {
    if (!(map['hasData'] ?? false)) return null;

    final plotsData = map['plots'] as Map<String, dynamic>?;
    if (plotsData == null) return null;

    final rows = map['plotsRows'] as int? ?? 0;
    final cols = map['plotsCols'] as int? ?? 0;
    
    if (rows == 0 || cols == 0) return null;

    // Reconstruct 2D array from flat map
    final plots = List.generate(rows, (row) => 
      List.generate(cols, (col) {
        final cellData = plotsData['${row}_$col'] as Map<String, dynamic>?;
        return cellData != null 
          ? _plantCellFromMap(cellData)
          : PlantCell(
              plantType: null,
              growthStage: 0,
              lastWatered: DateTime.now(),
              needsWater: false,
              hasPest: false,
              plantedAt: null,
            ); // Default empty cell
      })
    );

    return GardenProgress(
      plots: plots,
      inventory: Map<String, int>.from(map['inventory'] ?? {}),
      earnings: map['earnings'] ?? 0,
    );
  }

  Map<String, dynamic> _plantCellToMap(PlantCell cell) {
    return {
      'plantType': cell.plantType,
      'growthStage': cell.growthStage,
      'lastWatered': Timestamp.fromDate(cell.lastWatered),
      'needsWater': cell.needsWater,
      'hasPest': cell.hasPest,
      'plantedAt': cell.plantedAt != null ? Timestamp.fromDate(cell.plantedAt!) : null,
    };
  }

  PlantCell _plantCellFromMap(Map<String, dynamic> map) {
    return PlantCell(
      plantType: map['plantType'],
      growthStage: map['growthStage'] ?? 0,
      lastWatered: (map['lastWatered'] as Timestamp).toDate(),
      needsWater: map['needsWater'] ?? false,
      hasPest: map['hasPest'] ?? false,
      plantedAt: map['plantedAt'] != null ? (map['plantedAt'] as Timestamp).toDate() : null,
    );
  }

  // ==================== AQUARIUM PROGRESS CONVERSION ====================
  
  Map<String, dynamic> _aquariumProgressToMap(AquariumProgress? progress) {
    if (progress == null) {
      return {
        'hasData': false,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      };
    }

    return {
      'hasData': true,
      'fishes': progress.fishes.map((fish) => _fishToMap(fish)).toList(),
      'lastFed': Timestamp.fromDate(progress.lastFed),
      'earnings': progress.earnings,
      'lastClaimed': progress.lastClaimed != null 
          ? Timestamp.fromDate(progress.lastClaimed!) : null,
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
    };
  }

  AquariumProgress? _aquariumProgressFromMap(Map<String, dynamic> map) {
    if (!(map['hasData'] ?? false)) return null;

    final fishesData = map['fishes'] as List<dynamic>?;
    if (fishesData == null) return null;

    final fishes = fishesData.map((fishData) => 
      _fishFromMap(fishData as Map<String, dynamic>)
    ).toList();

    return AquariumProgress(
      fishes: fishes,
      lastFed: (map['lastFed'] as Timestamp).toDate(),
      earnings: map['earnings'] ?? 0,
      lastClaimed: map['lastClaimed'] != null 
          ? (map['lastClaimed'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> _fishToMap(Fish fish) {
    return {
      'type': fish.type,
    };
  }

  Fish _fishFromMap(Map<String, dynamic> map) {
    return Fish(
      type: map['type'] ?? 'betta',
    );
  }

  // ==================== PAINTING PROGRESS CONVERSION ====================
  
  Map<String, dynamic> _paintingProgressToMap(PaintingProgress? progress) {
    if (progress == null) {
      return {
        'hasData': false,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      };
    }

    return {
      'hasData': true,
      'savedPaintings': progress.savedPaintings?.map((painting) => 
        _paintingToMap(painting)).toList() ?? [],
      'selected': progress.selected,
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
    };
  }

  PaintingProgress? _paintingProgressFromMap(Map<String, dynamic> map) {
    if (!(map['hasData'] ?? false)) return null;

    final paintingsData = map['savedPaintings'] as List<dynamic>?;
    List<Painting>? paintings;
    
    if (paintingsData != null && paintingsData.isNotEmpty) {
      paintings = paintingsData.map((paintingData) => 
        _paintingFromMap(paintingData as Map<String, dynamic>)
      ).toList();
    }

    return PaintingProgress(
      savedPaintings: paintings,
      selected: map['selected'] ?? 0,
    );
  }

  Map<String, dynamic> _paintingToMap(Painting painting) {
    // Flatten pixels 2D array to avoid nested arrays
    final flatPixels = <String, int>{};
    for (int row = 0; row < painting.pixels.length; row++) {
      for (int col = 0; col < painting.pixels[row].length; col++) {
        flatPixels['${row}_$col'] = painting.pixels[row][col];
      }
    }

    return {
      'name': painting.name,
      'pixels': flatPixels,
      'pixelsRows': painting.pixels.length,
      'pixelsCols': painting.pixels.isNotEmpty ? painting.pixels[0].length : 0,
      'createdAt': Timestamp.fromDate(painting.createdAt),
    };
  }

  Painting _paintingFromMap(Map<String, dynamic> map) {
    final flatPixels = Map<String, int>.from(map['pixels'] ?? {});
    final rows = map['pixelsRows'] as int? ?? 0;
    final cols = map['pixelsCols'] as int? ?? 0;
    
    // Reconstruct 2D pixels array from flat map
    final pixels = List.generate(rows, (row) => 
      List.generate(cols, (col) => 
        flatPixels['${row}_$col'] ?? 0
      )
    );

    return Painting(
      name: map['name'] ?? 'Untitled',
      pixels: pixels,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // ==================== MUSIC PROGRESS CONVERSION ====================
  
  Map<String, dynamic> _musicProgressToMap(MusicProgress? progress) {
    if (progress == null) {
      return {
        'hasData': false,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      };
    }

    return {
      'hasData': true,
      'savedTracks': progress.savedTracks.map((track) => 
        _musicTrackToMap(track)).toList(),
      'selected': progress.selected,
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
    };
  }

  MusicProgress? _musicProgressFromMap(Map<String, dynamic> map) {
    if (!(map['hasData'] ?? false)) return null;

    final tracksData = map['savedTracks'] as List<dynamic>?;
    if (tracksData == null) return null;

    final tracks = tracksData.map((trackData) => 
      _musicTrackFromMap(trackData as Map<String, dynamic>)
    ).toList();

    return MusicProgress(
      savedTracks: tracks,
      selected: map['selected'] ?? 0,
    );
  }

  Map<String, dynamic> _musicTrackToMap(MusicTrack track) {
    // Flatten tracks to avoid nested arrays
    final flatTracks = <String, dynamic>{};
    
    track.tracks.forEach((instrument, notes) {
      flatTracks['${instrument.name}_count'] = notes.length;
      for (int i = 0; i < notes.length; i++) {
        flatTracks['${instrument.name}_$i'] = _noteToMap(notes[i]);
      }
    });

    return {
      'name': track.name,
      'createdAt': Timestamp.fromDate(track.createdAt),
      'tracks': flatTracks,
      'instrumentNames': track.tracks.keys.map((i) => i.name).toList(),
    };
  }

  MusicTrack _musicTrackFromMap(Map<String, dynamic> map) {
    final flatTracks = Map<String, dynamic>.from(map['tracks'] ?? {});
    final instrumentNames = List<String>.from(map['instrumentNames'] ?? []);
    final tracks = <Instrument, List<Note>>{};
    
    for (String instrumentName in instrumentNames) {
      final instrument = Instrument.values.firstWhere(
        (i) => i.name == instrumentName,
        orElse: () => Instrument.key,
      );
      
      final noteCount = flatTracks['${instrumentName}_count'] as int? ?? 0;
      final notes = <Note>[];
      
      for (int i = 0; i < noteCount; i++) {
        final noteData = flatTracks['${instrumentName}_$i'] as Map<String, dynamic>?;
        if (noteData != null) {
          notes.add(_noteFromMap(noteData));
        }
      }
      
      tracks[instrument] = notes;
    }

    return MusicTrack(
      name: map['name'] ?? 'Untitled Track',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      tracks: tracks,
    );
  }

  Map<String, dynamic> _noteToMap(Note note) {
    return {
      'pitch': note.pitch,
      'startTimeMilliseconds': note.startTimeMilliseconds,
    };
  }

  Note _noteFromMap(Map<String, dynamic> map) {
    return Note(
      pitch: map['pitch'] ?? 'C4',
      startTimeMilliseconds: map['startTimeMilliseconds'] ?? 0,
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