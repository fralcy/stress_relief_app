import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Custom card với header và content
/// 
/// Variants:
/// - Static: Header + Content luôn hiển thị
/// - Expandable: Có thể thu gọn/mở rộng bằng arrow button
class AppCard extends StatefulWidget {
  final String title;
  final Widget content;
  final bool isExpandable;
  final bool initiallyExpanded;
  final double? width;

  const AppCard({
    super.key,
    required this.title,
    required this.content,
    this.isExpandable = false,
    this.initiallyExpanded = true,
    this.width,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    if (!widget.isExpandable) return;
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: theme.background,
        border: Border.all(color: theme.border, width: 1.5),
        borderRadius: BorderRadius.circular(16), // Bo tròn góc
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(),
          
          // Content (có thể collapse)
          if (_isExpanded) ...[
            Divider(
              color: theme.border,
              height: 1,
              thickness: 1,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: widget.content,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Builder(
      builder: (context) {
        final theme = context.theme;
        
        return InkWell(
          onTap: widget.isExpandable ? _toggleExpanded : null,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(16),
            bottom: _isExpanded ? Radius.zero : const Radius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: widget.isExpandable
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      // Title (centered)
                      Center(
                        child: Text(
                          widget.title,
                          style: AppTypography.h4(context, color: theme.text),
                        ),
                      ),
                      
                      // Arrow (positioned right)
                      Positioned(
                        right: 0,
                        child: Icon(
                          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: theme.text,
                          size: 24,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      widget.title,
                      style: AppTypography.h4(context, color: theme.text),
                    ),
                  ),
          ),
        );
      }
    );
  }
}