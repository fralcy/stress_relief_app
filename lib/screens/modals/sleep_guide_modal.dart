import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/sleep_guide_service.dart';
import '../../core/utils/bgm_service.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/utils/asset_loader.dart';
import '../../core/l10n/app_localizations.dart';
import '../../models/sleep_session.dart';
import '../../models/scene_models.dart';
import 'breathing_exercise_modal.dart';

/// Modal for sleep guide
class SleepGuideModal extends StatefulWidget {
  const SleepGuideModal({super.key});

  @override
  State<SleepGuideModal> createState() => _SleepGuideModalState();

  /// Helper to show modal
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.sleepGuide,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      content: const SleepGuideModal(),
    );
  }
}

class _SleepGuideModalState extends State<SleepGuideModal> {
  final SleepGuideService _sleepService = SleepGuideService();
  final BgmService _bgmService = BgmService();

  // Timer state
  int _timerMinutes = 30;
  bool _isTimerActive = false;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _fadingStarted = false;

  @override
  void initState() {
    super.initState();
    final settings = DataManager().sleepSettings;
    _timerMinutes = settings.defaultTimerMinutes;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = DataManager().sleepSettings;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mascot tip section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Image.asset(
                  AssetLoader.getMascotAsset(MascotExpression.sleepy),
                  width: 80,
                  height: 80,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _sleepService.getSleepTip(l10n, settings),
                    style: AppTypography.bodyMedium(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sleep schedule settings
          Text(l10n.sleepSchedule, style: AppTypography.h4(context)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildTimePickerSection(
                  label: l10n.bedtime,
                  time: settings.bedtimeMinutes != null
                      ? _sleepService.minutesToTimeOfDay(settings.bedtimeMinutes!)
                      : const TimeOfDay(hour: 22, minute: 0),
                  onChanged: (time) {
                    final minutes = _sleepService.timeOfDayToMinutes(time);
                    final updated = settings.copyWith(bedtimeMinutes: minutes);
                    DataManager().saveSleepSettings(updated);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimePickerSection(
                  label: l10n.wakeTime,
                  time: settings.wakeTimeMinutes != null
                      ? _sleepService.minutesToTimeOfDay(settings.wakeTimeMinutes!)
                      : const TimeOfDay(hour: 7, minute: 0),
                  onChanged: (time) {
                    final minutes = _sleepService.timeOfDayToMinutes(time);
                    final updated = settings.copyWith(wakeTimeMinutes: minutes);
                    DataManager().saveSleepSettings(updated);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Sleep timer section
          Text(l10n.sleepTimer, style: AppTypography.h4(context)),
          const SizedBox(height: 12),

          if (!_isTimerActive) ...[
            // Timer duration picker
            Text(
              l10n.timerDuration,
              style: AppTypography.bodyMedium(context),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _timerMinutes > 5
                      ? () => setState(() => _timerMinutes -= 5)
                      : null,
                ),
                Text(
                  '$_timerMinutes min',
                  style: AppTypography.h3(context),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _timerMinutes < 120
                      ? () => setState(() => _timerMinutes += 5)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Start button
            Center(
              child: AppButton(
                label: l10n.startTimer,
                onPressed: _startSleepTimer,
              ),
            ),
          ] else ...[
            // Active timer display
            Center(
              child: Column(
                children: [
                  Text(
                    _formatTimeRemaining(_remainingSeconds),
                    style: AppTypography.h1(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.musicWillFadeOut,
                    style: AppTypography.bodySmall(context),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: l10n.stopTimer,
                    onPressed: _stopSleepTimer,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Breathing exercise CTA (if suggested)
          if (_sleepService.shouldSuggestBreathing(settings)) ...[
            const Divider(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.troubleSleeping,
                    style: AppTypography.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tryBreathingExercise,
                    style: AppTypography.bodyMedium(context),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: l10n.goToBreathing,
                    onPressed: () {
                      Navigator.pop(context);
                      BreathingExerciseModal.show(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePickerSection({
    required String label,
    required TimeOfDay time,
    required Function(TimeOfDay) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall(context),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) {
              onChanged(picked);
              SfxService().buttonClick();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  time.format(context),
                  style: AppTypography.labelMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _startSleepTimer() {
    setState(() {
      _isTimerActive = true;
      _remainingSeconds = _timerMinutes * 60;
      _fadingStarted = false;
    });

    // Save session
    final currentBgm = DataManager().userSettings.bgm;
    final session = SleepSession(
      startTime: DateTime.now(),
      bgmTrack: currentBgm,
      timerDurationMinutes: _timerMinutes,
      completed: false,
    );
    DataManager().addSleepSession(session);

    // Start countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;

        // Start fade-out in last 2 minutes
        if (_remainingSeconds == 120 && !_fadingStarted) {
          _fadingStarted = true;
          _bgmService.fadeOutAndStop(const Duration(minutes: 2));
        }

        // Timer complete
        if (_remainingSeconds <= 0) {
          _stopSleepTimer();
          SfxService().taskComplete();
        }
      });
    });
  }

  void _stopSleepTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _isTimerActive = false;
      _fadingStarted = false;
    });
  }

  String _formatTimeRemaining(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    }
    return '${minutes}m ${secs}s';
  }
}
