import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/line_graph.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/sleep_guide_service.dart';
import '../../core/utils/bgm_service.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/utils/asset_loader.dart';
import '../../core/l10n/app_localizations.dart';
import '../../models/sleep_session.dart';
import '../../models/sleep_log.dart';
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

  // Sleep log state
  int _selectedDayIndex = 0; // 0 = today, 1 = yesterday, …, 6 = 6 days ago
  int? _logBedtimeMinutes;
  int? _logWakeTimeMinutes;
  int? _logQuality;
  final TextEditingController _logNotesController = TextEditingController();

  // Timer state
  int _timerMinutes = 30;
  bool _isTimerActive = false;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _fadingStarted = false;
  bool _timerCompletedNaturally = false;

  @override
  void initState() {
    super.initState();
    final settings = DataManager().sleepSettings;
    _timerMinutes = settings.defaultTimerMinutes;
    _loadLogForSelectedDay();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    // Cancel any in-progress fade and save session if timer was active
    if (_isTimerActive) {
      if (_fadingStarted && !_timerCompletedNaturally) {
        _bgmService.cancelFade();
      }
      final currentBgm = DataManager().userSettings.bgm;
      DataManager().addSleepSession(SleepSession(
        startTime: DateTime.now(),
        bgmTrack: currentBgm,
        timerDurationMinutes: _timerMinutes,
        completed: false,
      ));
    }
    _logNotesController.dispose();
    super.dispose();
  }

  // ==================== SLEEP LOG HELPERS ====================

  /// Date for a given day index (0 = today, 1 = yesterday …)
  DateTime _dateFor(int index) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: index));
  }

  /// Find existing log for the selected day
  SleepLog? get _currentLog {
    final target = _dateFor(_selectedDayIndex);
    final logs = DataManager().sleepLogs;
    try {
      return logs.firstWhere((l) =>
          l.date.year == target.year &&
          l.date.month == target.month &&
          l.date.day == target.day);
    } catch (_) {
      return null;
    }
  }

  void _loadLogForSelectedDay() {
    final log = _currentLog;
    _logBedtimeMinutes = log?.bedtimeMinutes;
    _logWakeTimeMinutes = log?.wakeTimeMinutes;
    _logQuality = log?.quality;
    _logNotesController.text = log?.notes ?? '';
  }

  int? get _logDurationMinutes {
    if (_logBedtimeMinutes == null || _logWakeTimeMinutes == null) return null;
    final diff = _logWakeTimeMinutes! - _logBedtimeMinutes!;
    return diff < 0 ? diff + 1440 : diff;
  }

  void _saveLog() {
    final date = _dateFor(_selectedDayIndex);
    final newLog = SleepLog(
      date: date,
      bedtimeMinutes: _logBedtimeMinutes,
      wakeTimeMinutes: _logWakeTimeMinutes,
      quality: _logQuality,
      notes: _logNotesController.text.trim(),
    );

    final logs = DataManager().sleepLogs.toList();
    final idx = logs.indexWhere((l) =>
        l.date.year == date.year &&
        l.date.month == date.month &&
        l.date.day == date.day);

    if (idx >= 0) {
      logs[idx] = newLog;
    } else {
      logs.add(newLog);
    }

    // Keep only last 30 days
    logs.sort((a, b) => b.date.compareTo(a.date));
    if (logs.length > 30) logs.removeRange(30, logs.length);

    DataManager().saveSleepLogs(logs);
    SfxService().taskComplete();

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.sleepLogSaved),
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {});
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = DataManager().sleepSettings;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mascot tip
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

          // ── Sleep Log Section ──
          Text(l10n.sleepLog, style: AppTypography.h4(context)),
          const SizedBox(height: 4),
          Text(
            l10n.tapDayToLogSleep,
            style: AppTypography.bodySmall(context).copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          _buildDayGrid(l10n),
          const SizedBox(height: 16),
          _buildSleepGraph(l10n),
          const SizedBox(height: 16),
          _buildCheckInForm(l10n),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // ── Sleep Schedule ──
          Text(l10n.sleepSchedule, style: AppTypography.h4(context)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildTimePickerTile(
                  label: l10n.bedtime,
                  time: settings.bedtimeMinutes != null
                      ? _sleepService.minutesToTimeOfDay(settings.bedtimeMinutes!)
                      : const TimeOfDay(hour: 22, minute: 0),
                  onChanged: (time) {
                    final updated = settings.copyWith(
                        bedtimeMinutes: _sleepService.timeOfDayToMinutes(time));
                    DataManager().saveSleepSettings(updated);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimePickerTile(
                  label: l10n.wakeTime,
                  time: settings.wakeTimeMinutes != null
                      ? _sleepService.minutesToTimeOfDay(settings.wakeTimeMinutes!)
                      : const TimeOfDay(hour: 7, minute: 0),
                  onChanged: (time) {
                    final updated = settings.copyWith(
                        wakeTimeMinutes: _sleepService.timeOfDayToMinutes(time));
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

          // ── Sleep Timer ──
          Text(l10n.sleepTimer, style: AppTypography.h4(context)),
          const SizedBox(height: 12),

          if (!_isTimerActive) ...[
            Text(l10n.timerDuration, style: AppTypography.bodyMedium(context)),
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
                Text('$_timerMinutes min', style: AppTypography.h3(context)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _timerMinutes < 120
                      ? () => setState(() => _timerMinutes += 5)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: AppButton(
                label: l10n.startTimer,
                onPressed: _startSleepTimer,
              ),
            ),
          ] else ...[
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

          // ── Breathing CTA ──
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
                    style: AppTypography.bodyLarge(context)
                        .copyWith(fontWeight: FontWeight.bold),
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

  // ==================== SLEEP LOG WIDGETS ====================

  Widget _buildDayGrid(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final logs = DataManager().sleepLogs;

    return Row(
      children: List.generate(7, (i) {
        final date = _dateFor(i);
        final hasLog = logs.any((l) =>
            l.date.year == date.year &&
            l.date.month == date.month &&
            l.date.day == date.day);
        final isSelected = i == _selectedDayIndex;

        Color borderColor;
        Color bgColor;
        if (isSelected) {
          borderColor = theme.colorScheme.secondary;
          bgColor = theme.colorScheme.secondaryContainer;
        } else if (hasLog) {
          borderColor = theme.colorScheme.primary;
          bgColor = theme.colorScheme.primaryContainer;
        } else {
          borderColor = theme.colorScheme.outlineVariant;
          bgColor = Colors.transparent;
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedDayIndex = i;
                  _loadLogForSelectedDay();
                });
                SfxService().buttonClick();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _dayLabel(date, l10n),
                      style: AppTypography.bodySmall(context).copyWith(
                        fontSize: 9,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${date.day}',
                      style: AppTypography.bodyMedium(context).copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (hasLog)
                      Icon(Icons.bedtime,
                          size: 10, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSleepGraph(AppLocalizations l10n) {
    final logs = DataManager().sleepLogs;
    final values = <double?>[];
    final labels = <String>[];

    // Build 7-day series (oldest → newest = left → right)
    for (int i = 6; i >= 0; i--) {
      final date = _dateFor(i);
      final log = logs.cast<SleepLog?>().firstWhere(
            (l) =>
                l != null &&
                l.date.year == date.year &&
                l.date.month == date.month &&
                l.date.day == date.day,
            orElse: () => null,
          );
      values.add(log?.durationHours);
      labels.add('${date.day}/${date.month}');
    }

    final hasAny = values.any((v) => v != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.sleepHistory, style: AppTypography.bodyMedium(context)),
            const Spacer(),
            Text(
              l10n.sleepDuration,
              style: AppTypography.bodySmall(context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (hasAny)
          LineGraph(
            values: values,
            labels: labels,
            minY: 0,
            maxY: 12,
            yUnit: l10n.hoursUnit,
          )
        else
          SizedBox(
            height: 80,
            child: Center(
              child: Text(
                l10n.noSleepData,
                style: AppTypography.bodySmall(context).copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckInForm(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final selectedDate = _dateFor(_selectedDayIndex);
    final isToday = _selectedDayIndex == 0;
    final dateStr = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';

    // Computed duration string
    String durationStr = '--';
    final dur = _logDurationMinutes;
    if (dur != null) {
      final h = dur ~/ 60;
      final m = dur % 60;
      durationStr = m > 0 ? '${h}h ${m}m' : '${h}h';
    }

    final canSave =
        _logBedtimeMinutes != null || _logWakeTimeMinutes != null || _logQuality != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: date + duration badge
        Row(
          children: [
            Text(
              isToday ? l10n.todaysJournal : dateStr,
              style: AppTypography.bodyLarge(context)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (dur != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  durationStr,
                  style: AppTypography.bodySmall(context).copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Bedtime + Wake time pickers
        Row(
          children: [
            Expanded(
              child: _buildTimePickerTile(
                label: l10n.actualBedtime,
                time: _logBedtimeMinutes != null
                    ? _sleepService.minutesToTimeOfDay(_logBedtimeMinutes!)
                    : const TimeOfDay(hour: 22, minute: 0),
                onChanged: (t) => setState(() {
                  _logBedtimeMinutes = _sleepService.timeOfDayToMinutes(t);
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimePickerTile(
                label: l10n.actualWakeTime,
                time: _logWakeTimeMinutes != null
                    ? _sleepService.minutesToTimeOfDay(_logWakeTimeMinutes!)
                    : const TimeOfDay(hour: 7, minute: 0),
                onChanged: (t) => setState(() {
                  _logWakeTimeMinutes = _sleepService.timeOfDayToMinutes(t);
                }),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Sleep quality
        Text(l10n.sleepQuality, style: AppTypography.bodyMedium(context)),
        const SizedBox(height: 8),
        _buildQualityRow(theme),

        const SizedBox(height: 16),

        // Notes
        TextField(
          controller: _logNotesController,
          maxLines: 2,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: l10n.writeYourThoughts,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: AppTypography.bodyMedium(context),
        ),

        const SizedBox(height: 16),

        // Save button
        Center(
          child: AppButton(
            label: l10n.save,
            onPressed: canSave ? _saveLog : null,
          ),
        ),
      ],
    );
  }

  Widget _buildQualityRow(ThemeData theme) {
    const qualities = ['😴', '😕', '😐', '🙂', '😊'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (i) {
        final score = i + 1;
        final isSelected = _logQuality == score;
        return GestureDetector(
          onTap: () {
            setState(() => _logQuality = score);
            SfxService().buttonClick();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
            ),
            child: Center(
              child: Text(
                qualities[i],
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ==================== SHARED WIDGET ====================

  Widget _buildTimePickerTile({
    required String label,
    required TimeOfDay time,
    required Function(TimeOfDay) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall(context)),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  style: AppTypography.labelMedium(context)
                      .copyWith(fontWeight: FontWeight.w600),
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

  // ==================== SLEEP TIMER LOGIC ====================

  void _startSleepTimer() {
    final settings = DataManager().sleepSettings;
    if (settings.defaultTimerMinutes != _timerMinutes) {
      DataManager().saveSleepSettings(
        settings.copyWith(defaultTimerMinutes: _timerMinutes),
      );
    }

    setState(() {
      _isTimerActive = true;
      _remainingSeconds = _timerMinutes * 60;
      _fadingStarted = false;
      _timerCompletedNaturally = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds == 120 && !_fadingStarted) {
        _fadingStarted = true;
        _bgmService.fadeOutAndStop(const Duration(minutes: 2));
      }

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _timerCompletedNaturally = true;
        _stopSleepTimer();
        SfxService().taskComplete();
        return;
      }

      setState(() => _remainingSeconds--);
    });
  }

  void _stopSleepTimer() {
    _countdownTimer?.cancel();

    if (_fadingStarted && !_timerCompletedNaturally) {
      _bgmService.cancelFade();
    }

    final currentBgm = DataManager().userSettings.bgm;
    DataManager().addSleepSession(SleepSession(
      startTime: DateTime.now(),
      bgmTrack: currentBgm,
      timerDurationMinutes: _timerMinutes,
      completed: _timerCompletedNaturally,
    ));

    setState(() {
      _isTimerActive = false;
      _fadingStarted = false;
      _timerCompletedNaturally = false;
    });
  }

  // ==================== HELPERS ====================

  String _dayLabel(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (diff == 0) return l10n.todaysJournal.substring(0, 2).toUpperCase();
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return days[date.weekday - 1];
  }

  String _formatTimeRemaining(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m ${secs}s';
    return '${minutes}m ${secs}s';
  }
}
