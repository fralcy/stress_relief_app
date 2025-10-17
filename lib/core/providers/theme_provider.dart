import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/data_manager.dart';

/// Provider để quản lý theme state
class ThemeProvider extends ChangeNotifier {
  AppTheme _currentTheme;

  ThemeProvider() : _currentTheme = AppThemes.pastelBlueBreeze {
    _loadTheme();
  }

  AppTheme get currentTheme => _currentTheme;

  /// Load theme từ DataManager
  void _loadTheme() {
    final themeId = DataManager().userSettings.currentTheme;
    _currentTheme = AppThemes.getById(themeId);
  }

  /// Đổi theme và lưu vào DataManager
  void setTheme(String themeId) {
    final newTheme = AppThemes.getById(themeId);
    if (newTheme.id == _currentTheme.id) return;

    _currentTheme = newTheme;
    
    // Save to DataManager
    final settings = DataManager().userSettings;
    DataManager().saveUserSettings(
      settings.copyWith(currentTheme: themeId),
    );

    notifyListeners();
  }
}