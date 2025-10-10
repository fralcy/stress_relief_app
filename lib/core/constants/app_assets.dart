import '../../models/scene_models.dart';

/// Quản lý paths của tất cả assets trong app
class AppAssets {
  // ==================== SCENES (5 phòng) ====================
  
  // Scene Set: Default
  static const String defaultLivingRoom = 'assets/images/scenes/default/living_room.png';
  static const String defaultGarden = 'assets/images/scenes/default/garden.png';
  static const String defaultAquarium = 'assets/images/scenes/default/aquarium.png';
  static const String defaultPaintingRoom = 'assets/images/scenes/default/painting_room.png';
  static const String defaultMusicRoom = 'assets/images/scenes/default/music_room.png';
  
  
  // ==================== MASCOT EXPRESSIONS ====================
  
  static const String mascotIdle = 'assets/images/mascot/idle.png';
  static const String mascotHappy = 'assets/images/mascot/happy.png';
  static const String mascotCalm = 'assets/images/mascot/calm.png';
  static const String mascotSad = 'assets/images/mascot/sad.png';
  static const String mascotSleepy = 'assets/images/mascot/sleepy.png';
  static const String mascotSurprised = 'assets/images/mascot/surprised.png';
  
  
  // ==================== HELPER MAPS ====================
  
  /// Map (SceneSet, SceneType) → asset path
  /// Nested map: SceneSet → (SceneType → path)
  static const Map<SceneSet, Map<SceneType, String>> sceneAssets = {
    SceneSet.defaultSet: {
      SceneType.livingRoom: defaultLivingRoom,
      SceneType.garden: defaultGarden,
      SceneType.aquarium: defaultAquarium,
      SceneType.paintingRoom: defaultPaintingRoom,
      SceneType.musicRoom: defaultMusicRoom,
    },
    // Có thể thêm sets khác ở đây sau
  };
  
  /// Map expression → asset path
  static const Map<MascotExpression, String> mascotAssets = {
    MascotExpression.idle: mascotIdle,
    MascotExpression.happy: mascotHappy,
    MascotExpression.calm: mascotCalm,
    MascotExpression.sad: mascotSad,
    MascotExpression.sleepy: mascotSleepy,
    MascotExpression.surprised: mascotSurprised,
  };
}