import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// Centralized typography system with responsive font sizes
///
/// Usage:
/// ```dart
/// Text('Title', style: AppTypography.h1(context))
/// Text('Body', style: AppTypography.body(context, color: theme.text))
/// ```
class AppTypography {
  // ==================== HEADINGS ====================

  /// Heading 1 - Main page titles (28-32px base)
  static TextStyle h1(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: context.sp(28),
      fontWeight: FontWeight.bold,
      height: 1.2,
      color: color,
    );
  }

  /// Heading 2 - Section titles (24px base)
  static TextStyle h2(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: context.sp(24),
      fontWeight: FontWeight.bold,
      height: 1.3,
      color: color,
    );
  }

  /// Heading 3 - Subsection titles (20px base)
  static TextStyle h3(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: context.sp(20),
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: color,
    );
  }

  /// Heading 4 - Card titles (18px base)
  static TextStyle h4(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: context.sp(18),
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: color,
    );
  }

  // ==================== BODY TEXT ====================

  /// Body Large - Main content (16px base)
  static TextStyle bodyLarge(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: context.sp(16),
      fontWeight: fontWeight ?? FontWeight.normal,
      height: 1.5,
      color: color,
    );
  }

  /// Body Medium - Secondary content (14px base)
  static TextStyle bodyMedium(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: context.sp(14),
      fontWeight: fontWeight ?? FontWeight.normal,
      height: 1.5,
      color: color,
    );
  }

  /// Body Small - Tertiary content (12px base)
  static TextStyle bodySmall(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: context.sp(12),
      fontWeight: fontWeight ?? FontWeight.normal,
      height: 1.5,
      color: color,
    );
  }

  // ==================== LABELS ====================

  /// Label Large - Form labels, buttons (16px base)
  static TextStyle labelLarge(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: context.sp(16),
      fontWeight: fontWeight ?? FontWeight.w500,
      height: 1.4,
      letterSpacing: 0.1,
      color: color,
    );
  }

  /// Label Medium - Secondary labels (14px base)
  static TextStyle labelMedium(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: context.sp(14),
      fontWeight: fontWeight ?? FontWeight.w500,
      height: 1.4,
      letterSpacing: 0.1,
      color: color,
    );
  }

  /// Label Small - Tiny labels, tags (12px base)
  static TextStyle labelSmall(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: context.sp(12),
      fontWeight: fontWeight ?? FontWeight.w500,
      height: 1.4,
      letterSpacing: 0.1,
      color: color,
    );
  }

  // ==================== CAPTIONS ====================

  /// Caption - Hints, helper text (12px base)
  static TextStyle caption(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: context.sp(12),
      fontWeight: FontWeight.normal,
      height: 1.4,
      color: color,
    );
  }

  /// Caption Small - Very small text (10px base)
  static TextStyle captionSmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: context.sp(10),
      fontWeight: FontWeight.normal,
      height: 1.4,
      color: color,
    );
  }

  // ==================== BUTTONS ====================

  /// Button Large - Primary buttons (16px base)
  static TextStyle button(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: context.sp(16),
      fontWeight: FontWeight.bold,
      height: 1.2,
      letterSpacing: 0.2,
      color: color,
    );
  }

  /// Button Small - Secondary buttons (14px base)
  static TextStyle buttonSmall(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: context.sp(14),
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.2,
      color: color,
    );
  }

  // ==================== SPECIAL ====================

  /// Display - Extra large titles (32px base)
  static TextStyle display(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: context.sp(32),
      fontWeight: FontWeight.bold,
      height: 1.1,
      color: color,
    );
  }

  /// Overline - Small uppercase labels (11px base)
  static TextStyle overline(BuildContext context, {Color? color}) {
    return TextStyle(
      fontSize: context.sp(11),
      fontWeight: FontWeight.w600,
      height: 1.5,
      letterSpacing: 1.5,
      color: color,
    );
  }

  // ==================== M3 INTEGRATION ====================

  /// Generate Material 3 compliant TextTheme
  /// Maps AppTypography to M3 standard naming
  static TextTheme toTextTheme(BuildContext context, {Color? color}) {
    return TextTheme(
      // Display styles (largest text)
      displayLarge: display(context, color: color),
      displayMedium: h1(context, color: color),
      displaySmall: h2(context, color: color),

      // Headline styles
      headlineLarge: h2(context, color: color),
      headlineMedium: h3(context, color: color),
      headlineSmall: h4(context, color: color),

      // Title styles
      titleLarge: h3(context, color: color),
      titleMedium: h4(context, color: color),
      titleSmall: labelLarge(context, color: color, fontWeight: FontWeight.w600),

      // Body styles
      bodyLarge: bodyLarge(context, color: color),
      bodyMedium: bodyMedium(context, color: color),
      bodySmall: bodySmall(context, color: color),

      // Label styles
      labelLarge: labelLarge(context, color: color),
      labelMedium: labelMedium(context, color: color),
      labelSmall: labelSmall(context, color: color),
    );
  }
}

/// Extension cho BuildContext để dễ sử dụng
extension TypographyExtension on BuildContext {
  // Headings
  TextStyle get h1 => AppTypography.h1(this);
  TextStyle get h2 => AppTypography.h2(this);
  TextStyle get h3 => AppTypography.h3(this);
  TextStyle get h4 => AppTypography.h4(this);

  // Body
  TextStyle get bodyLarge => AppTypography.bodyLarge(this);
  TextStyle get bodyMedium => AppTypography.bodyMedium(this);
  TextStyle get bodySmall => AppTypography.bodySmall(this);

  // Labels
  TextStyle get labelLarge => AppTypography.labelLarge(this);
  TextStyle get labelMedium => AppTypography.labelMedium(this);
  TextStyle get labelSmall => AppTypography.labelSmall(this);

  // Others
  TextStyle get caption => AppTypography.caption(this);
  TextStyle get button => AppTypography.button(this);
  TextStyle get display => AppTypography.display(this);
}
