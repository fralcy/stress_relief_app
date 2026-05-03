import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/breathing_exercise_service.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/mascot_sprite_widget.dart';
import '../../models/breathing_session.dart';
import '../../models/scene_models.dart';
import 'package:provider/provider.dart';
import '../../core/providers/score_provider.dart';
import '../../core/providers/achievement_provider.dart';
import '../../core/widgets/achievement_popup.dart';
import '../../core/widgets/speech_bubble.dart';

/// Modal for breathing exercises
class BreathingExerciseModal extends StatefulWidget {
  const BreathingExerciseModal({super.key});

  @override
  State<BreathingExerciseModal> createState() =>
      _BreathingExerciseModalState();

  /// Helper to show modal
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    if (size.width >= 720 && size.width > size.height && size.height >= 600) {
      return _showLandscape(context);
    }
    final h = size.height * 0.92;
    return AppModal.show(
      context: context,
      title: l10n.breathingExercise,
      maxHeight: h,
      minHeight: h,
      content: const BreathingExerciseModal(),
    );
  }

  static Future<void> _showLandscape(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width.clamp(0.0, 640.0);
    final dialogHeight = size.height * 0.92;
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: AppModal(
            isDialog: true,
            title: l10n.breathingExercise,
            content: const BreathingExerciseModal(),
          ),
        ),
      ),
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

  // Current phase state (updated by timer, used by build)
  String _currentPhase = 'inhale';
  double _currentProgress = 0.0;

  // Breathing sprite animation
  int _breathingFrame = 0;
  Timer? _breathingFrameTimer;
  String _lastBreathingPhase = '';

  // Speech bubble
  String? _cycleMessage;
  Timer? _bubbleTimer;
  final _rng = math.Random();

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
    _bubbleTimer?.cancel();
    _breathingFrameTimer?.cancel();
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
    final exercises = <Map<String, dynamic>>[
      {'type': '4-7-8',       'name': l10n.exercise478,        'desc': l10n.exercise478Desc,        'icon': Icons.bedtime},
      {'type': 'box',         'name': l10n.exerciseBox,         'desc': l10n.exerciseBoxDesc,        'icon': Icons.crop_square},
      {'type': 'deep_belly',  'name': l10n.exerciseDeepBelly,  'desc': l10n.exerciseDeepBellyDesc,  'icon': Icons.self_improvement},
      {'type': 'calm',        'name': l10n.exerciseCalm,        'desc': l10n.exerciseCalmDesc,       'icon': Icons.spa},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.selectExercise, style: AppTypography.h4(context)),
        const SizedBox(height: 16),
        ...exercises.map((ex) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ExerciseCard(
                name: ex['name'] as String,
                description: ex['desc'] as String,
                icon: ex['icon'] as IconData,
                onTap: () {
                  setState(() => _selectedExercise = ex['type'] as String);
                  SfxService().buttonClick();
                },
              ),
            )),
      ],
    );
  }

  Widget _buildBreathingSession() {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        // Back button + centered exercise title
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (_isActive) _stopSession();
                setState(() => _selectedExercise = null);
              },
            ),
            Expanded(
              child: Text(
                _getExerciseName(l10n),
                textAlign: TextAlign.center,
                style: AppTypography.h4(context),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),

        const SizedBox(height: 4),

        // Timer and cycles
        Text(
          '${_elapsedSeconds ~/ 60}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}',
          style: AppTypography.h2(context),
        ),
        Text(
          '${l10n.cycles}: $_cyclesCompleted',
          style: AppTypography.bodyMedium(context),
        ),

        const SizedBox(height: 16),

        // Responsive circle + mascot
        LayoutBuilder(
          builder: (context, constraints) {
            final circleSize = math.min(constraints.maxWidth * 0.75, 220.0);
            final mascotSize = circleSize * 0.67;
            final mascotAreaHeight = mascotSize * 1.3;

            return Column(
              children: [
                // Circular progress
                SizedBox(
                  width: circleSize,
                  height: circleSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(circleSize, circleSize),
                        painter: _CircularProgressPainter(
                          progress: _currentProgress,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (_isActive)
                        Positioned(
                          top: circleSize * 0.07,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getPhaseText(_currentPhase, l10n),
                              style: AppTypography.bodyLarge(context).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Mascot area with speech bubble overlay
                SizedBox(
                  height: mascotAreaHeight,
                  child: Stack(
                    children: [
                      // Mascot — bottom-aligned, expands upward
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            alignment: Alignment.bottomCenter,
                            child: MascotSpriteWidget(
                              expression: MascotExpression.calm,
                              size: mascotSize,
                              frameIndex: _breathingFrame,
                            ),
                          ),
                        ),
                      ),
                      // Speech bubble — top-centered, mũi tên chỉ xuống linh vật
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedOpacity(
                          opacity: _cycleMessage != null ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Center(
                            child: SpeechBubble(
                              text: _cycleMessage ?? '',
                              tailPosition: BubbleTailPosition.bottom,
                              maxWidth: 200,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 8),

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
    );
  }

  List<String> _getPraiseMessages() {
    final l10n = AppLocalizations.of(context);
    return [
      l10n.breathingPraise1,
      l10n.breathingPraise2,
      l10n.breathingPraise3,
      l10n.breathingPraise4,
    ];
  }

  String _getExerciseName(AppLocalizations l10n) {
    switch (_selectedExercise) {
      case '4-7-8':
        return l10n.exercise478;
      case 'box':
        return l10n.exerciseBox;
      case 'deep_belly':
        return l10n.exerciseDeepBelly;
      case 'calm':
        return l10n.exerciseCalm;
      default:
        return '';
    }
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
    // Always reset to start fresh from inhale
    _bubbleTimer?.cancel();
    setState(() {
      _isActive = true;
      _elapsedSeconds = 0;
      _cyclesCompleted = 0;
      _currentPhase = 'inhale';
      _currentProgress = 0.0;
      _cycleMessage = null;
    });
    _scaleController.reset();
    _breathingFrameTimer?.cancel();
    _breathingFrameTimer = null;
    _breathingFrame = 0;
    _lastBreathingPhase = '';
    _updatePhaseAndAnimation();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      bool cycleJustCompleted = false;

      setState(() {
        _elapsedSeconds++;

        // Check cycle completion
        final cycleDuration = _service.getCycleDuration(_selectedExercise!);
        if (_elapsedSeconds % cycleDuration == 0) {
          _cyclesCompleted++;
          cycleJustCompleted = true;
          final msgs = _getPraiseMessages();
          _cycleMessage = msgs[_rng.nextInt(msgs.length)];
        }

        // Update phase and animation
        _updatePhaseAndAnimation();
      });

      // Side effects outside setState
      if (cycleJustCompleted) {
        SfxService().buttonClick();
        _bubbleTimer?.cancel();
        _bubbleTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _cycleMessage = null);
        });
      }
    });
  }

  /// Cycling frame theo phase: inhale loop f0↔f1, hold=f2, exhale loop f2↔f3, pause=f0.
  void _updateBreathingFrame(String phase) {
    if (phase == _lastBreathingPhase) return;
    _lastBreathingPhase = phase;
    _breathingFrameTimer?.cancel();
    _breathingFrameTimer = null;
    switch (phase) {
      case 'inhale':
        _breathingFrame = 0;
        _breathingFrameTimer = Timer.periodic(
          const Duration(milliseconds: 500), // 2fps
          (_) {
            if (mounted) setState(() => _breathingFrame = _breathingFrame == 0 ? 1 : 0);
          },
        );
      case 'hold':
        _breathingFrame = 2;
      case 'exhale':
        _breathingFrame = 2;
        _breathingFrameTimer = Timer.periodic(
          const Duration(milliseconds: 500),
          (_) {
            if (mounted) setState(() => _breathingFrame = _breathingFrame == 2 ? 3 : 2);
          },
        );
      default: // pause
        _breathingFrame = 0;
    }
  }

  /// Updates current phase, progress, and mascot animation
  /// Called from timer callback instead of build() for better performance
  void _updatePhaseAndAnimation() {
    if (_selectedExercise == null) return;

    final cycleDuration = _service.getCycleDuration(_selectedExercise!);
    final elapsedInCycle = _elapsedSeconds % cycleDuration;
    final phaseData = _service.getCurrentPhase(_selectedExercise!, elapsedInCycle);

    _currentPhase = phaseData['phase'] as String;
    _currentProgress = phaseData['progress'] as double;

    // Update mascot scale animation
    final targetScale = _service.getMascotScale(_currentPhase, _currentProgress);
    final normalizedTarget = (targetScale - 1.0) / 0.3; // 0.0-1.0

    if (_scaleController.value != normalizedTarget) {
      _scaleController.animateTo(
        normalizedTarget,
        duration: const Duration(milliseconds: 500),
      );
    }
    _updateBreathingFrame(_currentPhase);
  }

  Future<void> _stopSession() async {
    _timer?.cancel();
    _breathingFrameTimer?.cancel();
    _breathingFrameTimer = null;
    _lastBreathingPhase = '';
    if (!mounted) return;
    setState(() {
      _isActive = false;
      _breathingFrame = 0;
    });

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

      // Achievement trigger
      if (mounted) {
        final score = context.read<ScoreProvider>();
        final newly = await context
            .read<AchievementProvider>()
            .onBreathingSessionCompleted(_selectedExercise!, score);
        if (newly.isNotEmpty && mounted) {
          AchievementPopup.show(context, newly);
        }
      }
    }
  }

  void _resetSession() {
    _stopSession();
    setState(() {
      _elapsedSeconds = 0;
      _cyclesCompleted = 0;
      _currentPhase = 'inhale';
      _currentProgress = 0.0;
    });
    _scaleController.reset();
  }
}

/// Exercise card widget
class _ExerciseCard extends StatelessWidget {
  final String name;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.onPrimary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: AppTypography.bodySmall(context).copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: theme.colorScheme.primary),
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
      ..color = color.withValues(alpha: 0.2)
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
