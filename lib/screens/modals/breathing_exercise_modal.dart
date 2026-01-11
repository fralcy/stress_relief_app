import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/breathing_exercise_service.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/utils/asset_loader.dart';
import '../../core/l10n/app_localizations.dart';
import '../../models/breathing_session.dart';
import '../../models/scene_models.dart';

/// Modal for breathing exercises
class BreathingExerciseModal extends StatefulWidget {
  const BreathingExerciseModal({super.key});

  @override
  State<BreathingExerciseModal> createState() =>
      _BreathingExerciseModalState();

  /// Helper to show modal
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.breathingExercise,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      content: const BreathingExerciseModal(),
    );
  }
}

class _BreathingExerciseModalState extends State<BreathingExerciseModal>
    with TickerProviderStateMixin {
  // State
  String? _selectedExercise;
  bool _isActive = false;
  int _elapsedSeconds = 0;
  int _cyclesCompleted = 0;
  Timer? _timer;

  // Animation controllers
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  final BreathingExerciseService _service = BreathingExerciseService();

  @override
  void initState() {
    super.initState();

    // Mascot scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedExercise == null) {
      return _buildExerciseSelection();
    }
    return _buildBreathingSession();
  }

  Widget _buildExerciseSelection() {
    final l10n = AppLocalizations.of(context);
    final exercises = [
      {
        'type': '4-7-8',
        'name': l10n.exercise478,
        'desc': l10n.exercise478Desc,
      },
      {
        'type': 'box',
        'name': l10n.exerciseBox,
        'desc': l10n.exerciseBoxDesc,
      },
      {
        'type': 'deep_belly',
        'name': l10n.exerciseDeepBelly,
        'desc': l10n.exerciseDeepBellyDesc,
      },
      {
        'type': 'calm',
        'name': l10n.exerciseCalm,
        'desc': l10n.exerciseCalmDesc,
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectExercise,
            style: AppTypography.h4(context),
          ),
          const SizedBox(height: 16),
          ...exercises.map((ex) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ExerciseCard(
                  name: ex['name']!,
                  description: ex['desc']!,
                  onTap: () {
                    setState(() => _selectedExercise = ex['type']);
                    SfxService().buttonClick();
                  },
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBreathingSession() {
    final l10n = AppLocalizations.of(context);
    final cycleDuration = _service.getCycleDuration(_selectedExercise!);
    final elapsedInCycle = _elapsedSeconds % cycleDuration;
    final phaseData = _service.getCurrentPhase(_selectedExercise!, elapsedInCycle);
    final phase = phaseData['phase'] as String;
    final progress = phaseData['progress'] as double;

    // Update mascot scale based on phase
    final targetScale = _service.getMascotScale(phase, progress);
    final normalizedTarget = (targetScale - 1.0) / 0.3; // 0.0-1.0
    if (_isActive && _scaleController.value != normalizedTarget) {
      _scaleController.animateTo(
        normalizedTarget,
        duration: const Duration(milliseconds: 500),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (_isActive) {
                  _stopSession();
                }
                setState(() => _selectedExercise = null);
              },
            ),
          ),

          const SizedBox(height: 8),

          // Timer and cycles
          Text(
            '${_elapsedSeconds ~/ 60}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}',
            style: AppTypography.h2(context),
          ),
          Text(
            '${l10n.cycles}: $_cyclesCompleted',
            style: AppTypography.bodyMedium(context),
          ),

          const SizedBox(height: 32),

          // Mascot with circular progress
          SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Circular progress
                CustomPaint(
                  size: const Size(300, 300),
                  painter: _CircularProgressPainter(
                    progress: progress,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                // Animated mascot
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Image.asset(
                    AssetLoader.getMascotAsset(MascotExpression.calm),
                    width: 200,
                    height: 200,
                  ),
                ),

                // Phase text
                if (_isActive)
                  Positioned(
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getPhaseText(phase, l10n),
                        style: AppTypography.bodyLarge(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppButton(
                label: _isActive ? l10n.stop : l10n.start,
                onPressed: _toggleSession,
              ),
              if (_isActive) ...[
                const SizedBox(width: 16),
                AppButton(
                  label: l10n.reset,
                  onPressed: _resetSession,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getPhaseText(String phase, AppLocalizations l10n) {
    switch (phase) {
      case 'inhale':
        return l10n.breatheIn;
      case 'hold':
        return l10n.hold;
      case 'exhale':
        return l10n.breatheOut;
      case 'pause':
        return l10n.pause;
      default:
        return '';
    }
  }

  void _toggleSession() {
    if (_isActive) {
      _stopSession();
    } else {
      _startSession();
    }
  }

  void _startSession() {
    setState(() => _isActive = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _elapsedSeconds++;

        // Check cycle completion
        final cycleDuration = _service.getCycleDuration(_selectedExercise!);
        if (_elapsedSeconds % cycleDuration == 0) {
          _cyclesCompleted++;
          SfxService().buttonClick();
        }
      });
    });
  }

  void _stopSession() {
    _timer?.cancel();
    setState(() => _isActive = false);

    // Save session if at least 30s
    if (_elapsedSeconds >= 30) {
      final session = BreathingSession(
        date: DateTime.now(),
        exerciseType: _selectedExercise!,
        durationSeconds: _elapsedSeconds,
        cyclesCompleted: _cyclesCompleted,
      );
      DataManager().addBreathingSession(session);
      SfxService().taskComplete();
    }
  }

  void _resetSession() {
    _stopSession();
    setState(() {
      _elapsedSeconds = 0;
      _cyclesCompleted = 0;
    });
    _scaleController.reset();
  }
}

/// Exercise card widget
class _ExerciseCard extends StatelessWidget {
  final String name;
  final String description;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.name,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: AppTypography.bodyLarge(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTypography.bodyMedium(context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for circular progress
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background circle
    final bgPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
