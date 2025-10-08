import 'package:flutter/material.dart';
import 'data_manager.dart';

/// Quản lý ngôn ngữ thông qua DataManager
class LocaleStorage {
  /// Danh sách ngôn ngữ được hỗ trợ
  static const List<Locale> supportedLocales = [
    Locale('vi', 'VN'), // Tiếng Việt
    Locale('en', 'US'), // English
  ];
  
  /// Lấy locale hiện tại
  static Locale getLocale() {
    final languageCode = DataManager().userSettings.currentLanguage;
    
    // Tìm locale tương ứng
    return supportedLocales.firstWhere(
      (locale) => locale.languageCode == languageCode,
      orElse: () => const Locale('vi', 'VN'), // Default
    );
  }
  
  /// Lưu locale mới
  static void saveLocale(Locale locale) {
    final currentSettings = DataManager().userSettings;
    DataManager().saveUserSettings(
      currentSettings.copyWith(currentLanguage: locale.languageCode),
    );
  }
}