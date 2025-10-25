import 'package:flutter/material.dart';
import '../../models/scene_models.dart';
import '../constants/app_assets.dart';

/// Utility class để load assets một cách type-safe
class AssetLoader {
  
  // ==================== SCENE LOADING ====================
  
  /// Lấy asset path của scene theo bộ cảnh và loại phòng
  /// 
  /// [sceneSet]: Bộ cảnh (default, modern, vintage, ...)
  /// [sceneType]: Loại phòng (living room, garden, ...)
  /// 
  /// Returns: Path của scene asset
  static String getSceneAsset(SceneSet sceneSet, SceneType sceneType) {
    final setScenes = AppAssets.sceneAssets[sceneSet];
    
    if (setScenes == null) {
      throw Exception('Scene set not found: $sceneSet');
    }
    
    final assetPath = setScenes[sceneType];
    
    if (assetPath == null) {
      throw Exception('Scene type not found in set $sceneSet: $sceneType');
    }
    
    return assetPath;
  }
  
  /// Lấy scene từ default set
  static String getDefaultSceneAsset(SceneType sceneType) {
    return getSceneAsset(SceneSet.defaultSet, sceneType);
  }
  
  
  // ==================== MASCOT LOADING ====================
  
  /// Lấy asset path của mascot theo expression
  static String getMascotAsset(MascotExpression expression) {
    final assetPath = AppAssets.mascotAssets[expression];
    
    if (assetPath == null) {
      throw Exception('No asset found for mascot expression: $expression');
    }
    
    return assetPath;
  }
  
  /// Lấy default mascot expression (idle)
  static String getDefaultMascotAsset() {
    return getMascotAsset(MascotExpression.idle);
  }
  
  
  // ==================== PRELOADING (Optional) ====================
  
  /// Preload scenes của một bộ cảnh vào cache
  /// Gọi trong initState để tránh lag khi đổi scene
  static Future<void> preloadSceneSet(BuildContext context, SceneSet sceneSet) async {
    final setScenes = AppAssets.sceneAssets[sceneSet];
    if (setScenes == null) return;
    
    for (final assetPath in setScenes.values) {
      await precacheImage(AssetImage(assetPath), context);
    }
  }
  
  /// Preload default scene set
  static Future<void> preloadDefaultScenes(BuildContext context) async {
    await preloadSceneSet(context, SceneSet.defaultSet);
  }
  
  /// Preload tất cả mascot assets vào cache
  static Future<void> preloadMascots(BuildContext context) async {
    for (final assetPath in AppAssets.mascotAssets.values) {
      await precacheImage(AssetImage(assetPath), context);
    }
  }
  
  /// Preload TẤT CẢ assets
  static Future<void> preloadAll(BuildContext context) async {
    await Future.wait([
      preloadDefaultScenes(context),
      preloadMascots(context),
    ]);
  }
  // ==================== PLANT LOADING ====================

  /// Lấy asset path của cây theo loại và growthStage
  /// 
  /// [plantType]: Tên loại cây (carrot, tomato, corn, ...)
  /// [growthStage]: 0-100, sẽ convert thành 1-4
  /// 
  /// Returns: Path của plant asset
  static String getPlantAsset(String plantType, int growthStage) {
    // Convert 0-100 → 1-4
    int stage;
    if (growthStage < 33) {
      stage = 1;
    } else if (growthStage < 66) {
      stage = 2;
    } else if (growthStage < 100) {
      stage = 3;
    } else {
      stage = 4; // 100 = có thể thu hoạch
    }
    
    return 'assets/images/plants/${plantType.toLowerCase()}_$stage.png';
  }

  // ==================== AQUARIUM LOADING ====================
  static String getTankAsset(SceneSet sceneSet) {
    final assetPath = AppAssets.tankAssets[sceneSet];
    if (assetPath == null) {
      throw Exception('No tank asset found for scene set: $sceneSet');
    }
    return assetPath;
  }

  static String getFishAsset(String fishType) {
    final assetPath = AppAssets.fishAssets[fishType.toLowerCase()];
    if (assetPath == null) {
      throw Exception('No asset found for fish type: $fishType');
    }
    return assetPath;
  }
}