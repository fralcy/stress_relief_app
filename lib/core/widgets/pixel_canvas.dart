import 'package:flutter/material.dart';
import '../constants/drawing_palette.dart';

class PixelCanvas extends StatelessWidget {
  final int gridSize;
  final List<List<int>> pixels; // Thay đổi: int index thay vì String
  final int selectedColorIndex;  // Thay đổi: int index thay vì String
  final Function(int row, int col) onPixelPaint;

  const PixelCanvas({
    Key? key,
    required this.gridSize,
    required this.pixels,
    required this.selectedColorIndex,
    required this.onPixelPaint,
  }) : super(key: key);

  void _handlePaint(Offset position, Size size) {
    final cellWidth = size.width / gridSize;
    final cellHeight = size.height / gridSize;
    
    final col = (position.dx / cellWidth).floor();
    final row = (position.dy / cellHeight).floor();

    if (row >= 0 && row < gridSize && col >= 0 && col < gridSize) {
      onPixelPaint(row, col);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxWidth);
        
        return GestureDetector(
          onTapDown: (details) => _handlePaint(details.localPosition, size),
          onPanUpdate: (details) => _handlePaint(details.localPosition, size),
          child: CustomPaint(
            size: size,
            painter: _PixelCanvasPainter(
              pixels: pixels,
              gridSize: gridSize,
            ),
          ),
        );
      },
    );
  }
}

class _PixelCanvasPainter extends CustomPainter {
  final List<List<int>> pixels; // Thay đổi: int index
  final int gridSize;

  _PixelCanvasPainter({
    required this.pixels,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / gridSize;
    final cellHeight = size.height / gridSize;

    // Vẽ background trắng
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Vẽ pixels
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final colorIndex = pixels[row][col];
        if (colorIndex != DrawingPalette.emptyIndex) {
          final colorHex = DrawingPalette.getColorByIndex(colorIndex);
          if (colorHex.isNotEmpty) {
            final color = Color(DrawingPalette.hexToInt(colorHex));
            final paint = Paint()..color = color;
            canvas.drawRect(
              Rect.fromLTWH(
                col * cellWidth,
                row * cellHeight,
                cellWidth,
                cellHeight,
              ),
              paint,
            );
          }
        }
      }
    }

    // Vẽ grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= gridSize; i++) {
      // Vertical lines
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        gridPaint,
      );
      // Horizontal lines
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelCanvasPainter oldDelegate) {
    return oldDelegate.pixels != pixels;
  }
}