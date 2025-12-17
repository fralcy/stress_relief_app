import 'package:flutter/material.dart';

/// Responsive utilities for adaptive UI sizing
class ResponsiveUtils {
  /// Base design width (iPhone 13 Pro / Pixel 5)
  static const double _baseWidth = 390.0;

  /// Base design height
  static const double _baseHeight = 844.0;

  /// Get scaled font size based on screen width
  ///
  /// Example:
  /// ```dart
  /// fontSize: ResponsiveUtils.sp(context, 16)
  /// ```
  static double sp(BuildContext context, double fontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / _baseWidth;

    // Clamp scale between 0.85 and 1.2 to prevent extreme sizes
    final clampedScale = scale.clamp(0.85, 1.2);

    return fontSize * clampedScale;
  }

  /// Get scaled width based on design width
  ///
  /// Example:
  /// ```dart
  /// width: ResponsiveUtils.w(context, 100)
  /// ```
  static double w(BuildContext context, double width) {
    final screenWidth = MediaQuery.of(context).size.width;
    return width * (screenWidth / _baseWidth);
  }

  /// Get scaled height based on design height
  ///
  /// Example:
  /// ```dart
  /// height: ResponsiveUtils.h(context, 50)
  /// ```
  static double h(BuildContext context, double height) {
    final screenHeight = MediaQuery.of(context).size.height;
    return height * (screenHeight / _baseHeight);
  }

  /// Check if screen is small (width < 360)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Check if screen is large (width > 428)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 428;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context, {
    double horizontal = 24,
    double vertical = 24,
  }) {
    final scale = MediaQuery.of(context).size.width / _baseWidth;
    final clampedScale = scale.clamp(0.85, 1.15);

    return EdgeInsets.symmetric(
      horizontal: horizontal * clampedScale,
      vertical: vertical * clampedScale,
    );
  }

  /// Get responsive spacing
  static double spacing(BuildContext context, double baseSpacing) {
    final scale = MediaQuery.of(context).size.width / _baseWidth;
    final clampedScale = scale.clamp(0.9, 1.1);
    return baseSpacing * clampedScale;
  }
}

/// Extension on BuildContext for easier access
extension ResponsiveExtension on BuildContext {
  /// Get responsive font size
  ///
  /// Example:
  /// ```dart
  /// fontSize: context.sp(16)
  /// ```
  double sp(double fontSize) => ResponsiveUtils.sp(this, fontSize);

  /// Get responsive width
  double rw(double width) => ResponsiveUtils.w(this, width);

  /// Get responsive height
  double rh(double height) => ResponsiveUtils.h(this, height);

  /// Get responsive spacing
  double spacing(double baseSpacing) => ResponsiveUtils.spacing(this, baseSpacing);

  /// Check if small screen
  bool get isSmallScreen => ResponsiveUtils.isSmallScreen(this);

  /// Check if large screen
  bool get isLargeScreen => ResponsiveUtils.isLargeScreen(this);
}
