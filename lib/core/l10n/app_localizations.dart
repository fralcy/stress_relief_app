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
  
  // Navigation - 5 phòng
  String get livingRoom;
  String get garden;
  String get aquarium;
  String get paintingRoom;
  String get musicRoom;
  
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

  // Helper method
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}