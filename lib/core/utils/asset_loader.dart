import 'package:flutter/material.dart';
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
}