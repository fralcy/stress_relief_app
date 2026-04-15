import 'package:flutter/material.dart';
import '../../models/scene_models.dart';

/// Base class cho localization
/// Mỗi ngôn ngữ sẽ implement class này
abstract class AppLocalizations {
  // Common words
  String get ok;
  String get cancel;
  String get save;
  String get open;
  String get reset;
  String get edit;
  String get load;
  
  // Navigation - 5 phòng
  String get livingRoom;
  String get garden;
  String get aquarium;
  String get paintingRoom;
  String get musicRoom;

  // Feature buttons
  String get tasks;
  String get mood;
  String get draw;
  String get compose;
  String get library;
  String get templates;
  String get samples;
  
  // Template/Sample selection
  String get useTemplate;
  String get useSample;
  String get selectTemplate;
  String get selectSample;
  String currentWillBeReplaced(String type);
  
  // Template names (localized)
  String get templateHeart;
  String get templateStar;
  String get templateFlower;
  String get templateApple;
  String get templateTree;
  String get templateCat;
  
  // Settings
  String get settings;
  String get theme;
  String get language;
  
  // Settings Modal - Audio
  String get audio;
  String get bgm;
  String get volume;
  String get sfx;
  String get enabled;
  
  // Settings Modal - Display
  String get display;
  String get preview;
  
  // Settings Modal - Mascot
  String get mascot;
  String get name;
  String get mascotName;
  
  // Settings Modal - Notification
  String get notification;
  String get sleepReminder;
  String get taskReminder;
  String get time;
  String get before;
  String get remindBeforeMinutes;
  String get minutes;
  
  // Settings Modal - Cloud Sync
  String get cloudSync;
  String get sync;
  String get resetToDefault;
  String get resetConfirmation;

  // Schedule Task
  String get scheduleTask;
  String get taskName;
  String get addTask;
  String get noTasksYet;
  String get expectedPoints;
  String get endDayAndClaimPoints;
  String get completedTasks;
  String get alreadyClaimedToday;
  String get noCompletedTasks;
  String get sceneShop;
  String get scenePreviewExpand;
  String get scenePreviewCollapse;
  String get progress;
  
  // Emotion Diary
  String get emotionDiary;
  String get historyLast2Weeks;
  String get tapDayToViewDetails;
  String get noDiaryData;
  String get todaysJournal;
  String get dailyJournal;
  String get howDoYouFeelOverall;
  String get howWasYourStressLevel;
  String get howProductiveWereYou;
  String get veryBad;
  String get bad;
  String get neutral;
  String get good;
  String get great;
  String get veryHigh;
  String get high;
  String get moderate;
  String get low;
  String get relaxed;
  String get none;
  String get little;
  String get average;
  String get very;
  String get writeYourThoughts;
  String get saveToEarnPoints;
  String get alreadySavedToday;

  // Garden
  String get gardenTitle;
  String get inventory;

  // Aquarium
  String get fish;
  String get hour;
  String get price;
  String get lastFed;
  String get fishShop;
  String get owned;
  String get noFishYet;
  String get buyFishBelow;
  String get betta;
  String get guppy;
  String get neonTetra;
  String get molly;
  String get cory;
  String get platy;
  String get tankFull;
  String get fishHungry;

  // ==================== ROCK BALANCING LAN ====================
  String get players;
  String get rockBalancing;
  String get lanNotConnected;
  String get rockCount;
  String get joinGame;
  String get startGame;
  String get approveJoin;
  String get approveLabel;
  String get remove;
  String get pendingApproval;
  String get deniedByHost;
  String get kickedByHost;
  String get waitingForPlayers;
  String get readyLabel;
  String get notReadyLabel;
  String get lobbyHost;
  String get singleplayer;
  String get multiplayer;
  String get createRoom;
  String get scanning;
  String get startServer;
  String get connecting;
  String get reconnecting;
  String get hostsFound;
  String get rescan;
  String get connectionLost;
  String get restartServer;
  String get reconnect;
  String get syncError;
  String get record;
  String get endGame;
  String get rocksStacked;
  String get maxHeightLabel;
  String get failedToStartServer;
  String get connectionFailed;
  String get syncTimeout;
  String get playerLeft;
  String get gameLoading;
  String get tapToReplay;
  String get connectingToRoom;
  String get pendingApprovalShort;
  String get syncingGame;

