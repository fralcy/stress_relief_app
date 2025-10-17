import 'package:flutter/material.dart';

/// Theme data structure
class AppTheme {
  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color text;
  final Color background;
  final Color border;
  final bool isDark;

  const AppTheme({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.text,
    required this.background,
    required this.border,
    required this.isDark,
  });

  /// Get preview colors for settings
  List<Color> get previewColors => [primary, secondary, text, background, border];
}

/// All available themes
class AppThemes {
  // Light themes
  static const pastelBlueBreeze = AppTheme(
    id: 'pastel_blue_breeze',
    name: 'Pastel Blue Breeze',
    primary: Color(0xFF8EC5FC),
    secondary: Color(0xFFB2F7EF),
    text: Color(0xFF2D3748),
    background: Color(0xFFFDFEFE),
    border: Color(0xFFCBD5E0),
    isDark: false,
  );

  static const calmLavender = AppTheme(
    id: 'calm_lavender',
    name: 'Calm Lavender',
    primary: Color(0xFFCBB2FE),
    secondary: Color(0xFFFFD6E8),
    text: Color(0xFF2F2F2F),
    background: Color(0xFFFFFDFD),
    border: Color(0xFFE0D7F9),
    isDark: false,
  );

  static const sunnyPastelYellow = AppTheme(
    id: 'sunny_pastel_yellow',
    name: 'Sunny Pastel Yellow',
    primary: Color(0xFFFFE29A),
    secondary: Color(0xFFFFD3B6),
    text: Color(0xFF3A3A3A),
    background: Color(0xFFFFFEFB),
    border: Color(0xFFF6E7C1),
    isDark: false,
  );

  static const mintyFresh = AppTheme(
    id: 'minty_fresh',
    name: 'Minty Fresh',
    primary: Color(0xFFB8F2E6),
    secondary: Color(0xFFFFB7B2),
    text: Color(0xFF2B2B2B),
    background: Color(0xFFFFFFFF),
    border: Color(0xFFD1F2EB),
    isDark: false,
  );

  // Dark themes
  static const midnightBlue = AppTheme(
    id: 'midnight_blue',
    name: 'Midnight Blue',
    primary: Color(0xFF4F86F7),
    secondary: Color(0xFF89CFF0),
    text: Color(0xFFF1F5F9),
    background: Color(0xFF1E293B),
    border: Color(0xFF334155),
    isDark: true,
  );

  static const softPurpleNight = AppTheme(
    id: 'soft_purple_night',
    name: 'Soft Purple Night',
    primary: Color(0xFFA78BFA),
    secondary: Color(0xFFF0ABFC),
    text: Color(0xFFF9FAFB),
    background: Color(0xFF18181B),
    border: Color(0xFF3F3F46),
    isDark: true,
  );

  static const warmSunset = AppTheme(
    id: 'warm_sunset',
    name: 'Warm Sunset',
    primary: Color(0xFFFCA5A5),
    secondary: Color(0xFFFDE68A),
    text: Color(0xFFFEF9C3),
    background: Color(0xFF1C1917),
    border: Color(0xFF374151),
    isDark: true,
  );

  static const sereneGreenNight = AppTheme(
    id: 'serene_green_night',
    name: 'Serene Green Night',
    primary: Color(0xFF86EFAC),
    secondary: Color(0xFFA7F3D0),
    text: Color(0xFFF3F4F6),
    background: Color(0xFF111827),
    border: Color(0xFF374151),
    isDark: true,
  );

  /// All themes list
  static const List<AppTheme> all = [
    pastelBlueBreeze,
    calmLavender,
    sunnyPastelYellow,
    mintyFresh,
    midnightBlue,
    softPurpleNight,
    warmSunset,
    sereneGreenNight,
  ];

  /// Get theme by ID
  static AppTheme getById(String id) {
    return all.firstWhere(
      (theme) => theme.id == id,
      orElse: () => pastelBlueBreeze,
    );
  }
}