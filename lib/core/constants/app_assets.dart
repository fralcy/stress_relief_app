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
  
  // Scene Set: Forest
  static const String forestLivingRoom = 'assets/images/scenes/forest/living_room.png';
  static const String forestGarden = 'assets/images/scenes/forest/garden.png';
  static const String forestAquarium = 'assets/images/scenes/forest/aquarium.png';
  static const String forestPaintingRoom = 'assets/images/scenes/forest/painting_room.png';
  static const String forestMusicRoom = 'assets/images/scenes/forest/music_room.png';
  
  // Scene Set: Beach
  static const String beachLivingRoom = 'assets/images/scenes/beach/living_room.png';
  static const String beachGarden = 'assets/images/scenes/beach/garden.png';
  static const String beachAquarium = 'assets/images/scenes/beach/aquarium.png';
  static const String beachPaintingRoom = 'assets/images/scenes/beach/painting_room.png';
  static const String beachMusicRoom = 'assets/images/scenes/beach/music_room.png';
  
  // Scene Set: Japanese
  static const String japaneseLivingRoom = 'assets/images/scenes/japanese/living_room.png';
  static const String japaneseGarden = 'assets/images/scenes/japanese/garden.png';
  static const String japaneseAquarium = 'assets/images/scenes/japanese/aquarium.png';
  static const String japanesePaintingRoom = 'assets/images/scenes/japanese/painting_room.png';
  static const String japaneseMusicRoom = 'assets/images/scenes/japanese/music_room.png';
  
  // Scene Set: Winter
  static const String winterLivingRoom = 'assets/images/scenes/winter/living_room.png';
  static const String winterGarden = 'assets/images/scenes/winter/garden.png';
  static const String winterAquarium = 'assets/images/scenes/winter/aquarium.png';
  static const String winterPaintingRoom = 'assets/images/scenes/winter/painting_room.png';
  static const String winterMusicRoom = 'assets/images/scenes/winter/music_room.png';
  
  
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
  static const String bgmFolkSong = 'assets/audio/bgm/folk_song.mp3';
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
    SceneSet.forest: {
      SceneType.livingRoom: forestLivingRoom,
      SceneType.garden: forestGarden,
      SceneType.aquarium: forestAquarium,
      SceneType.paintingRoom: forestPaintingRoom,
      SceneType.musicRoom: forestMusicRoom,
    },
    SceneSet.beach: {
      SceneType.livingRoom: beachLivingRoom,
      SceneType.garden: beachGarden,
      SceneType.aquarium: beachAquarium,
      SceneType.paintingRoom: beachPaintingRoom,
      SceneType.musicRoom: beachMusicRoom,
    },
    SceneSet.japanese: {
      SceneType.livingRoom: japaneseLivingRoom,
      SceneType.garden: japaneseGarden,
      SceneType.aquarium: japaneseAquarium,
      SceneType.paintingRoom: japanesePaintingRoom,
      SceneType.musicRoom: japaneseMusicRoom,
    },
    SceneSet.winter: {
      SceneType.livingRoom: winterLivingRoom,
      SceneType.garden: winterGarden,
      SceneType.aquarium: winterAquarium,
      SceneType.paintingRoom: winterPaintingRoom,
      SceneType.musicRoom: winterMusicRoom,
    },
  };
  
  /// Scene collection info for shop
  static const Map<SceneSet, Map<String, dynamic>> sceneCollections = {
    SceneSet.defaultSet: {
      'name': 'Cozy Home Collection',
      'price': 0, // Free default set
      'icon': '🏠',
      'description': 'Classic home comfort scenes',
    },
    SceneSet.forest: {
      'name': 'Forest Collection',
      'price': 1000,
      'icon': '🌲',
      'description': 'Peaceful woodland scenes',
    },
    SceneSet.beach: {
      'name': 'Beach Collection', 
      'price': 1000,
      'icon': '🏖️',
      'description': 'Relaxing coastal scenes',
    },
    SceneSet.japanese: {
      'name': 'Japanese Collection',
      'price': 1000,
      'icon': '🎋',
      'description': 'Traditional zen scenes',
    },
    SceneSet.winter: {
      'name': 'Winter Collection',
      'price': 1000,
      'icon': '❄️',
      'description': 'Cozy winter wonderland',
    },
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
    'Folk Song': bgmFolkSong,
    'Indie Vibes': bgmIndieVibes,
    'Soft Pop': bgmSoftPop,
    'Chill Acoustic': bgmChillAcoustic,
  };

  // ==================== AQUARIUM ====================
  // Tank backgrounds
  static const String tankDefault = 'assets/images/aquarium/tank_default.png';

  // Fish types
  static const String fishBetta = 'assets/images/aquarium/fish_betta.png';
  static const String fishGuppy = 'assets/images/aquarium/fish_guppy.png';
  static const String fishNeon = 'assets/images/aquarium/fish_neon.png';
  static const String fishMolly = 'assets/images/aquarium/fish_molly.png';
  static const String fishCory = 'assets/images/aquarium/fish_cory.png';
  static const String fishPlaty = 'assets/images/aquarium/fish_platy.png';

  // Maps
  static const Map<SceneSet, String> tankAssets = {
    SceneSet.defaultSet: tankDefault,
  };

  static const Map<String, String> fishAssets = {
    'betta': fishBetta,
    'guppy': fishGuppy,
    'neon': fishNeon,
    'molly': fishMolly,
    'cory': fishCory,
    'platy': fishPlaty,
  };
}