  // Paper Ship
  String get paperShip;

  // Firefly Catching
  String get fireflyCatching;
  String get jar;
  String get lamp;
  String get caught;
  String get attractMode;
  String get repelMode;
  String get attractShort;
  String get repelShort;
  String get maxFireflyCount;
  String get roleJar;
  String get roleLamp;
  String get switchTool;
  String get selectStartingRole;

  // Painting Room
  String get art;
  String get canvasName;
  String get clear;
  String get undo;
  String get colorPalette;
  String get selected;
  String get clearCanvas;
  String get clearCanvasWarning;
  String get thisWillEraseEverything;
  String get gallery;
  String get myPaintings;
  String paintingNumber(int number);
  String get zoom;
  String get myTracks;

  // Music Room
  String get music;
  String get songName;
  String get selectInstrument;
  String get notes;
  String get note;
  String get piano;
  String get guitar;
  String get synth;
  String get bass;
  String get drum;

  // Scene Shop (additional strings)
  String get yourPoints;
  String get buyCollection;
  String get useCollection;
  String get currentlyUsing;
  String get notEnoughPoints;
  String get points;
  String get free;
  String get ownedBadge;
  String get cozyHome;
  String get forest;
  String get beach;
  String get peachBlossom;
  String get winter;
  String get desert;
  String get cosmic;
  String get castle;
  String get cozyHomeDesc;
  String get forestDesc;
  String get beachDesc;
  String get peachBlossomDesc;
  String get winterDesc;
  String get desertDesc;
  String get cosmicDesc;
  String get castleDesc;

  // Authentication
  String get signUp;
  String get signIn;
  String get email;
  String get password;
  String get confirmPassword;
  String get username;
  String get alreadyHaveAccount;
  String get createAccount;
  String get enterEmail;
  String get enterPassword;
  String get passwordTooShort;
  String get passwordsDoNotMatch;
  String get invalidEmail;
  String get letsGetStarted;
  String get welcomeBack;
  String get dontHaveAccount;
  String get forgotPassword;
  String get forgotPasswordTitle;
  String get forgotPasswordDescription;
  String get forgotPasswordEmailSentDescription;
  String get sendResetEmail;
  String get emailSent;
  String get emailSentSuccessfully;
  String get checkYourInbox;
  String get sendAgain;
  String get rememberPassword;
  String get backToLogin;

  // Sync related
  String get pleaseLoginFirst;
  String get syncing;
  String get login;
  String get logout;

  // Guest mode
  String get useAsGuest;
  String get usingAsGuestMessage;
  String get failedToStartGuestMode;
  String get welcomeUpgradedFromGuest;
  String get registrationSuccessful;
  String get loginSuccessful;
  String get upgradedFromGuestMode;
  String get syncWillRetryLater;

  // Welcome Screen
  String get chooseYourTheme;
  String get pickColorScheme;
  String get selectLanguage;
  String get choosePreferredLanguage;
  String get audioSettings;
  String get customizeAudioExperience;
  String get backgroundMusic;
  String get soundEffects;
  String get enableSFX;
  String get back;
  String get next;
  String get getStarted;

  // Tutorial Screen
  String get tutorialTitle;
  String get tutorialOverviewTitle;
  String get tutorialOverviewDesc;
  String get tutorialTipPrefix;
  String get tutorialTipSuffix;
  String get tutorialPlayTogetherTitle;
  String get tutorialPlayTogetherDesc;
  String get tutorialPlayTogetherDescNative;
  String get tutorialPlayTogetherDescWeb;
  String get tutorialRewardingTitle;
  String get tutorialRewardingDesc;
  String get tutorialCreativeTitle;
  String get tutorialCreativeDesc;
  String get tutorialPrevious;
  String get tutorialNext;
  String get tutorialGotIt;
  String get tutorialSkip;
  String tutorialPageOf(int current, int total);

