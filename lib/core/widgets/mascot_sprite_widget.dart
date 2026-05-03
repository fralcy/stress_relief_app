import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import '../../models/scene_models.dart';

class MascotSpriteWidget extends StatefulWidget {
  const MascotSpriteWidget({
    super.key,
    required this.expression,
    required this.size,
    this.fps,
    this.frameIndex,
  });

  final MascotExpression expression;
  final double size;

  /// Tốc độ khung hình (frames/giây). null = dùng mặc định theo expression.
  /// Mặc định: sleepy = 2fps, các trạng thái khác = 10fps.
  final int? fps;

  /// Khi khác null, widget hiển thị frame này và không chạy timer nội bộ.
  /// Dùng để điều khiển animation từ bên ngoài (ví dụ: breathing exercise).
  final int? frameIndex;

  @override
  State<MascotSpriteWidget> createState() => _MascotSpriteWidgetState();
}

class _MascotSpriteWidgetState extends State<MascotSpriteWidget> {
  static final _random = Random();

  int _frameIndex = 0;
  int _completedLoops = 0;
  int? _targetLoopCount;
  Timer? _timer;

  List<String> get _frames =>
      AppAssets.mascotFrames[widget.expression] ??
      [AppAssets.mascotAssets[widget.expression]!];

  int get _effectiveFps =>
      widget.fps ??
      switch (widget.expression) {
        MascotExpression.sleepy => 2,
        _ => 4,
      };

  // null = loop vô tận
  static int? _loopCountFor(MascotExpression e) => switch (e) {
        MascotExpression.idle || MascotExpression.happy =>
          _random.nextInt(2) + 1, // 1-2 loops @ 4fps ≈ 1-2s
        _ => null,
      };

  void _startAnimation() {
    _timer?.cancel();
    _timer = null;
    _frameIndex = 0;
    _completedLoops = 0;
    _targetLoopCount = _loopCountFor(widget.expression);
    if (widget.frameIndex != null) return; // điều khiển từ ngoài, không cần timer
    if (_frames.length <= 1) return;
    final interval = Duration(milliseconds: (1000 / _effectiveFps).round());
    _timer = Timer.periodic(interval, (_) {
      if (!mounted) return;
      setState(() {
        _frameIndex = (_frameIndex + 1) % _frames.length;
        if (_frameIndex == 0) {
          _completedLoops++;
          if (_targetLoopCount != null && _completedLoops >= _targetLoopCount!) {
            _timer?.cancel();
            _timer = null;
          }
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void didUpdateWidget(MascotSpriteWidget old) {
    super.didUpdateWidget(old);
    if (old.expression != widget.expression || old.fps != widget.fps) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frameIdx = widget.frameIndex != null
        ? widget.frameIndex!.clamp(0, _frames.length - 1)
        : _frameIndex;
    return Image.asset(
      _frames[frameIdx],
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, _, e) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text('🐱', style: TextStyle(fontSize: widget.size / 2)),
      ),
    );
  }
}
