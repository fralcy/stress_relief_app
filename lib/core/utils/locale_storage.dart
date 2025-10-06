import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý lưu trữ ngôn ngữ
class LocaleStorage {
  static const String _localeKey = 'app_locale';
  static const String _defaultLocale = 'vi'; // Tiếng Việt mặc định
  
  /// Danh sách ngôn ngữ được hỗ trợ
  static const List<Locale> supportedLocales = [
    Locale('vi', 'VN'), // Tiếng Việt
    Locale('en', 'US'), // English
  ];
  
  /// Lấy locale đã lưu (hoặc mặc định)
  static Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey) ?? _defaultLocale;
    
    // Tìm locale tương ứng
    return supportedLocales.firstWhere(
      (locale) => locale.languageCode == languageCode,
      orElse: () => const Locale('vi', 'VN'),
    );
  }
  
  /// Lưu locale
  static Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}