  // Tutorial overlays — Sleep Guide
  String get tutorialSleepTipTitle;
  String get tutorialSleepTipDesc;
  String get tutorialSleepGridTitle;
  String get tutorialSleepGridDesc;
  String get tutorialSleepGraphTitle;
  String get tutorialSleepGraphDesc;
  String get tutorialSleepCheckinTitle;
  String get tutorialSleepCheckinDesc;

  // Tutorial overlays — Drawing
  String get tutorialDrawCanvasTitle;
  String get tutorialDrawCanvasDesc;
  String get tutorialDrawToolbarTitle;
  String get tutorialDrawToolbarDesc;
  String get tutorialDrawZoomTitle;
  String get tutorialDrawZoomDesc;
  String get tutorialDrawPaletteTitle;
  String get tutorialDrawPaletteDesc;

  // Tutorial overlays — Composing
  String get tutorialComposeToolbarTitle;
  String get tutorialComposeToolbarDesc;
  String get tutorialComposeTimelineTitle;
  String get tutorialComposeTimelineDesc;
  String get tutorialComposePlaybackTitle;
  String get tutorialComposePlaybackDesc;
  String get tutorialComposeNotesTitle;
  String get tutorialComposeNotesDesc;

  // Tutorial overlays — Emotion Diary
  String get tutorialDiaryHistoryTitle;
  String get tutorialDiaryHistoryDesc;
  String get tutorialDiaryQuestionsTitle;
  String get tutorialDiaryQuestionsDesc;
  String get tutorialDiaryNotesTitle;
  String get tutorialDiaryNotesDesc;
  String get tutorialDiarySaveTitle;
  String get tutorialDiarySaveDesc;

  // Theme names
  String get themePastelBlueBreeze;
  String get themeCalmLavender;
  String get themeWarmAmber;
  String get themeMintyFresh;
  String get themeMidnightBlue;
  String get themeSoftPurpleNight;
  String get themeWarmSunset;
  String get themeSereneGreenNight;

  // BGM names
  String get bgmLofiBeats;
  String get bgmRainSounds;
  String get bgmPianoMusic;
  String get bgmAcousticBallad;
  String get bgmFolkSong;
  String get bgmIndieVibes;
  String get bgmSoftPop;
  String get bgmChillAcoustic;

  // Mascot dialogues
  String getMascotSceneGreeting(SceneType scene, int variant);
  String getMascotClickDialogue(SceneType scene, int variant);
  String getMascotSleepDialogue(int variant);

  // Tutorial - Aquarium
  String get tutorialAquariumTankDesc;
  String get tutorialAquariumShopTitle;
  String get tutorialAquariumShopDesc;

  // Tutorial - Garden
  String get tutorialGardenGridDesc;
  String get tutorialGardenInventoryTitle;
  String get tutorialGardenInventoryDesc;

  // Tutorial - Rock Balancing Lobby
  String get tutorialRockLobbyConfigTitle;
  String get tutorialRockLobbyConfigDesc;
  String get tutorialRockLobbyRoomTitle;
  String get tutorialRockLobbyRoomDesc;
  String get tutorialRockLobbyPlayersTitle;
  String get tutorialRockLobbyPlayersDesc;
  String get tutorialRockLobbyStartTitle;
  String get tutorialRockLobbyStartDesc;
  String get tutorialRockLobbyReadyTitle;
  String get tutorialRockLobbyReadyDesc;

  // Tutorial - Rock Balancing Game
  String get tutorialRockGameCanvasTitle;
  String get tutorialRockGameCanvasDesc;
  String get tutorialRockGameCanvasSoloDesc;
  String get tutorialRockGameInfoTitle;
  String get tutorialRockGameInfoDesc;

  // Tutorial - Firefly Lobby
  String get tutorialFireflyLobbyConfigTitle;
  String get tutorialFireflyLobbyConfigDesc;
  String get tutorialFireflyLobbyRoomTitle;
  String get tutorialFireflyLobbyRoomDesc;
  String get tutorialFireflyLobbyPlayersTitle;
  String get tutorialFireflyLobbyPlayersDesc;
  String get tutorialFireflyLobbyRoleTitle;
  String get tutorialFireflyLobbyRoleDesc;
  String get tutorialFireflyLobbyStartTitle;
  String get tutorialFireflyLobbyStartDesc;
  String get tutorialFireflyLobbyReadyTitle;
  String get tutorialFireflyLobbyReadyDesc;

