import '../../models/index.dart';
import '../constants/app_assets.dart';

/// Singleton để quản lý toàn bộ app data trong memory
/// 
/// Features:
/// - Local-only: chỉ lưu trong memory, chưa có persistence
/// - Singleton pattern: 1 instance duy nhất trong app
/// - CRUD operations cho tất cả models
class DataManager {
  // Singleton instance
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();
  
  // In-memory data storage
  UserProfile? _userProfile;
  UserSettings? _userSettings;
  List<ScheduleTask> _scheduleTasks = [];
  List<EmotionDiary> _emotionDiaries = [];
  GardenProgress? _gardenProgress;
  AquariumProgress? _aquariumProgress;
  PaintingProgress? _paintingProgress;
  MusicProgress? _musicProgress;
  
  // ==================== INITIALIZATION ====================
  
  /// Initialize với default data
  /// Gọi 1 lần khi app khởi động
  void initialize() {
    // Tạo profile mặc định
    _userProfile = UserProfile.initial(
      id: 'user_001',
      username: 'guest',
      email: 'guest@example.com',
      name: 'Guest User',
    );
    
    // Tạo settings mặc định
    _userSettings = UserSettings.initial();
    
    // Các data khác bắt đầu empty
    _scheduleTasks = [];
    _emotionDiaries = [];
    _gardenProgress = null;
    _aquariumProgress = null;
    _paintingProgress = null;
    _musicProgress = null;
  }
  
  /// Clear all data (reset app)
  void clearAll() {
    _userProfile = null;
    _userSettings = null;
    _scheduleTasks = [];
    _emotionDiaries = [];
    _gardenProgress = null;
    _aquariumProgress = null;
    _paintingProgress = null;
    _musicProgress = null;
  }
  
  // ==================== USER PROFILE ====================
  
  UserProfile get userProfile {
    if (_userProfile == null) {
      throw Exception('DataManager not initialized! Call initialize() first.');
    }
    return _userProfile!;
  }
  
  void saveUserProfile(UserProfile profile) {
    _userProfile = profile;
  }
  
  // ==================== USER SETTINGS ====================
  
  UserSettings get userSettings {
    if (_userSettings == null) {
      throw Exception('DataManager not initialized! Call initialize() first.');
    }
    return _userSettings!;
  }
  
  void saveUserSettings(UserSettings settings) {
    _userSettings = settings;
  }
  
  // ==================== SCHEDULE TASKS ====================
  
  List<ScheduleTask> get scheduleTasks => _scheduleTasks;
  
  void saveScheduleTasks(List<ScheduleTask> tasks) {
    _scheduleTasks = tasks;
  }
  
  void addScheduleTask(ScheduleTask task) {
    _scheduleTasks = [..._scheduleTasks, task];
  }
  
  void removeScheduleTask(int index) {
    final tasks = [..._scheduleTasks];
    tasks.removeAt(index);
    _scheduleTasks = tasks;
  }
  
  void updateScheduleTask(int index, ScheduleTask task) {
    final tasks = [..._scheduleTasks];
    tasks[index] = task;
    _scheduleTasks = tasks;
  }
  
  // ==================== EMOTION DIARIES ====================
  
  List<EmotionDiary> get emotionDiaries => _emotionDiaries;
  
  void saveEmotionDiaries(List<EmotionDiary> diaries) {
    _emotionDiaries = diaries;
  }
  
  void addEmotionDiary(EmotionDiary diary) {
    _emotionDiaries = [..._emotionDiaries, diary];
  }
  
  // ==================== GARDEN PROGRESS ====================
  
  GardenProgress? get gardenProgress => _gardenProgress;
  
  void saveGardenProgress(GardenProgress progress) {
    _gardenProgress = progress;
  }
  
  // ==================== AQUARIUM PROGRESS ====================
  
  AquariumProgress? get aquariumProgress => _aquariumProgress;
  
  void saveAquariumProgress(AquariumProgress progress) {
    _aquariumProgress = progress;
  }
  
  // ==================== PAINTING PROGRESS ====================
  
  PaintingProgress? get paintingProgress => _paintingProgress;
  
  void savePaintingProgress(PaintingProgress progress) {
    _paintingProgress = progress;
  }
  
  // ==================== MUSIC PROGRESS ====================
  
  MusicProgress? get musicProgress => _musicProgress;
  
  void saveMusicProgress(MusicProgress progress) {
    _musicProgress = progress;
  }
}