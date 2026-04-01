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
  List<Color> get previewColors => [
    primary,
    secondary,
    text,
    background,
    border,
  ];

  /// Generate Material 3 ColorScheme from theme colors
  /// This enables full M3 support with semantic colors
  ColorScheme toColorScheme() {
    if (isDark) {
      return ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: secondary,
        surface: background,
      );
    } else {
      return ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: background,
      );
    }
  }
}

/// All available themes
///
/// WCAG AA compliance targets per pair (measured at design time):
///   text / background   ≥ 4.5:1  (normal text)
///   border / background ≥ 3.0:1  (UI component / non-text)
///   text / primary      ≥ 3.0:1  (UI component / non-text)
///   primary / background≥ 3.0:1  (UI component / non-text)
///   text / secondary    ≥ 3.0:1  (UI component / non-text)
///   secondary /background≥ 3.0:1 (UI component / non-text)
///
/// Note: satisfying text/primary ≥ 4.5:1 AND primary/background ≥ 4.5:1
/// simultaneously is mathematically impossible for any standard light/dark
/// theme (where text and background are on opposite luminance ends).
/// The 3.0:1 target for non-text pairs follows WCAG 1.4.11 (UI Components).
/// If text is rendered directly ON a primary-colored background (e.g. inside
/// a button), add a separate `onPrimary` / `onSecondary` color field.
class AppThemes {
  // ── Light themes ────────────────────────────────────────────────────────────

  /// Pastel Blue Breeze — WCAG ratios:
  ///   text/bg 15.08 | border/bg 4.29 | text/primary 3.05 |
  ///   primary/bg 4.94 | text/secondary 3.01 | secondary/bg 5.01
  static const pastelBlueBreeze = AppTheme(
    id: 'pastel_blue_breeze',
    name: 'Pastel Blue Breeze',
    primary: Color(0xFF2563EB),
    secondary: Color(0xFF0E7A6A),
    text: Color(0xFF1A2333),
    background: Color(0xFFF8FAFD),
    border: Color(0xFF5A7A9A),
    isDark: false,
  );

  /// Calm Lavender — WCAG ratios:
  ///   text/bg 16.05 | border/bg 5.61 | text/primary 3.07 |
  ///   primary/bg 5.22 | text/secondary 3.24 | secondary/bg 4.95
  static const calmLavender = AppTheme(
    id: 'calm_lavender',
    name: 'Calm Lavender',
    primary: Color(0xFF8040E8),
    secondary: Color(0xFFBE3878),
    text: Color(0xFF1E1A2E),
    background: Color(0xFFFAF8FF),
    border: Color(0xFF6B5A9A),
    isDark: false,
  );

  /// Warm Amber — WCAG ratios:
  ///   text/bg 17.36 | border/bg 5.53 | text/primary 4.13 |
  ///   primary/bg 4.21 | text/secondary 3.02 | secondary/bg 5.74
  static const warmAmber = AppTheme(
    id: 'warm_amber',
    name: 'Warm Amber',
    primary: Color(0xFFA07200),
    secondary: Color(0xFFA84800),
    text: Color(0xFF1C1810),
    background: Color(0xFFFFFDF5),
    border: Color(0xFF7A6530),
    isDark: false,
  );

  /// Minty Fresh — WCAG ratios:
  ///   text/bg 16.72 | border/bg 5.62 | text/primary 3.22 |
  ///   primary/bg 5.19 | text/secondary 3.27 | secondary/bg 5.11
  static const mintyFresh = AppTheme(
    id: 'minty_fresh',
    name: 'Minty Fresh',
    primary: Color(0xFF0C7A60),
    secondary: Color(0xFFCC3030),
    text: Color(0xFF141E1C),
    background: Color(0xFFF5FFFD),
    border: Color(0xFF3A7060),
    isDark: false,
  );

  // ── Dark themes ─────────────────────────────────────────────────────────────

  /// Midnight Blue — WCAG ratios:
  ///   text/bg 11.66 | border/bg 4.24 | text/primary 3.84 |
  ///   primary/bg 3.04 | text/secondary 3.66 | secondary/bg 3.19
  static const midnightBlue = AppTheme(
    id: 'midnight_blue',
    name: 'Midnight Blue',
    primary: Color(0xFF2060C0),
    secondary: Color(0xFF1A7080),
    text: Color(0xFFC0D0E8),
    background: Color(0xFF0C1620),
    border: Color(0xFF508098),
    isDark: true,
  );

  /// Soft Purple Night — WCAG ratios:
  ///   text/bg 12.18 | border/bg 4.42 | text/primary 3.67 |
  ///   primary/bg 3.32 | text/secondary 3.40 | secondary/bg 3.58
  static const softPurpleNight = AppTheme(
    id: 'soft_purple_night',
    name: 'Soft Purple Night',
    primary: Color(0xFF7848C8),
    secondary: Color(0xFF9050A0),
    text: Color(0xFFCCC8EE),
    background: Color(0xFF0C0A18),
    border: Color(0xFF8070A0),
    isDark: true,
  );

  /// Warm Sunset — WCAG ratios:
  ///   text/bg 11.90 | border/bg 5.02 | text/primary 3.16 |
  ///   primary/bg 3.76 | text/secondary 3.05 | secondary/bg 3.90
  static const warmSunset = AppTheme(
    id: 'warm_sunset',
    name: 'Warm Sunset',
    primary: Color(0xFFB84848),
    secondary: Color(0xFF207898),
    text: Color(0xFFE0C890),
    background: Color(0xFF100C08),
    border: Color(0xFFA07870),
    isDark: true,
  );

  /// Serene Green Night — WCAG ratios:
  ///   text/bg 11.62 | border/bg 4.29 | text/primary 3.26 |
  ///   primary/bg 3.56 | text/secondary 3.29 | secondary/bg 3.53
  static const sereneGreenNight = AppTheme(
    id: 'serene_green_night',
    name: 'Serene Green Night',
    primary: Color(0xFF287848),
    secondary: Color(0xFF1E7848),
    text: Color(0xFFB8CEC0),
    background: Color(0xFF080E18),
    border: Color(0xFF508070),
    isDark: true,
  );

  /// All themes list
  static const List<AppTheme> all = [
    pastelBlueBreeze,
    calmLavender,
    warmAmber,
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
