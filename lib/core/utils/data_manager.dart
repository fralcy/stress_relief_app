import 'dart:math';
import '../../models/index.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'auth_service.dart';
import 'encryption_util.dart';

/// Singleton để quản lý toàn bộ app data với Hive persistence
/// 
/// Features:
/// - Persistent storage với Hive
/// - Singleton pattern: 1 instance duy nhất trong app
/// - CRUD operations cho tất cả models
/// - Support cho guest mode và user authentication
/// - 3 trạng thái: first_launch, guest, logged_in
class DataManager {
  // Singleton instance
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();
  
  // AuthService instance for user state checks
  final AuthService _authService = AuthService();
  
  // EncryptionUtil instance for sensitive data
  final EncryptionUtil _encryption = EncryptionUtil.instance;
  
  // Hive box names
  static const String _userProfileBox = 'userProfileBox';
  static const String _userSettingsBox = 'userSettingsBox';
  static const String _scheduleTasksBox = 'scheduleTasksBox';
  static const String _emotionDiariesBox = 'emotionDiariesBox';
  static const String _gardenProgressBox = 'gardenProgressBox';
  static const String _aquariumProgressBox = 'aquariumProgressBox';
  static const String _paintingProgressBox = 'paintingProgressBox';
  static const String _musicProgressBox = 'musicProgressBox';
  static const String _breathingSessionsBox = 'breathingSessionsBox';
  static const String _sleepSettingsBox = 'sleepSettingsBox';
  static const String _sleepLogsBox = 'sleepLogsBox';
  static const String _achievementProgressBox = 'achievementProgressBox';
  
  // Hive boxes
  late Box<UserProfile> _userProfileHive;
  late Box<UserSettings> _userSettingsHive;
  late Box<ScheduleTask> _scheduleTasksHive;
  late Box<EmotionDiary> _emotionDiariesHive;
  late Box<GardenProgress> _gardenProgressHive;
  late Box<AquariumProgress> _aquariumProgressHive;
  late Box<PaintingProgress> _paintingProgressHive;
  late Box<MusicProgress> _musicProgressHive;
  late Box<BreathingSession> _breathingSessionsHive;
  late Box<SleepSettings> _sleepSettingsHive;
  late Box<SleepLog> _sleepLogsHive;
  late Box<AchievementProgress> _achievementProgressHive;
  
  bool _isInitialized = false;
  
  // ==================== INITIALIZATION ====================
  
  /// Initialize Hive và mở tất cả boxes
  /// Gọi 1 lần khi app khởi động
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Init Hive
    await Hive.initFlutter();
    
    // Register ALL adapters (bao gồm cả nested classes)    
    // Main models (typeId: 0-7)
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(UserSettingsAdapter());
    Hive.registerAdapter(ScheduleTaskAdapter());
    Hive.registerAdapter(EmotionDiaryAdapter());
    Hive.registerAdapter(GardenProgressAdapter());
    Hive.registerAdapter(AquariumProgressAdapter());
    Hive.registerAdapter(PaintingProgressAdapter());
    Hive.registerAdapter(MusicProgressAdapter());
    // Scene models (typeId: 8-11)
    Hive.registerAdapter(SceneSetAdapter());
    Hive.registerAdapter(SceneTypeAdapter());
    Hive.registerAdapter(SceneKeyAdapter());
    Hive.registerAdapter(MascotExpressionAdapter());
    // Nested models (typeId: 12-17)
    Hive.registerAdapter(PlantCellAdapter());
    Hive.registerAdapter(FishAdapter());
    Hive.registerAdapter(PaintingAdapter());
    Hive.registerAdapter(InstrumentAdapter());
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(MusicTrackAdapter());
    // Breathing & Sleep models (typeId: 18-21)
    Hive.registerAdapter(BreathingSessionAdapter());
    Hive.registerAdapter(SleepSettingsAdapter());
    Hive.registerAdapter(SleepLogAdapter());
    // Achievement model (typeId: 22)
    Hive.registerAdapter(AchievementProgressAdapter());
    
