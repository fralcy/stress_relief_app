import 'package:flutter/material.dart';
import '../constants/drawing_palette.dart';

class PixelCanvas extends StatelessWidget {
  final int gridSize;
  final List<List<int>> pixels; // Thay đổi: int index thay vì String
  final int selectedColorIndex;  // Thay đổi: int index thay vì String
  final Function(int row, int col) onPixelPaint;
  final int zoomLevel; // 1, 2, 4
  final double panX;   // -1 to 1 for zoom 2, -3 to 3 for zoom 4
  final double panY;   // -1 to 1 for zoom 2, -3 to 3 for zoom 4

  const PixelCanvas({
    Key? key,
    required this.gridSize,
    required this.pixels,
    required this.selectedColorIndex,
    required this.onPixelPaint,
    this.zoomLevel = 1,
    this.panX = 0,
    this.panY = 0,
  }) : super(key: key);

  void _handlePaint(Offset position, Size size) {
    // Tính toán grid hiển thị dựa trên zoom level
    final displayGridSize = gridSize ~/ zoomLevel;
    final cellWidth = size.width / displayGridSize;
    final cellHeight = size.height / displayGridSize;
    
    final col = (position.dx / cellWidth).floor();
    final row = (position.dy / cellHeight).floor();

    if (row >= 0 && row < displayGridSize && col >= 0 && col < displayGridSize) {
      // Tính toán offset dựa trên pan và zoom
      final gridOffset = (gridSize - displayGridSize) ~/ 2;
      final panOffsetX = (panX * displayGridSize / 2).round();
      final panOffsetY = (panY * displayGridSize / 2).round();
      
      final actualRow = row + gridOffset + panOffsetY;
      final actualCol = col + gridOffset + panOffsetX;
      
      if (actualRow >= 0 && actualRow < gridSize && actualCol >= 0 && actualCol < gridSize) {
        onPixelPaint(actualRow, actualCol);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Drawing canvas, zoom level $zoomLevel',
      hint: 'Tap or drag to paint pixels',
      child: LayoutBuilder(
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
                zoomLevel: zoomLevel,
                panX: panX,
                panY: panY,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PixelCanvasPainter extends CustomPainter {
  final List<List<int>> pixels; // Thay đổi: int index
  final int gridSize;
  final int zoomLevel;
  final double panX;
  final double panY;

  _PixelCanvasPainter({
    required this.pixels,
    required this.gridSize,
    required this.zoomLevel,
    required this.panX,
    required this.panY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Tính toán grid hiển thị dựa trên zoom level
    final displayGridSize = gridSize ~/ zoomLevel;
    final cellWidth = size.width / displayGridSize;
    final cellHeight = size.height / displayGridSize;

    // Vẽ background trắng
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Tính toán offset cho pan
    final gridOffset = (gridSize - displayGridSize) ~/ 2;
    final panOffsetX = (panX * displayGridSize / 2).round();
    final panOffsetY = (panY * displayGridSize / 2).round();
    
    final startRow = gridOffset + panOffsetY;
    final startCol = gridOffset + panOffsetX;

    // Vẽ pixels trong khu vực hiển thị
    for (int displayRow = 0; displayRow < displayGridSize; displayRow++) {
      for (int displayCol = 0; displayCol < displayGridSize; displayCol++) {
        final actualRow = startRow + displayRow;
        final actualCol = startCol + displayCol;
        
        if (actualRow >= 0 && actualRow < gridSize && actualCol >= 0 && actualCol < gridSize) {
          final colorIndex = pixels[actualRow][actualCol];
          if (colorIndex != DrawingPalette.emptyIndex) {
            final colorHex = DrawingPalette.getColorByIndex(colorIndex);
            if (colorHex.isNotEmpty) {
              final color = Color(DrawingPalette.hexToInt(colorHex));
              final paint = Paint()..color = color;
              canvas.drawRect(
                Rect.fromLTWH(
                  displayCol * cellWidth,
                  displayRow * cellHeight,
                  cellWidth,
                  cellHeight,
                ),
                paint,
              );
            }
          }
        }
      }
    }

    // Vẽ grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= displayGridSize; i++) {
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
    return oldDelegate.pixels != pixels ||
           oldDelegate.zoomLevel != zoomLevel ||
           oldDelegate.panX != panX ||
           oldDelegate.panY != panY;
  }
}