  // Tutorial - Firefly Game
  String get tutorialFireflyGameCanvasTitle;
  String get tutorialFireflyGameCanvasDesc;
  String get tutorialFireflyGameCanvasSoloDesc;
  String get tutorialFireflyGameCaughtTitle;
  String get tutorialFireflyGameCaughtDesc;
  String get tutorialFireflyGameBrightnessTitle;
  String get tutorialFireflyGameBrightnessDesc;
  String get tutorialFireflyGameSwitchTitle;
  String get tutorialFireflyGameSwitchDesc;
  String get tutorialPaperShipGameCanvasTitle;
  String get tutorialPaperShipGameCanvasSoloDesc;
  String get tutorialPaperShipGameCanvasDesc;
  String get tutorialPaperShipGameInfoTitle;
  String get tutorialPaperShipGameInfoDesc;

  // Breathing Exercise
  String get breathing;
  String get breathingExercise;
  String get selectExercise;
  String get exercise478;
  String get exercise478Desc;
  String get exerciseBox;
  String get exerciseBoxDesc;
  String get exerciseDeepBelly;
  String get exerciseDeepBellyDesc;
  String get exerciseCalm;
  String get exerciseCalmDesc;
  String get breatheIn;
  String get breatheOut;
  String get hold;
  String get pause;
  String get cycles;
  String get breathingPraise1;
  String get breathingPraise2;
  String get breathingPraise3;
  String get breathingPraise4;
  String get start;
  String get stop;

  // Sleep Guide
  String get sleep;
  String get sleepGuide;
  String get sleepSchedule;
  String get bedtime;
  String get wakeTime;
  // Sleep tips
  String get sleepTipSetBedtime;
  String get sleepTipEarly;
  String get sleepTipEarly2;
  String get sleepTipEarly3;
  String get sleepTipEarly4;
  String get sleepTipWindDown;
  String get sleepTipWindDown2;
  String get sleepTipWindDown3;
  String get sleepTipLate;
  String get sleepTipVeryLate;

  // Sleep Log (tracking)
  String get sleepLog;
  String get sleepHistory;
  String get tapDayToLogSleep;
  String get actualBedtime;
  String get actualWakeTime;
  String get sleepQuality;
  String get sleepDuration;
  String get sleepLogSaved;
  String get hoursUnit;
  String get noSleepData;

  // Sleep tips card
  String get sleepTipsCardTitle;
  String get sleepTipsLead;
  String get sleepTip1;
  String get sleepTip2;
  String get sleepTip3;
  String get sleepTip4;
  String get sleepTip5;
  String get sleepTip6;
  String get sleepTip7;
  String get sleepTip8;
  String get sleepTip9;
  String get sleepTip10;

  // History grid week labels
  String get sleepLastWeek;
  String get sleepThisWeek;

  // ==================== PWA ====================
  String get newVersionAvailable;
  String get reload;
  String get roomCode;
  String get enterRoomCode;
  String get activeRooms;

  // ==================== PROFILE ====================
  String get menu;
  String get menuProfile;
  String get editProfile;
  String get chooseAvatar;

  // ==================== ACHIEVEMENTS ====================

  // UI labels
  String get achievements;
  String get achievementsTitle;
  String get achievementUnlocked;
  String get locked;
  String get goToFeature;
  String get tapToDismiss;

  /// Returns the localized unit label for achievement progress (e.g. 'days', 'tasks').
  String achievementUnit(String unitKey);

  /// Returns the localized category name.
  /// [category] matches AchievementCategory enum name (e.g. 'engagement').
  String achievementCategoryName(String category);

  /// Returns the localized title for the given achievement [id].
  String achievementTitle(String id);

  /// Returns the localized description for the given achievement [id].
  String achievementDescription(String id);

  // Helper method
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}