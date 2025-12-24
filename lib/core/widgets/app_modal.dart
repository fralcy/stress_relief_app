import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_shapes.dart';
import '../constants/app_typography.dart';
import 'app_scroller.dart';

/// Custom modal với header, title và close button
///
/// Features:
/// - Header: Title + X button + optional ? button
/// - Scrollable content nếu dài
/// - Backdrop dim
/// - Slide up animation
class AppModal extends StatelessWidget {
  final String title;
  final Widget content;
  final double maxHeight;
  final VoidCallback? onHelpPressed;

  const AppModal({
    super.key,
    required this.title,
    required this.content,
    this.maxHeight = 600,
    this.onHelpPressed,
  });

  /// Show modal helper
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    double maxHeight = 600,
    VoidCallback? onHelpPressed,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppModal(
        title: title,
        content: content,
        maxHeight: maxHeight,
        onHelpPressed: onHelpPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: BoxDecoration(
        // M3 surface color
        color: context.surfaceColor,

        // M3 shape (extra large for modals)
        borderRadius: BorderRadius.vertical(
          top: (context.shapes.extraLarge.borderRadius as BorderRadius).topLeft,
        ),

        // M3 outline border
        border: Border(
          top: BorderSide(color: context.outline, width: 1),
          left: BorderSide(color: context.outline, width: 1),
          right: BorderSide(color: context.outline, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context),
          
          // M3 Divider
          Divider(
            color: context.outlineVariant,
            height: 1,
            thickness: 1,
          ),
          
          // Scrollable content với custom scroller
          Flexible(
            child: AppScroller(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Title (centered)
          Center(
            child: Text(
              title,
              style: AppTypography.h3(context, color: theme.text),
            ),
          ),

          // Help button (positioned left) - only if onHelpPressed is provided
          if (onHelpPressed != null)
            Positioned(
              left: 0,
              child: Semantics(
                label: 'Help',
                button: true,
                enabled: true,
                child: IconButton(
                  onPressed: onHelpPressed,
                  icon: const Icon(Icons.help_outline, size: 24),
                  // M3 semantic color for primary action
                  color: context.primaryColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  style: IconButton.styleFrom(
                    // M3 state layers
                    foregroundColor: context.primaryColor,
                    shape: context.shapes.small,
                  ),
                ),
              ),
            ),

          // Close button (positioned right)
          Positioned(
            right: 0,
            child: Semantics(
              label: 'Close',
              button: true,
              enabled: true,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 24),
                // M3 semantic color for neutral action
                color: context.onSurfaceVariant,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                style: IconButton.styleFrom(
                  // M3 state layers
                  foregroundColor: context.onSurfaceVariant,
                  shape: context.shapes.small,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}