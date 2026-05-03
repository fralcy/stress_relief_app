import '../../models/scene_models.dart';

/// Quản lý paths của tất cả assets trong app
class AppAssets {
  // ==================== SCENES (5 phòng) ====================
  
  // Scene Set: Default
  static const String defaultLivingRoom = 'assets/images/scenes/default/living_room.webp';
  static const String defaultGarden = 'assets/images/scenes/default/garden.webp';
  static const String defaultAquarium = 'assets/images/scenes/default/aquarium.webp';
  static const String defaultPaintingRoom = 'assets/images/scenes/default/painting_room.webp';
  static const String defaultMusicRoom = 'assets/images/scenes/default/music_room.webp';
  
  // Scene Set: Forest
  static const String forestLivingRoom = 'assets/images/scenes/forest/living_room.webp';
  static const String forestGarden = 'assets/images/scenes/forest/garden.webp';
  static const String forestAquarium = 'assets/images/scenes/forest/aquarium.webp';
  static const String forestPaintingRoom = 'assets/images/scenes/forest/painting_room.webp';
  static const String forestMusicRoom = 'assets/images/scenes/forest/music_room.webp';
  
  // Scene Set: Beach
  static const String beachLivingRoom = 'assets/images/scenes/beach/living_room.webp';
  static const String beachGarden = 'assets/images/scenes/beach/garden.webp';
  static const String beachAquarium = 'assets/images/scenes/beach/aquarium.webp';
  static const String beachPaintingRoom = 'assets/images/scenes/beach/painting_room.webp';
  static const String beachMusicRoom = 'assets/images/scenes/beach/music_room.webp';
  
  // Scene Set: Peach Blossom
  static const String peachBlossomLivingRoom = 'assets/images/scenes/peach_blossom/living_room.webp';
  static const String peachBlossomGarden = 'assets/images/scenes/peach_blossom/garden.webp';
  static const String peachBlossomAquarium = 'assets/images/scenes/peach_blossom/aquarium.webp';
  static const String peachBlossomPaintingRoom = 'assets/images/scenes/peach_blossom/painting_room.webp';
  static const String peachBlossomMusicRoom = 'assets/images/scenes/peach_blossom/music_room.webp';

  // Scene Set: Desert
  static const String desertLivingRoom = 'assets/images/scenes/desert/living_room.webp';
  static const String desertGarden = 'assets/images/scenes/desert/garden.webp';
  static const String desertAquarium = 'assets/images/scenes/desert/aquarium.webp';
  static const String desertPaintingRoom = 'assets/images/scenes/desert/painting_room.webp';
  static const String desertMusicRoom = 'assets/images/scenes/desert/music_room.webp';

  // Scene Set: Cosmic
  static const String cosmicLivingRoom = 'assets/images/scenes/cosmic/living_room.webp';
  static const String cosmicGarden = 'assets/images/scenes/cosmic/garden.webp';
  static const String cosmicAquarium = 'assets/images/scenes/cosmic/aquarium.webp';
  static const String cosmicPaintingRoom = 'assets/images/scenes/cosmic/painting_room.webp';
  static const String cosmicMusicRoom = 'assets/images/scenes/cosmic/music_room.webp';

  // Scene Set: Castle
  static const String castleLivingRoom = 'assets/images/scenes/castle/living_room.webp';
  static const String castleGarden = 'assets/images/scenes/castle/garden.webp';
  static const String castleAquarium = 'assets/images/scenes/castle/aquarium.webp';
  static const String castlePaintingRoom = 'assets/images/scenes/castle/painting_room.webp';
  static const String castleMusicRoom = 'assets/images/scenes/castle/music_room.webp';
  
  // Scene Set: Winter
  static const String winterLivingRoom = 'assets/images/scenes/winter/living_room.webp';
  static const String winterGarden = 'assets/images/scenes/winter/garden.webp';
  static const String winterAquarium = 'assets/images/scenes/winter/aquarium.webp';
  static const String winterPaintingRoom = 'assets/images/scenes/winter/painting_room.webp';
  static const String winterMusicRoom = 'assets/images/scenes/winter/music_room.webp';
  
  
  // ==================== MASCOT EXPRESSIONS ====================
  