    // Initialize encryption with user ID for deterministic keys
    if (!_encryption.isInitialized) {
      final userId = await _authService.userId;
      _encryption.initialize(userId: userId);
    }
    
    // Open boxes
    _userProfileHive = await Hive.openBox<UserProfile>(_userProfileBox);
    _userSettingsHive = await Hive.openBox<UserSettings>(_userSettingsBox);
    _scheduleTasksHive = await Hive.openBox<ScheduleTask>(_scheduleTasksBox);
    _emotionDiariesHive = await Hive.openBox<EmotionDiary>(_emotionDiariesBox);
    _gardenProgressHive = await Hive.openBox<GardenProgress>(_gardenProgressBox);
    _aquariumProgressHive = await Hive.openBox<AquariumProgress>(_aquariumProgressBox);
    _paintingProgressHive = await Hive.openBox<PaintingProgress>(_paintingProgressBox);
    _musicProgressHive = await Hive.openBox<MusicProgress>(_musicProgressBox);
    _breathingSessionsHive = await Hive.openBox<BreathingSession>(_breathingSessionsBox);
    _sleepSettingsHive = await Hive.openBox<SleepSettings>(_sleepSettingsBox);
    _sleepLogsHive = await Hive.openBox<SleepLog>(_sleepLogsBox);
    _achievementProgressHive = await Hive.openBox<AchievementProgress>(_achievementProgressBox);

    // Initialize default sleep settings if empty
    if (_sleepSettingsHive.isEmpty) {
      await _sleepSettingsHive.put('current', SleepSettings.initial());
    }

    // Initialize default achievement progress if empty
    if (_achievementProgressHive.isEmpty) {
      await _achievementProgressHive.put('current', AchievementProgress.initial());
    }

    // Tạo default data theo user mode
    await _initializeUserData();
    
