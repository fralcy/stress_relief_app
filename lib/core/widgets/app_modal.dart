import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_scroller.dart';

/// Custom modal với header, title và close button
/// 
/// Features:
/// - Header: Title + X button
/// - Scrollable content nếu dài
/// - Backdrop dim
/// - Slide up animation
class AppModal extends StatelessWidget {
  final String title;
  final Widget content;
  final double maxHeight;

  const AppModal({
    super.key,
    required this.title,
    required this.content,
    this.maxHeight = 600,
  });

  /// Show modal helper
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    double maxHeight = 600,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppModal(
        title: title,
        content: content,
        maxHeight: maxHeight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24), // Bo tròn góc trên
        ),
        border: Border(
          top: BorderSide(color: theme.border, width: 2),
          left: BorderSide(color: theme.border, width: 2),
          right: BorderSide(color: theme.border, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context),
          
          // Divider
          Divider(
            color: theme.border,
            height: 1,
            thickness: 1.5,
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
          ),
          
          // Close button (positioned right)
          Positioned(
            right: 0,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 24),
              color: theme.text,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}