import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Speech bubble cho linh vật giao tiếp với người dùng
/// 
/// Features:
/// - Oval shape
/// - Background: 75% opacity
/// - Border: primary with 75% opacity
/// - Optional tail pointing to mascot
enum BubbleTailPosition { none, left, right, top, bottom }

class SpeechBubble extends StatelessWidget {
  final String text;
  final BubbleTailPosition tailPosition;
  final double? width;
  final double? maxWidth;

  const SpeechBubble({
    super.key,
    required this.text,
    this.tailPosition = BubbleTailPosition.bottom,
    this.width,
    this.maxWidth = 300,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    
    return Container(
      width: width,
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: CustomPaint(
        painter: tailPosition != BubbleTailPosition.none
            ? _BubbleTailPainter(tailPosition: tailPosition, theme: theme)
            : null,
        child: Container(
          margin: _getMarginForTail(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: theme.background.withValues(alpha: 0.75), // 75% opacity
            border: Border.all(
              color: theme.primary.withValues(alpha: 0.75), // 75% opacity
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20), // Bo tròn góc oval
          ),
          child: Builder(
            builder: (context) => Text(
              text,
              style: AppTypography.bodyMedium(context, color: theme.text).copyWith(height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  EdgeInsets _getMarginForTail() {
    const tailSize = 12.0;
    switch (tailPosition) {
      case BubbleTailPosition.left:
        return const EdgeInsets.only(left: tailSize);
      case BubbleTailPosition.right:
        return const EdgeInsets.only(right: tailSize);
      case BubbleTailPosition.top:
        return const EdgeInsets.only(top: tailSize);
      case BubbleTailPosition.bottom:
        return const EdgeInsets.only(bottom: tailSize);
      case BubbleTailPosition.none:
        return EdgeInsets.zero;
    }
  }
}

/// Custom painter để vẽ tail của speech bubble
class _BubbleTailPainter extends CustomPainter {
  final BubbleTailPosition tailPosition;
  final AppTheme theme;

  _BubbleTailPainter({
    required this.tailPosition, 
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.background.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = theme.primary.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    const tailSize = 12.0;

    switch (tailPosition) {
      case BubbleTailPosition.bottom:
        // Tail pointing down (center bottom)
        final centerX = size.width / 2;
        final bottomY = size.height - tailSize;
        path.moveTo(centerX - 8, bottomY);
        path.lineTo(centerX, size.height);
        path.lineTo(centerX + 8, bottomY);
        break;

      case BubbleTailPosition.top:
        // Tail pointing up (center top)
        final centerX = size.width / 2;
        path.moveTo(centerX - 8, tailSize);
        path.lineTo(centerX, 0);
        path.lineTo(centerX + 8, tailSize);
        break;

      case BubbleTailPosition.left:
        // Tail pointing left (middle left)
        final centerY = size.height / 2;
        path.moveTo(tailSize, centerY - 8);
        path.lineTo(0, centerY);
        path.lineTo(tailSize, centerY + 8);
        break;

      case BubbleTailPosition.right:
        // Tail pointing right (middle right)
        final centerY = size.height / 2;
        path.moveTo(size.width - tailSize, centerY - 8);
        path.lineTo(size.width, centerY);
        path.lineTo(size.width - tailSize, centerY + 8);
        break;

      case BubbleTailPosition.none:
        return;
    }

    path.close();

    // Draw fill
    canvas.drawPath(path, paint);
    // Draw border
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}