import '../../models/index.dart';
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
  static const String _sleepSessionsBox = 'sleepSessionsBox';
  static const String _sleepSettingsBox = 'sleepSettingsBox';
  
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
  late Box<SleepSession> _sleepSessionsHive;
  late Box<SleepSettings> _sleepSettingsHive;
  
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
    // Breathing & Sleep models (typeId: 18-20)
    Hive.registerAdapter(BreathingSessionAdapter());
    Hive.registerAdapter(SleepSessionAdapter());
    Hive.registerAdapter(SleepSettingsAdapter());
    
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
    _sleepSessionsHive = await Hive.openBox<SleepSession>(_sleepSessionsBox);
    _sleepSettingsHive = await Hive.openBox<SleepSettings>(_sleepSettingsBox);

    // Initialize default sleep settings if empty
    if (_sleepSettingsHive.isEmpty) {
      await _sleepSettingsHive.put('current', SleepSettings.initial());
    }

    // Tạo default data theo user mode
    await _initializeUserData();
    
    _isInitialized = true;
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
            id: 'initial_user',
            username: 'new_user',
            email: 'initial@example.com',
            name: 'New User',
          );
          break;
        case 'guest':
          defaultProfile = UserProfile.initial(
            id: 'guest_user',
            username: 'guest',
            email: 'guest@example.com',
            name: 'Guest User',
          );
          break;
        case 'debug':
          defaultProfile = UserProfile.initial(
            id: 'debug_user',
            username: 'debug',
            email: 'debug@example.com',
            name: 'Debug User',
          );
          break;
        case 'logged_in':
          defaultProfile = UserProfile.initial(
            id: userId,
            username: _authService.userEmail?.split('@')[0] ?? 'user',
            email: _authService.userEmail ?? 'user@example.com',
            name: _authService.currentUser?.displayName ?? 'User',
          );
          break;
        default:
          defaultProfile = UserProfile.initial(
            id: 'initial_user',
            username: 'new_user',
            email: 'initial@example.com',
            name: 'New User',
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
      name: 'Guest User',
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
      name: 'Debug User',
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

  // ==================== SLEEP SESSIONS ====================

  List<SleepSession> get sleepSessions {
    return _sleepSessionsHive.values.toList();
  }

  Future<void> addSleepSession(SleepSession session) async {
    await _sleepSessionsHive.add(session);
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

  // Helper method to update lastUpdatedAt timestamp when any data changes
  Future<void> _updateLastModifiedTime() async {
    final currentProfile = userProfile;
    final updatedProfile = currentProfile.copyWith(lastUpdatedAt: DateTime.now());
    // Save without triggering another update (to avoid recursion)
    await _userProfileHive.put('current', updatedProfile);
  }
}