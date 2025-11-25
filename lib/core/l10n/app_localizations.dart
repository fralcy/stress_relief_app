import 'package:flutter/material.dart';

/// Base class cho localization
/// Mỗi ngôn ngữ sẽ implement class này
abstract class AppLocalizations {
  // App info
  String get appName;
  
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
  String get on;
  String get off;
  
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
  String get cloudSyncComingSoon;
  String get resetConfirmation;

  // Schedule Task
  String get scheduleTask;
  String get taskName;
  String get addTask;
  String get editTask;
  String get completed;
  String get earnPoints;
                     
  String get noTasksYet;
  String get enterTaskName;
  String get taskAdded;
  String get taskDeleted;
  String get taskUpdated;
  String get taskNameRequired;
  String get expectedPoints;
  String get endDayAndClaimPoints;
  String get completedTasks;
  String get alreadyClaimedToday;
  String get noCompletedTasks;
  String get pointsClaimed;
  String get alreadyClaimedOrNoTasks;
  String get sceneShop;
  String get feature;
  
  // Emotion Diary
  String get emotionDiary;
  String get historyLast2Weeks;
  String get tapDayToViewDetails;
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
  String get journalSaved;
  String get saveToEarnPoints;
  String get alreadySavedToday;

  // Garden
  String get gardenTitle;
  String get inventory;
  String get action;
  String get plant;
  String get water;
  String get pestControl;
  String get harvest;
  String get plantedSuccessfully;
  String get wateredSuccessfully;
  String get pestControlSuccessfully;
  String harvestedSuccessfully(int count, int points);

  // Aquarium
  String get fish;
  String get hour;
  String get lastFed;
  String get hoursAgo;
  String get feedNow;
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
  String get readyToFeed;
  String get hoursLeft;
  String get claimCoins;
  String get tankFull;
  String get maxFish;

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
  String get selectNote;
  String get eraser;

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
  String get japanese;
  String get winter;
  String get cozyHomeDesc;
  String get forestDesc;
  String get beachDesc;
  String get japaneseDesc;
  String get winterDesc;

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
  String get enterUsername;
  String get passwordTooShort;
  String get passwordsDoNotMatch;
  String get invalidEmail;
  String get usernameRequired;
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
  String get tutorialPointsTitle;
  String get tutorialPointsDesc;
  String get tutorialLifestyleSupportTitle;
  String get tutorialLifestyleSupportDesc;
  String get tutorialRewardingTitle;
  String get tutorialRewardingDesc;
  String get tutorialCreativeTitle;
  String get tutorialCreativeDesc;
  String get tutorialSettingsTitle;
  String get tutorialSettingsDesc;
  String get tutorialPrevious;
  String get tutorialNext;
  String get tutorialGotIt;
  String get tutorialSkip;
  String tutorialPageOf(int current, int total);

  // Theme names
  String get themePastelBlueBreeze;
  String get themeCalmLavender;
  String get themeSunnyPastelYellow;
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

  // Helper method
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}