import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Custom scrollbar wrapper cho themed scrolling
/// 
/// Features:
/// - Thumb: primary color
/// - Track: border color
/// - Smooth scroll behavior
/// - Auto-hide khi không scroll
class AppScroller extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final Axis scrollDirection;
  final bool alwaysShowScrollbar;

  const AppScroller({
    super.key,
    required this.child,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.alwaysShowScrollbar = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    
    return Scrollbar(
      controller: controller,
      thumbVisibility: alwaysShowScrollbar,
      trackVisibility: alwaysShowScrollbar,
      thickness: 8,
      radius: const Radius.circular(4), // Bo tròn góc
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false, // Hide default scrollbar
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            scrollbarTheme: ScrollbarThemeData(
              thumbColor: WidgetStateProperty.all(theme.primary),
              trackColor: WidgetStateProperty.all(theme.border.withOpacity(0.3)),
              trackBorderColor: WidgetStateProperty.all(Colors.transparent),
              radius: const Radius.circular(4),
              thickness: WidgetStateProperty.all(8),
              minThumbLength: 48,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Helper widget: Scrollable Column với AppScroller
class ScrollableColumn extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final ScrollController? controller;

  const ScrollableColumn({
    super.key,
    required this.children,
    this.padding,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AppScroller(
      controller: controller,
      child: SingleChildScrollView(
        controller: controller,
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}