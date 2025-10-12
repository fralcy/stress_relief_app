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
  String get reset;
  
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
  
  // Helper method
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}