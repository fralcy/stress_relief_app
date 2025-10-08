import 'data_manager.dart';

/// Quản lý theme preference thông qua DataManager
class ThemeStorage {
  /// Lấy theme ID hiện tại
  static String getThemeId() {
    return DataManager().userSettings.currentTheme;
  }
  
  /// Lưu theme ID mới
  static void saveThemeId(String themeId) {
    final currentSettings = DataManager().userSettings;
    DataManager().saveUserSettings(
      currentSettings.copyWith(currentTheme: themeId),
    );
  }
  
  /// Reset về theme mặc định
  static void resetTheme() {
    saveThemeId('pastel_blue_breeze');
  }
}