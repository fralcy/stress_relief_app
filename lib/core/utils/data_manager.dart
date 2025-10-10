import '../../models/index.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Singleton để quản lý toàn bộ app data với Hive persistence
/// 
/// Features:
/// - Persistent storage với Hive
/// - Singleton pattern: 1 instance duy nhất trong app
/// - CRUD operations cho tất cả models
class DataManager {
  // Singleton instance
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();
  
  // Hive box names
  static const String _userProfileBox = 'userProfileBox';
  static const String _userSettingsBox = 'userSettingsBox';
  static const String _scheduleTasksBox = 'scheduleTasksBox';
  static const String _emotionDiariesBox = 'emotionDiariesBox';
  static const String _gardenProgressBox = 'gardenProgressBox';
  static const String _aquariumProgressBox = 'aquariumProgressBox';
  static const String _paintingProgressBox = 'paintingProgressBox';
  static const String _musicProgressBox = 'musicProgressBox';
  
  // Hive boxes
  late Box<UserProfile> _userProfileHive;
  late Box<UserSettings> _userSettingsHive;
  late Box<ScheduleTask> _scheduleTasksHive;
  late Box<EmotionDiary> _emotionDiariesHive;
  late Box<GardenProgress> _gardenProgressHive;
  late Box<AquariumProgress> _aquariumProgressHive;
  late Box<PaintingProgress> _paintingProgressHive;
  late Box<MusicProgress> _musicProgressHive;
  
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
    
    // Open boxes
    _userProfileHive = await Hive.openBox<UserProfile>(_userProfileBox);
    _userSettingsHive = await Hive.openBox<UserSettings>(_userSettingsBox);
    _scheduleTasksHive = await Hive.openBox<ScheduleTask>(_scheduleTasksBox);
    _emotionDiariesHive = await Hive.openBox<EmotionDiary>(_emotionDiariesBox);
    _gardenProgressHive = await Hive.openBox<GardenProgress>(_gardenProgressBox);
    _aquariumProgressHive = await Hive.openBox<AquariumProgress>(_aquariumProgressBox);
    _paintingProgressHive = await Hive.openBox<PaintingProgress>(_paintingProgressBox);
    _musicProgressHive = await Hive.openBox<MusicProgress>(_musicProgressBox);
    
    // Tạo default data nếu chưa có
    if (_userProfileHive.isEmpty) {
      final defaultProfile = UserProfile.initial(
        id: 'user_001',
        username: 'guest',
        email: 'guest@example.com',
        name: 'Guest User',
      );
      await _userProfileHive.put('current', defaultProfile);
    }
    
    if (_userSettingsHive.isEmpty) {
      final defaultSettings = UserSettings.initial();
      await _userSettingsHive.put('current', defaultSettings);
    }
    
    _isInitialized = true;
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
    
    // Tạo lại default data
    final defaultProfile = UserProfile.initial(
      id: 'user_001',
      username: 'guest',
      email: 'guest@example.com',
      name: 'Guest User',
    );
    await _userProfileHive.put('current', defaultProfile);
    
    final defaultSettings = UserSettings.initial();
    await _userSettingsHive.put('current', defaultSettings);
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
    await _userProfileHive.put('current', profile);
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
  }
  
  Future<void> addScheduleTask(ScheduleTask task) async {
    await _scheduleTasksHive.add(task);
  }
  
  Future<void> removeScheduleTask(int index) async {
    await _scheduleTasksHive.deleteAt(index);
  }
  
  Future<void> updateScheduleTask(int index, ScheduleTask task) async {
    await _scheduleTasksHive.putAt(index, task);
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
  }
  
  Future<void> addEmotionDiary(EmotionDiary diary) async {
    await _emotionDiariesHive.add(diary);
  }
  
  // ==================== GARDEN PROGRESS ====================
  
  GardenProgress? get gardenProgress {
    return _gardenProgressHive.get('current');
  }
  
  Future<void> saveGardenProgress(GardenProgress progress) async {
    await _gardenProgressHive.put('current', progress);
  }
  
  // ==================== AQUARIUM PROGRESS ====================
  
  AquariumProgress? get aquariumProgress {
    return _aquariumProgressHive.get('current');
  }
  
  Future<void> saveAquariumProgress(AquariumProgress progress) async {
    await _aquariumProgressHive.put('current', progress);
  }
  
  // ==================== PAINTING PROGRESS ====================
  
  PaintingProgress? get paintingProgress {
    return _paintingProgressHive.get('current');
  }
  
  Future<void> savePaintingProgress(PaintingProgress progress) async {
    await _paintingProgressHive.put('current', progress);
  }
  
  // ==================== MUSIC PROGRESS ====================
  
  MusicProgress? get musicProgress {
    return _musicProgressHive.get('current');
  }
  
  Future<void> saveMusicProgress(MusicProgress progress) async {
    await _musicProgressHive.put('current', progress);
  }
}