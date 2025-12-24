import 'package:flutter/material.dart';

/// Material 3 Shape System
/// Based on discovered border radius patterns: 8, 12, 16, 20
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: AppShapes.medium.borderRadius,
///   ),
/// )
///
/// // Or via extension
/// shape: context.shapes.large
/// ```
class AppShapes {
  // M3 Shape Scale (ExtraSmall to ExtraLarge)

  /// Extra Small - 4px radius (for very small UI elements)
  static const extraSmall = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  /// Small - 8px radius (dropdowns, small buttons)
  static const small = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  /// Medium - 12px radius (buttons, text fields)
  static const medium = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  /// Large - 16px radius (cards, containers)
  static const large = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

  /// Extra Large - 20px radius (modals, bottom sheets)
  static const extraLarge = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  /// Full - Circular (for pills, chips)
  static const full = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(9999)),
  );

  /// Convert to Material 3 ShapeTheme (for ThemeData)
  /// Note: Flutter doesn't have a built-in ShapeTheme yet,
  /// but we can access shapes via extension methods
  static Map<String, ShapeBorder> get all => {
    'extraSmall': extraSmall,
    'small': small,
    'medium': medium,
    'large': large,
    'extraLarge': extraLarge,
    'full': full,
  };
}

/// Extension for easy shape access via BuildContext
extension ShapeExtension on BuildContext {
  /// Access shape constants easily
  /// Example: context.shapes.medium
  AppShapesHelper get shapes => AppShapesHelper();
}

/// Helper class to provide dot notation access
class AppShapesHelper {
  RoundedRectangleBorder get extraSmall => AppShapes.extraSmall;
  RoundedRectangleBorder get small => AppShapes.small;
  RoundedRectangleBorder get medium => AppShapes.medium;
  RoundedRectangleBorder get large => AppShapes.large;
  RoundedRectangleBorder get extraLarge => AppShapes.extraLarge;
  RoundedRectangleBorder get full => AppShapes.full;
}