    _isInitialized = true;
  }
  
  /// Generate a unique session ID for web users who are not logged in.
  /// On web, Hive uses IndexedDB which is isolated per browser context
  /// (normal vs incognito), so this ID is stable within a session but
  /// unique across different browser contexts — preventing player ID
  /// collisions in WebRTC multiplayer.
  static String _generateWebUserId() {
    final suffix = Random().nextInt(999999999).toRadixString(36);
    return 'web_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}_$suffix';
  }

  /// Initialize user data based on current mode (first_launch/guest/logged_in)
  Future<void> _initializeUserData() async {
    final userMode = await _authService.userMode;
    final userId = await _authService.userId;

    if (_userProfileHive.isEmpty) {
      UserProfile defaultProfile;

      switch (userMode) {
        case 'first_launch':
          defaultProfile = UserProfile.initial(
            id: kIsWeb ? _generateWebUserId() : 'initial_user',
            username: 'new_user',
            email: 'initial@example.com',
            name: 'Player',
          );
          break;
        case 'guest':
          defaultProfile = UserProfile.initial(
            id: kIsWeb ? _generateWebUserId() : 'guest_user',
            username: 'guest',
            email: 'guest@example.com',
            name: 'Player',
          );
          break;
        case 'debug':
          defaultProfile = UserProfile.initial(
            id: kIsWeb ? _generateWebUserId() : 'debug_user',
            username: 'debug',
            email: 'debug@example.com',
            name: 'Player',
          );
          break;
        case 'logged_in':
          defaultProfile = UserProfile.initial(
            id: userId,
            username: _authService.userEmail?.split('@')[0] ?? 'user',
            email: _authService.userEmail ?? 'user@example.com',
            name: _authService.currentUser?.displayName ?? '',
          );
          break;
        default:
          defaultProfile = UserProfile.initial(
            id: 'initial_user',
            username: 'new_user',
            email: 'initial@example.com',
            name: '',
          );
      }
      
      await _userProfileHive.put('current', defaultProfile);
    }
    
    if (_userSettingsHive.isEmpty) {
      final defaultSettings = UserSettings.initial();
      await _userSettingsHive.put('current', defaultSettings);
    }
  }
  
  /// Switch to guest mode - preserve current data
  Future<void> switchToGuestMode() async {
    final currentProfile = userProfile;
    final guestProfile = currentProfile.copyWith(
      id: 'guest_user',
      username: 'guest',
      email: 'guest@example.com',
      lastUpdatedAt: DateTime.now(),
    );
    await _userProfileHive.put('current', guestProfile);
  }

  /// Switch to debug mode - preserve current data
  Future<void> switchToDebugMode() async {
    final currentProfile = userProfile;
    final debugProfile = currentProfile.copyWith(
      id: 'debug_user',
      username: 'debug',
      email: 'debug@example.com',
      lastUpdatedAt: DateTime.now(),
    );
    await _userProfileHive.put('current', debugProfile);
  }
  
  /// Switch to logged in user - merge or replace data based on cloud data existence
  Future<void> switchToLoggedInUser({
    required String userId,
    required String email,
    String? displayName,
    bool hasCloudData = false,
  }) async {
    UserProfile newProfile;
    
    if (hasCloudData) {
      // Nếu có data trên cloud, sẽ được ghi đè bởi sync service
      // Tạo profile tạm thời với thông tin Firebase
      newProfile = UserProfile.initial(
        id: userId,
        username: email.split('@')[0],
        email: email,
        name: displayName ?? email.split('@')[0],
      );
    } else {
      // Tài khoản mới, giữ nguyên data hiện tại nhưng update user info
      final currentProfile = userProfile;
      newProfile = currentProfile.copyWith(
        id: userId,
        username: email.split('@')[0],
        email: email,
        name: displayName ?? currentProfile.name,
        lastUpdatedAt: DateTime.now(),
      );
    }
    
    await _userProfileHive.put('current', newProfile);
  }
  
  /// Clear all data (reset app)
  Future<void> clearAll() async {
    await _userProfileHive.clear();
    await _userSettingsHive.clear();
    await _scheduleTasksHive.clear();
    await _emotionDiariesHive.clear();
    await _gardenProgressHive.clear();
    await _aquariumProgressHive.clear();
    await _paintingProgressHive.clear();
    await _musicProgressHive.clear();
    
    // Tạo lại default data theo user mode hiện tại
    await _initializeUserData();
  }
  
  /// Check if current user can sync (Firebase authenticated)
  Future<bool> get canSync async {
    final userMode = await _authService.userMode;
    // Debug mode and guest mode cannot sync
    if (userMode == 'debug' || userMode == 'guest') return false;
    // Direct check Firebase auth state for more reliability
    return _authService.isLoggedIn;
  }
  
  // ==================== USER PROFILE ====================
  
  UserProfile get userProfile {
    final profile = _userProfileHive.get('current');
    if (profile == null) {
      throw Exception('DataManager not initialized! Call initialize() first.');
    }
    return profile;
  }
  
  Future<void> saveUserProfile(UserProfile profile) async {
    // Always update lastUpdatedAt when saving profile
    final updatedProfile = profile.copyWith(lastUpdatedAt: DateTime.now());
    await _userProfileHive.put('current', updatedProfile);
  }
  
  // ==================== USER SETTINGS ====================
  
  UserSettings get userSettings {
    final settings = _userSettingsHive.get('current');
    if (settings == null) {
      throw Exception('DataManager not initialized! Call initialize() first.');
    }
    return settings;
  }
  
  Future<void> saveUserSettings(UserSettings settings) async {
    await _userSettingsHive.put('current', settings);
    await _updateLastModifiedTime();
  }
  
  // ==================== SCHEDULE TASKS ====================
  
  List<ScheduleTask> get scheduleTasks {
    return _scheduleTasksHive.values.toList();
  }
  
  Future<void> saveScheduleTasks(List<ScheduleTask> tasks) async {
    await _scheduleTasksHive.clear();
    for (int i = 0; i < tasks.length; i++) {
      await _scheduleTasksHive.put(i, tasks[i]);
    }
    // Update lastUpdatedAt when data changes
    await _updateLastModifiedTime();
  }
  

  
  Future<void> addScheduleTask(ScheduleTask task) async {
    await _scheduleTasksHive.add(task);
    await _updateLastModifiedTime();
  }
  
  Future<void> removeScheduleTask(int index) async {
    await _scheduleTasksHive.deleteAt(index);
    await _updateLastModifiedTime();
  }
  
  Future<void> updateScheduleTask(int index, ScheduleTask task) async {
    await _scheduleTasksHive.putAt(index, task);
    await _updateLastModifiedTime();
  }
  
  // ==================== EMOTION DIARIES ====================
  
  List<EmotionDiary> get emotionDiaries {
    return _emotionDiariesHive.values.toList();
  }
  
  Future<void> saveEmotionDiaries(List<EmotionDiary> diaries) async {
    await _emotionDiariesHive.clear();
    for (int i = 0; i < diaries.length; i++) {
      await _emotionDiariesHive.put(i, diaries[i]);
    }
    await _updateLastModifiedTime();
  }
  
  Future<void> addEmotionDiary(EmotionDiary diary) async {
    await _emotionDiariesHive.add(diary);
    await _updateLastModifiedTime();
  }
  
  // ==================== GARDEN PROGRESS ====================
  
  GardenProgress? get gardenProgress {
    return _gardenProgressHive.get('current');
  }
  
  Future<void> saveGardenProgress(GardenProgress progress) async {
    await _gardenProgressHive.put('current', progress);
    await _updateLastModifiedTime();
  }
  
  // ==================== AQUARIUM PROGRESS ====================
  
  AquariumProgress? get aquariumProgress {
    return _aquariumProgressHive.get('current');
  }
  
  Future<void> saveAquariumProgress(AquariumProgress progress) async {
    await _aquariumProgressHive.put('current', progress);
    await _updateLastModifiedTime();
  }
  
  // ==================== PAINTING PROGRESS ====================
  
  PaintingProgress? get paintingProgress {
    return _paintingProgressHive.get('current');
  }
  
  Future<void> savePaintingProgress(PaintingProgress progress) async {
    await _paintingProgressHive.put('current', progress);
    await _updateLastModifiedTime();
  }
  
  // ==================== MUSIC PROGRESS ====================
  
  MusicProgress? get musicProgress {
    return _musicProgressHive.get('current');
  }
  
  Future<void> saveMusicProgress(MusicProgress progress) async {
    await _musicProgressHive.put('current', progress);
    await _updateLastModifiedTime();
  }

  // ==================== BREATHING SESSIONS ====================

  List<BreathingSession> get breathingSessions {
    return _breathingSessionsHive.values.toList();
  }

  Future<void> addBreathingSession(BreathingSession session) async {
    await _breathingSessionsHive.add(session);
    await _updateLastModifiedTime();
  }

  // ==================== SLEEP SETTINGS ====================

  SleepSettings get sleepSettings {
    return _sleepSettingsHive.get('current') ?? SleepSettings.initial();
  }

  Future<void> saveSleepSettings(SleepSettings settings) async {
    await _sleepSettingsHive.put('current', settings);
    await _updateLastModifiedTime();
  }

  // ==================== SLEEP LOGS ====================

  List<SleepLog> get sleepLogs {
    final logs = _sleepLogsHive.values.toList();
    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs;
  }

  Future<void> saveSleepLogs(List<SleepLog> logs) async {
    await _sleepLogsHive.clear();
    for (final log in logs) {
      await _sleepLogsHive.add(log);
    }
    await _updateLastModifiedTime();
  }

  // ==================== ACHIEVEMENT PROGRESS ====================

  AchievementProgress get achievementProgress {
    return _achievementProgressHive.get('current') ?? AchievementProgress.initial();
  }

  Future<void> saveAchievementProgress(AchievementProgress progress) async {
    await _achievementProgressHive.put('current', progress);
  }

  // Helper method to update lastUpdatedAt timestamp when any data changes
  Future<void> _updateLastModifiedTime() async {
    final currentProfile = userProfile;
    final updatedProfile = currentProfile.copyWith(lastUpdatedAt: DateTime.now());
    // Save without triggering another update (to avoid recursion)
    await _userProfileHive.put('current', updatedProfile);
  }
}