  static const String mascotIdle = 'assets/images/mascot/idle.webp';
  static const String mascotHappy = 'assets/images/mascot/happy.webp';
  static const String mascotCalm = 'assets/images/mascot/calm.webp';
  static const String mascotSad = 'assets/images/mascot/sad.webp';
  static const String mascotSleepy = 'assets/images/mascot/sleepy.webp';
  static const String mascotSurprised = 'assets/images/mascot/surprised.webp';
  
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
    SceneSet.peachBlossom: {
      SceneType.livingRoom: peachBlossomLivingRoom,
      SceneType.garden: peachBlossomGarden,
      SceneType.aquarium: peachBlossomAquarium,
      SceneType.paintingRoom: peachBlossomPaintingRoom,
      SceneType.musicRoom: peachBlossomMusicRoom,
    },
    SceneSet.winter: {
      SceneType.livingRoom: winterLivingRoom,
      SceneType.garden: winterGarden,
      SceneType.aquarium: winterAquarium,
      SceneType.paintingRoom: winterPaintingRoom,
      SceneType.musicRoom: winterMusicRoom,
    },
    SceneSet.desert: {
      SceneType.livingRoom: desertLivingRoom,
      SceneType.garden: desertGarden,
      SceneType.aquarium: desertAquarium,
      SceneType.paintingRoom: desertPaintingRoom,
      SceneType.musicRoom: desertMusicRoom,
    },
    SceneSet.cosmic: {
      SceneType.livingRoom: cosmicLivingRoom,
      SceneType.garden: cosmicGarden,
      SceneType.aquarium: cosmicAquarium,
      SceneType.paintingRoom: cosmicPaintingRoom,
      SceneType.musicRoom: cosmicMusicRoom,
    },
    SceneSet.castle: {
      SceneType.livingRoom: castleLivingRoom,
      SceneType.garden: castleGarden,
      SceneType.aquarium: castleAquarium,
      SceneType.paintingRoom: castlePaintingRoom,
      SceneType.musicRoom: castleMusicRoom,
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
    SceneSet.peachBlossom: {
      'name': 'Peach Blossom',
      'price': 1000,
      'icon': '🌸',
      'description': 'Cherry blossoms, koi ponds, and low wooden tables',
    },
    SceneSet.winter: {
      'name': 'Winter Collection',
      'price': 1000,
      'icon': '❄️',
      'description': 'Cozy winter wonderland',
    },
    SceneSet.desert: {
      'name': 'Desert Oasis',
      'price': 1000,
      'icon': '🌵',
      'description': 'Sandy dunes, warm amber light, and terracotta accents',
    },
    SceneSet.cosmic: {
      'name': 'Cosmic Night',
      'price': 1000,
      'icon': '🌌',
      'description': 'Starry skies, deep indigo, and glowing nebula hues',
    },
    SceneSet.castle: {
      'name': 'Stone Castle',
      'price': 1000,
      'icon': '🏰',
      'description': 'Cobblestone halls, cool gray stone, and medieval warmth',
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

  /// Frame lists cho sprite animation.
  static const Map<MascotExpression, List<String>> mascotFrames = {
    MascotExpression.idle: [
      mascotIdle,
      'assets/images/mascot/idle_2.webp',
      'assets/images/mascot/idle_3.webp',
      'assets/images/mascot/idle_4.webp',
    ],
    MascotExpression.happy: [
      mascotHappy,
      'assets/images/mascot/happy_2.webp',
      'assets/images/mascot/happy_3.webp',
      'assets/images/mascot/happy_4.webp',
    ],
    MascotExpression.calm: [
      mascotCalm,
      'assets/images/mascot/calm_2.webp',
      'assets/images/mascot/calm_3.webp',
      'assets/images/mascot/calm_4.webp',
    ],
    MascotExpression.sleepy: [
      mascotSleepy,
      'assets/images/mascot/sleepy_2.webp',
      'assets/images/mascot/sleepy_3.webp',
      'assets/images/mascot/sleepy_4.webp',
    ],
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
  static const String tankDefault = 'assets/images/aquarium/tank_default.webp';
  static const String tankForest = 'assets/images/aquarium/tank_forest.webp';
  static const String tankBeach = 'assets/images/aquarium/tank_beach.webp';
  static const String tankPeachBlossom = 'assets/images/aquarium/tank_peach_blossom.webp';
  static const String tankWinter = 'assets/images/aquarium/tank_winter.webp';
  static const String tankDesert = 'assets/images/aquarium/tank_desert.webp';
  static const String tankCosmic = 'assets/images/aquarium/tank_cosmic.webp';
  static const String tankCastle = 'assets/images/aquarium/tank_castle.webp';

  // Fish types
  static const String fishBetta = 'assets/images/aquarium/fish_betta.webp';
  static const String fishGuppy = 'assets/images/aquarium/fish_guppy.webp';
  static const String fishNeon = 'assets/images/aquarium/fish_neon.webp';
  static const String fishMolly = 'assets/images/aquarium/fish_molly.webp';
  static const String fishCory = 'assets/images/aquarium/fish_cory.webp';
  static const String fishPlaty = 'assets/images/aquarium/fish_platy.webp';

  // Maps
  static const Map<SceneSet, String> tankAssets = {
    SceneSet.defaultSet:   tankDefault,
    SceneSet.forest:       tankForest,
    SceneSet.beach:        tankBeach,
    SceneSet.peachBlossom: tankPeachBlossom,
    SceneSet.winter:       tankWinter,
    SceneSet.desert:       tankDesert,
    SceneSet.cosmic:       tankCosmic,
    SceneSet.castle:       tankCastle,
  };

  static const Map<String, String> fishAssets = {
    'betta': fishBetta,
    'guppy': fishGuppy,
    'neon': fishNeon,
    'molly': fishMolly,
    'cory': fishCory,
    'platy': fishPlaty,
  };

  // ==================== ROCK BALANCING ====================
  static const String rockBgDefault  = 'assets/images/rock_balancing/bg_default.webp';
  static const String rockBgForest   = 'assets/images/rock_balancing/bg_forest.webp';
  static const String rockBgBeach    = 'assets/images/rock_balancing/bg_beach.webp';
  static const String rockBgPeachBlossom = 'assets/images/rock_balancing/bg_peach_blossom.webp';
  static const String rockBgWinter       = 'assets/images/rock_balancing/bg_winter.webp';
  static const String rockBgDesert       = 'assets/images/rock_balancing/bg_desert.webp';
  static const String rockBgCosmic       = 'assets/images/rock_balancing/bg_cosmic.webp';
  static const String rockBgCastle       = 'assets/images/rock_balancing/bg_castle.webp';

  static const Map<SceneSet, String> rockBgAssets = {
    SceneSet.defaultSet:   rockBgDefault,
    SceneSet.forest:       rockBgForest,
    SceneSet.beach:        rockBgBeach,
    SceneSet.peachBlossom: rockBgPeachBlossom,
    SceneSet.winter:       rockBgWinter,
    SceneSet.desert:       rockBgDesert,
    SceneSet.cosmic:       rockBgCosmic,
    SceneSet.castle:       rockBgCastle,
  };

  // ==================== FIREFLY ====================
  static const String fireflyBgDefault  = 'assets/images/firefly/bg_default.webp';
  static const String fireflyBgForest   = 'assets/images/firefly/bg_forest.webp';
  static const String fireflyBgBeach    = 'assets/images/firefly/bg_beach.webp';
  static const String fireflyBgPeachBlossom = 'assets/images/firefly/bg_peach_blossom.webp';
  static const String fireflyBgWinter       = 'assets/images/firefly/bg_winter.webp';
  static const String fireflyBgDesert       = 'assets/images/firefly/bg_desert.webp';
  static const String fireflyBgCosmic       = 'assets/images/firefly/bg_cosmic.webp';
  static const String fireflyBgCastle       = 'assets/images/firefly/bg_castle.webp';

  static const Map<SceneSet, String> fireflyBgAssets = {
    SceneSet.defaultSet:   fireflyBgDefault,
    SceneSet.forest:       fireflyBgForest,
    SceneSet.beach:        fireflyBgBeach,
    SceneSet.peachBlossom: fireflyBgPeachBlossom,
    SceneSet.winter:       fireflyBgWinter,
    SceneSet.desert:       fireflyBgDesert,
    SceneSet.cosmic:       fireflyBgCosmic,
    SceneSet.castle:       fireflyBgCastle,
  };
}