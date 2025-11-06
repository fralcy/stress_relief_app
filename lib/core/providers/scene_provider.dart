import 'package:flutter/material.dart';
import '../utils/data_manager.dart';
import '../../models/user_profile.dart';
import '../../models/user_settings.dart';
import '../../models/scene_models.dart';
import '../constants/app_assets.dart';

/// Provider để quản lý scenes: unlock status, current scenes, và asset loading
class SceneProvider extends ChangeNotifier {
  UserProfile _profile;
  UserSettings _settings;

  SceneProvider() 
    : _profile = DataManager().userProfile,
      _settings = DataManager().userSettings;

  // Getters
  UserProfile get profile => _profile;
  UserSettings get settings => _settings;
  Map<SceneKey, bool> get unlockedScenes => _profile.unlockedScenes;
  List<SceneKey> get currentScenes => _settings.currentScenes;

  /// Load data từ DataManager
  void loadData() {
    _profile = DataManager().userProfile;
    _settings = DataManager().userSettings;
    notifyListeners();
  }

  /// Refresh data từ DataManager (khi cần sync)
  void refresh() {
    _profile = DataManager().userProfile;
    _settings = DataManager().userSettings;
    notifyListeners();
  }

  /// Kiểm tra xem một scene có được unlock không
  bool isSceneUnlocked(SceneKey sceneKey) {
    return _profile.unlockedScenes[sceneKey] ?? false;
  }

  /// Kiểm tra xem toàn bộ scene set có được unlock không
  bool isSceneSetUnlocked(SceneSet sceneSet) {
    // Check all 5 scene types in the set
    for (SceneType sceneType in SceneType.values) {
      SceneKey key = SceneKey(sceneSet, sceneType);
      if (!isSceneUnlocked(key)) {
        return false;
      }
    }
    return true;
  }

  /// Kiểm tra xem scene set có được unlock một phần không
  bool isSceneSetPartiallyUnlocked(SceneSet sceneSet) {
    for (SceneType sceneType in SceneType.values) {
      SceneKey key = SceneKey(sceneSet, sceneType);
      if (isSceneUnlocked(key)) {
        return true;
      }
    }
    return false;
  }

  /// Đếm số scenes đã unlock trong một set
  int getUnlockedScenesCount(SceneSet sceneSet) {
    int count = 0;
    for (SceneType sceneType in SceneType.values) {
      SceneKey key = SceneKey(sceneSet, sceneType);
      if (isSceneUnlocked(key)) count++;
    }
    return count;
  }

  /// Mở khóa một scene cụ thể
  Future<void> unlockScene(SceneKey sceneKey) async {
    Map<SceneKey, bool> updatedUnlocked = Map.from(_profile.unlockedScenes);
    updatedUnlocked[sceneKey] = true;

    _profile = _profile.copyWith(unlockedScenes: updatedUnlocked);
    await DataManager().saveUserProfile(_profile);
    notifyListeners();
  }

  /// Mở khóa toàn bộ scene set (5 scenes)
  Future<void> unlockSceneSet(SceneSet sceneSet) async {
    Map<SceneKey, bool> updatedUnlocked = Map.from(_profile.unlockedScenes);
    
    for (SceneType sceneType in SceneType.values) {
      SceneKey key = SceneKey(sceneSet, sceneType);
      updatedUnlocked[key] = true;
    }

    _profile = _profile.copyWith(unlockedScenes: updatedUnlocked);
    await DataManager().saveUserProfile(_profile);
    notifyListeners();
  }

  /// Thay đổi scene hiện tại cho một loại phòng cụ thể
  Future<void> changeCurrentScene(SceneType sceneType, SceneSet sceneSet) async {
    SceneKey newSceneKey = SceneKey(sceneSet, sceneType);
    
    // Kiểm tra xem scene có được unlock không
    if (!isSceneUnlocked(newSceneKey)) {
      throw Exception('Scene chưa được mở khóa');
    }

    // Tạo mảng scenes mới
    List<SceneKey> newScenes = List.from(_settings.currentScenes);
    int index = sceneType.index; // SceneType enum index tương ứng với vị trí trong mảng
    newScenes[index] = newSceneKey;

    _settings = _settings.copyWith(currentScenes: newScenes);
    await DataManager().saveUserSettings(_settings);
    notifyListeners();
  }

  /// Thay đổi toàn bộ scene set hiện tại (tất cả 5 phòng)
  Future<void> changeCurrentSceneSet(SceneSet sceneSet) async {
    // Kiểm tra xem toàn bộ set có được unlock không
    if (!isSceneSetUnlocked(sceneSet)) {
      throw Exception('Scene set chưa được mở khóa hoàn toàn');
    }

    // Tạo danh sách scenes mới cho tất cả phòng
    List<SceneKey> newScenes = SceneType.values
        .map((sceneType) => SceneKey(sceneSet, sceneType))
        .toList();

    _settings = _settings.copyWith(currentScenes: newScenes);
    await DataManager().saveUserSettings(_settings);
    notifyListeners();
  }

  /// Lấy asset path cho scene hiện tại của một loại phòng
  String getCurrentSceneAsset(SceneType sceneType) {
    int index = sceneType.index;
    if (index < 0 || index >= _settings.currentScenes.length) {
      // Fallback to default
      return AppAssets.sceneAssets[SceneSet.defaultSet]?[sceneType] ?? '';
    }

    SceneKey currentKey = _settings.currentScenes[index];
    return AppAssets.sceneAssets[currentKey.sceneSet]?[currentKey.sceneType] ?? '';
  }

  /// Lấy tất cả assets cho scenes hiện tại
  Map<SceneType, String> getCurrentSceneAssets() {
    Map<SceneType, String> assets = {};
    for (SceneType sceneType in SceneType.values) {
      assets[sceneType] = getCurrentSceneAsset(sceneType);
    }
    return assets;
  }

  /// Lấy SceneSet hiện tại đang sử dụng (dựa trên living room)
  SceneSet getCurrentSceneSet() {
    if (_settings.currentScenes.isNotEmpty) {
      return _settings.currentScenes[0].sceneSet; // Dựa trên living room
    }
    return SceneSet.defaultSet;
  }

  /// Kiểm tra xem có đủ điểm để mua scene set không
  bool canAffordSceneSet(SceneSet sceneSet) {
    int price = AppAssets.sceneCollections[sceneSet]?['price'] ?? 0;
    return _profile.currentPoints >= price;
  }

  /// Mua scene set bằng điểm
  Future<bool> purchaseSceneSet(SceneSet sceneSet) async {
    int price = AppAssets.sceneCollections[sceneSet]?['price'] ?? 0;
    
    // Kiểm tra điểm
    if (_profile.currentPoints < price) {
      return false;
    }

    // Kiểm tra đã unlock chưa
    if (isSceneSetUnlocked(sceneSet)) {
      return false; // Đã mua rồi
    }

    // Trừ điểm
    _profile = _profile.copyWith(
      currentPoints: _profile.currentPoints - price,
    );

    // Mở khóa tất cả scenes trong set
    Map<SceneKey, bool> updatedUnlocked = Map.from(_profile.unlockedScenes);
    for (SceneType sceneType in SceneType.values) {
      SceneKey key = SceneKey(sceneSet, sceneType);
      updatedUnlocked[key] = true;
    }
    
    _profile = _profile.copyWith(unlockedScenes: updatedUnlocked);
    await DataManager().saveUserProfile(_profile);
    notifyListeners();
    
    return true;
  }
}