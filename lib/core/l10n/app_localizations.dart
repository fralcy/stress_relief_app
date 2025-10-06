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
  
  // Helper method để lấy translations từ context
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}