import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A simple line graph widget using CustomPainter.
/// Displays a list of nullable values along an X-axis with optional labels.
/// Null values are rendered as gaps in the line.
class LineGraph extends StatelessWidget {
  /// Data points. Null means no data for that day (renders as gap).
  final List<double?> values;

  /// X-axis labels (e.g., day abbreviations).
  final List<String> labels;

  /// Maximum Y value. Defaults to the max of [values] + padding.
  final double? maxY;

  /// Minimum Y value. Defaults to 0.
  final double minY;

  /// Y-axis unit label shown on the right (e.g., 'h').
  final String yUnit;

  final double height;

  const LineGraph({
    super.key,
    required this.values,
    required this.labels,
    this.maxY,
    this.minY = 0,
    this.yUnit = '',
    this.height = 160,
  }) : assert(values.length == labels.length);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;

    final nonNull = values.whereType<double>().toList();
    final computedMax = maxY ??
        (nonNull.isNotEmpty ? (nonNull.reduce(math.max) * 1.2).ceilToDouble() : 10.0);
    final effectiveMax = math.max(computedMax, minY + 1.0);

    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _LineGraphPainter(
          values: values,
          labels: labels,
          minY: minY,
          maxY: effectiveMax,
          yUnit: yUnit,
          lineColor: color,
          textColor: textColor,
          gridColor: textColor.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

class _LineGraphPainter extends CustomPainter {
  final List<double?> values;
  final List<String> labels;
  final double minY;
  final double maxY;
  final String yUnit;
  final Color lineColor;
  final Color textColor;
  final Color gridColor;

  static const double _leftPadding = 32;
  static const double _rightPadding = 20;
  static const double _topPadding = 12;
  static const double _bottomPadding = 24;

  const _LineGraphPainter({
    required this.values,
    required this.labels,
    required this.minY,
    required this.maxY,
    required this.yUnit,
    required this.lineColor,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final graphWidth = size.width - _leftPadding - _rightPadding;
    final graphHeight = size.height - _topPadding - _bottomPadding;
    final n = values.length;
    if (n < 2 || graphWidth <= 0 || graphHeight <= 0) return;

    final xStep = graphWidth / (n - 1);

    // --- Helpers ---
    Offset toPoint(int i, double v) => Offset(
          _leftPadding + i * xStep,
          _topPadding + graphHeight * (1 - (v - minY) / (maxY - minY)),
        );

    // --- Grid lines (3 horizontal) ---
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const gridLines = 3;
    for (int g = 0; g <= gridLines; g++) {
      final y = _topPadding + graphHeight * g / gridLines;
      canvas.drawLine(
        Offset(_leftPadding, y),
        Offset(_leftPadding + graphWidth, y),
        gridPaint,
      );
      // Y-axis label
      final yVal = maxY - (maxY - minY) * g / gridLines;
      final label = yVal == yVal.roundToDouble()
          ? '${yVal.toInt()}$yUnit'
          : '${yVal.toStringAsFixed(1)}$yUnit';
      _drawText(canvas, label, Offset(0, y - 7), size: 9, color: textColor);
    }

    // --- Area fill ---
    final segments = _buildSegments(n);
    for (final seg in segments) {
      if (seg.length < 2) continue;
      final fillPath = Path();
      final first = toPoint(seg.first, values[seg.first]!);
      fillPath.moveTo(first.dx, _topPadding + graphHeight); // bottom-left
      fillPath.lineTo(first.dx, first.dy);
      for (int k = 1; k < seg.length; k++) {
        final pt = toPoint(seg[k], values[seg[k]]!);
        fillPath.lineTo(pt.dx, pt.dy);
      }
      final last = toPoint(seg.last, values[seg.last]!);
      fillPath.lineTo(last.dx, _topPadding + graphHeight); // bottom-right
      fillPath.close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lineColor.withValues(alpha: 0.25), lineColor.withValues(alpha: 0.0)],
          ).createShader(Rect.fromLTWH(
              _leftPadding, _topPadding, graphWidth, graphHeight)),
      );
    }

    // --- Line segments ---
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final seg in segments) {
      if (seg.length < 2) continue;
      final path = Path();
      path.moveTo(
          toPoint(seg.first, values[seg.first]!).dx,
          toPoint(seg.first, values[seg.first]!).dy);
      for (int k = 1; k < seg.length; k++) {
        final pt = toPoint(seg[k], values[seg[k]]!);
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // --- Data points ---
    for (int i = 0; i < n; i++) {
      if (values[i] == null) continue;
      final pt = toPoint(i, values[i]!);
      canvas.drawCircle(pt, 4, Paint()..color = lineColor);
      canvas.drawCircle(
          pt, 2.5, Paint()..color = Colors.white.withValues(alpha: 0.9));
    }

    // --- X-axis labels ---
    for (int i = 0; i < n; i++) {
      final x = _leftPadding + i * xStep;
      _drawText(
        canvas,
        labels[i],
        Offset(x - 10, size.height - _bottomPadding + 6),
        size: 9,
        color: textColor,
      );
    }
  }

  /// Groups consecutive non-null indices into segments.
  List<List<int>> _buildSegments(int n) {
    final segments = <List<int>>[];
    List<int>? current;
    for (int i = 0; i < n; i++) {
      if (values[i] != null) {
        current ??= [];
        current.add(i);
      } else if (current != null) {
        segments.add(current);
        current = null;
      }
    }
    if (current != null) segments.add(current);
    return segments;
  }

  void _drawText(Canvas canvas, String text, Offset offset,
      {double size = 10, required Color color}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: size, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_LineGraphPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.maxY != maxY ||
      oldDelegate.lineColor != lineColor;
}
