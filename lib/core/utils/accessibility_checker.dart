import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// WCAG AA Contrast Ratio Checker
///
/// WCAG 2.1 Guidelines:
/// - AA Normal Text: 4.5:1 minimum
/// - AA Large Text (18pt+): 3.0:1 minimum
/// - AAA Normal Text: 7.0:1 minimum
/// - AAA Large Text: 4.5:1 minimum
class AccessibilityChecker {
  /// Calculate contrast ratio between two colors
  /// Returns ratio (e.g., 4.5, 3.0)
  ///
  /// Formula: (L1 + 0.05) / (L2 + 0.05)
  /// where L1 is lighter luminance, L2 is darker luminance
  static double getContrastRatio(Color foreground, Color background) {
    final lumFg = _getLuminance(foreground);
    final lumBg = _getLuminance(background);

    final lighter = max(lumFg, lumBg);
    final darker = min(lumFg, lumBg);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Get relative luminance of a color
  /// Uses W3C formula: https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
  static double _getLuminance(Color color) {
    return color.computeLuminance();
  }

  /// Check if color pair meets WCAG AA standard
  ///
  /// - AA Large Text: 3.0:1 minimum
  /// - AA Normal Text: 4.5:1 minimum
  static bool meetsWcagAA(Color fg, Color bg, {bool isLargeText = false}) {
    final ratio = getContrastRatio(fg, bg);
    return isLargeText ? ratio >= 3.0 : ratio >= 4.5;
  }

  /// Check if color pair meets WCAG AAA standard
  ///
  /// - AAA Large Text: 4.5:1 minimum
  /// - AAA Normal Text: 7.0:1 minimum
  static bool meetsWcagAAA(Color fg, Color bg, {bool isLargeText = false}) {
    final ratio = getContrastRatio(fg, bg);
    return isLargeText ? ratio >= 4.5 : ratio >= 7.0;
  }

  /// Audit entire theme for WCAG compliance
  /// Returns detailed report
  static Map<String, dynamic> auditTheme(AppTheme theme) {
    final primaryOnBg = getContrastRatio(theme.primary, theme.background);
    final secondaryOnBg = getContrastRatio(theme.secondary, theme.background);
    final textOnBg = getContrastRatio(theme.text, theme.background);
    final borderOnBg = getContrastRatio(theme.border, theme.background);

    return {
      'themeName': theme.name,
      'themeId': theme.id,
      'isDark': theme.isDark,
      'overallPass': _checkOverallPass(
        primaryOnBg,
        secondaryOnBg,
        textOnBg,
        borderOnBg,
      ),
      'checks': {
        'primaryOnBackground': {
          'ratio': primaryOnBg,
          'passAA_large': primaryOnBg >= 3.0,
          'passAA_normal': primaryOnBg >= 4.5,
          'passAAA_large': primaryOnBg >= 4.5,
          'passAAA_normal': primaryOnBg >= 7.0,
          'recommendation': _getRecommendation(primaryOnBg),
        },
        'secondaryOnBackground': {
          'ratio': secondaryOnBg,
          'passAA_large': secondaryOnBg >= 3.0,
          'passAA_normal': secondaryOnBg >= 4.5,
          'passAAA_large': secondaryOnBg >= 4.5,
          'passAAA_normal': secondaryOnBg >= 7.0,
          'recommendation': _getRecommendation(secondaryOnBg),
        },
        'textOnBackground': {
          'ratio': textOnBg,
          'passAA_large': textOnBg >= 3.0,
          'passAA_normal': textOnBg >= 4.5,
          'passAAA_large': textOnBg >= 4.5,
          'passAAA_normal': textOnBg >= 7.0,
          'recommendation': _getRecommendation(textOnBg),
        },
        'borderOnBackground': {
          'ratio': borderOnBg,
          'passAA_large': borderOnBg >= 3.0,
          'passAA_normal': borderOnBg >= 4.5,
          'passAAA_large': borderOnBg >= 4.5,
          'passAAA_normal': borderOnBg >= 7.0,
          'recommendation': _getRecommendation(borderOnBg),
        },
      },
    };
  }

  /// Audit all themes in AppThemes
  static List<Map<String, dynamic>> auditAllThemes() {
    return AppThemes.all.map((theme) => auditTheme(theme)).toList();
  }

  static bool _checkOverallPass(
    double primaryOnBg,
    double secondaryOnBg,
    double textOnBg,
    double borderOnBg,
  ) {
    // For overall pass, we require:
    // - Text must pass AA normal (4.5:1)
    // - Primary and secondary must pass AA large (3.0:1)
    return textOnBg >= 4.5 && primaryOnBg >= 3.0 && secondaryOnBg >= 3.0;
  }

  static String _getRecommendation(double ratio) {
    if (ratio >= 7.0) {
      return 'Excellent - AAA compliant';
    } else if (ratio >= 4.5) {
      return 'Good - AA compliant for all text';
    } else if (ratio >= 3.0) {
      return 'Acceptable - AA compliant for large text only';
    } else {
      return 'Needs improvement - Does not meet WCAG AA';
    }
  }

  /// Get human-readable summary
  static String getSummary(Map<String, dynamic> audit) {
    final themeName = audit['themeName'];
    final overallPass = audit['overallPass'];
    final checks = audit['checks'] as Map<String, dynamic>;

    final buffer = StringBuffer();
    buffer.writeln('Theme: $themeName');
    buffer.writeln('Overall: ${overallPass ? "✅ PASS" : "❌ FAIL"}');
    buffer.writeln();

    checks.forEach((key, value) {
      final data = value as Map<String, dynamic>;
      final ratio = data['ratio'] as double;
      final passAA = data['passAA_normal'] as bool;
      final icon = passAA ? '✅' : '⚠️';
      buffer.writeln('$icon $key: ${ratio.toStringAsFixed(2)}:1');
    });

    return buffer.toString();
  }

  /// Suggest color adjustments to meet WCAG AA
  /// Returns adjusted color that meets minimum contrast ratio
  static Color suggestAdjustment(
    Color original,
    Color background, {
    double targetRatio = 4.5,
  }) {
    // Simple algorithm: Lighten or darken original color
    // until it meets target ratio

    final bgLuminance = background.computeLuminance();
    final shouldLighten = bgLuminance < 0.5;

    var adjusted = original;
    var ratio = getContrastRatio(adjusted, background);

    // Try up to 50 steps
    for (var i = 0; i < 50 && ratio < targetRatio; i++) {
      if (shouldLighten) {
        // Lighten
        adjusted = Color.lerp(adjusted, Colors.white, 0.05)!;
      } else {
        // Darken
        adjusted = Color.lerp(adjusted, Colors.black, 0.05)!;
      }
      ratio = getContrastRatio(adjusted, background);
    }

    return adjusted;
  }
}
