import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import '../providers/theme_provider.dart';

/// Extension để dùng context.theme thay vì AppColors
extension BuildContextTheme on BuildContext {
  AppTheme get theme {
    try {
      return watch<ThemeProvider>().currentTheme;
    } catch (e) {
      // Fallback nếu chưa có Provider
      return AppThemes.pastelBlueBreeze;
    }
  }
}