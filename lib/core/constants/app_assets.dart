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
  
  // ==================== BGM (BACKGROUND MUSIC) ====================
  static const String bgmLofiBeats = 'assets/audio/bgm/lofi_beats.mp3';
  static const String bgmRainSounds = 'assets/audio/bgm/rain_sounds.mp3';
  static const String bgmPianoMusic = 'assets/audio/bgm/piano_music.mp3';
  static const String bgmAcousticBallad = 'assets/audio/bgm/acoustic_ballad.mp3';
  static const String bgmTraditionalMelodies = 'assets/audio/bgm/traditional_melodies.mp3';
  static const String bgmIndieVibes = 'assets/audio/bgm/indie_vibes.mp3';
  static const String bgmSoftPop = 'assets/audio/bgm/soft_pop.mp3';
  static const String bgmChillAcoustic = 'assets/audio/bgm/chill_acoustic.mp3';

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

  /// Map BGM name → asset path
  static const Map<String, String> bgmAssets = {
    'Lofi Beats': bgmLofiBeats,
    'Rain Sounds': bgmRainSounds,
    'Piano Music': bgmPianoMusic,
    'Acoustic Ballad': bgmAcousticBallad,
    'Traditional Melodies': bgmTraditionalMelodies,
    'Indie Vibes': bgmIndieVibes,
    'Soft Pop': bgmSoftPop,
    'Chill Acoustic': bgmChillAcoustic,
  };
}