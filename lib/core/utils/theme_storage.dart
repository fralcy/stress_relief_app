import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý lưu trữ theme preference
class ThemeStorage {
  static const String _themeKey = 'app_theme';
  static const String _defaultTheme = 'pastel_blue_breeze';
  
  /// Lấy theme ID đã lưu (hoặc default)
  static Future<String> getThemeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? _defaultTheme;
  }
  
  /// Lưu theme ID
  static Future<void> saveThemeId(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeId);
  }
  
  /// Xóa theme (reset về default)
  static Future<void> clearTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
  }
}