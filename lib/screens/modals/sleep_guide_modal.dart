import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/line_graph.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/sleep_guide_service.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/utils/asset_loader.dart';
import '../../core/utils/notifier.dart';
import '../../core/utils/auth_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import 'package:flutter_tutorial_overlay/flutter_tutorial_overlay.dart';
import '../../models/sleep_log.dart';
import '../../models/sleep_settings.dart';
import '../../models/scene_models.dart';
import 'package:provider/provider.dart';
import '../../core/providers/score_provider.dart';
import '../../core/providers/achievement_provider.dart';
import '../../core/widgets/achievement_popup.dart';
import '../../core/widgets/app_time_picker.dart';

/// Modal for sleep guide
class SleepGuideModal extends StatefulWidget {
  const SleepGuideModal({super.key});

  @override
  State<SleepGuideModal> createState() => _SleepGuideModalState();

  static Future<void> show(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (size.width >= 720 && size.width > size.height && size.height >= 600) {
      return _showLandscape(context);
    }
    final l10n = AppLocalizations.of(context);
    final modalKey = GlobalKey<_SleepGuideModalState>();
    return AppModal.show(
      context: context,
      title: l10n.sleepGuide,
      maxHeight: size.height * 0.92,
      onHelpPressed: () => modalKey.currentState?._showTutorial(),
      content: SleepGuideModal(key: modalKey),
    );
  }

  static Future<void> _showLandscape(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modalKey = GlobalKey<_SleepGuideModalState>();
    final size = MediaQuery.of(context).size;
    final dialogWidth = (size.width * 0.92).clamp(0.0, 1100.0);
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
            title: l10n.sleepGuide,
            scrollable: false,
            content: SleepGuideModal(key: modalKey),
            onHelpPressed: () => modalKey.currentState?._showTutorial(),
          ),
        ),
      ),
    );
  }
}

class _SleepGuideModalState extends State<SleepGuideModal> {
  final SleepGuideService _sleepService = SleepGuideService();

  final GlobalKey _tipKey = GlobalKey();
  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey _graphKey = GlobalKey();
  final GlobalKey _checkinKey = GlobalKey();

  // Debug mode
  bool _isDebugMode = false;
  final AuthService _authService = AuthService();

  // 0 = today … 13 = 13 days ago (data index)
  int _selectedDayIndex = 0;
  int? _logBedtimeMinutes;
  int? _logWakeTimeMinutes;
  int? _logQuality;
  bool _showDurationGraph = true;
  int _currentTipIndex = 0;
  int _mascotTipIndex = 0;
  Timer? _reminderTimer;

  static const _qualityEmojis = ['😩', '😕', '😐', '🙂', '😊'];

  @override
  void initState() {
    super.initState();
    _loadLogForSelectedDay();
    _mascotTipIndex = Random().nextInt(10);
    _reminderTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
    _checkDebugMode();
  }

  Future<void> _checkDebugMode() async {
    final isDebug = await _authService.isDebugMode;
    if (mounted) {
      setState(() {
        _isDebugMode = isDebug;
      });
    }
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  // ==================== HELPERS ====================

  /// Expression for the mascot tip card — awake variants far from bedtime,
  /// sleepy when approaching/at bedtime, calm when well past it.
  MascotExpression _tipMascotExpression(SleepSettings settings) {
    if (settings.bedtimeMinutes == null) return MascotExpression.idle;
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final diff = settings.bedtimeMinutes! - currentMinutes;
    final normalizedDiff = diff < -720 ? diff + 1440 : diff;
    if (normalizedDiff > 60) return MascotExpression.happy;
    return MascotExpression.sleepy;
  }

  /// Returns a randomly-selected tip from the pool appropriate for the
  /// current time relative to bedtime.
  String _getMascotTip(AppLocalizations l10n, SleepSettings settings) {
    if (settings.bedtimeMinutes == null) return l10n.sleepTipSetBedtime;
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final diff = settings.bedtimeMinutes! - currentMinutes;
    final normalizedDiff = diff < -720 ? diff + 1440 : diff;

    if (normalizedDiff > 60) {
      final pool = [l10n.sleepTipEarly, l10n.sleepTipEarly2, l10n.sleepTipEarly3, l10n.sleepTipEarly4];
      return pool[_mascotTipIndex % pool.length];
    } else if (normalizedDiff > 0) {
      final pool = [l10n.sleepTipWindDown, l10n.sleepTipWindDown2, l10n.sleepTipWindDown3];
      return pool[_mascotTipIndex % pool.length];
    } else if (normalizedDiff > -60) {
      return l10n.sleepTipLate;
    } else {
      return l10n.sleepTipVeryLate;
    }
  }

  DateTime _dateFor(int index) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: index));
  }

  /// Only today (0) and yesterday (1) are editable (all days in debug mode)
  bool _canEdit(int dataIdx) => _isDebugMode || dataIdx <= 1;

  SleepLog? _logFor(int dataIdx) {
    final target = _dateFor(dataIdx);
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

  SleepLog? get _currentLog => _logFor(_selectedDayIndex);

  void _loadLogForSelectedDay() {
    final log = _currentLog;
    _logBedtimeMinutes = log?.bedtimeMinutes ?? 22 * 60; // default 22:00
    _logWakeTimeMinutes = log?.wakeTimeMinutes ?? 7 * 60; // default 07:00
    _logQuality = log?.quality;
  }

  int? get _logDurationMinutes {
    if (_logBedtimeMinutes == null || _logWakeTimeMinutes == null) return null;
    final diff = _logWakeTimeMinutes! - _logBedtimeMinutes!;
    return diff < 0 ? diff + 1440 : diff;
  }

  String _qualityEmoji(int? quality) {
    if (quality == null) return '';
    return _qualityEmojis[(quality - 1).clamp(0, 4)];
  }

  // ==================== SAVE ====================

  void _saveLog() async {
    final date = _dateFor(_selectedDayIndex);
    final newLog = SleepLog(
      date: date,
      bedtimeMinutes: _logBedtimeMinutes,
      wakeTimeMinutes: _logWakeTimeMinutes,
      quality: _logQuality,
    );

    final logs = DataManager().sleepLogs.toList();
    final idx = logs.indexWhere((l) =>
        l.date.year == date.year &&
        l.date.month == date.month &&
        l.date.day == date.day);
    final isNew = idx < 0;

    if (idx >= 0) {
      logs[idx] = newLog;
    } else {
      logs.add(newLog);
    }

    logs.sort((a, b) => b.date.compareTo(a.date));
    if (logs.length > 30) logs.removeRange(30, logs.length);

    await DataManager().saveSleepLogs(logs);
    if (!mounted) return;
    SfxService().taskComplete();
    if (isNew) _triggerSleepAchievement(_logQuality ?? 3);

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.sleepLogSaved),
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {});
  }

  Future<void> _triggerSleepAchievement(int quality) async {
    if (!mounted) return;
    final score = context.read<ScoreProvider>();
    final newly =
        await context.read<AchievementProvider>().onSleepLogAdded(quality, score);
    if (newly.isNotEmpty && mounted) {
      AchievementPopup.show(context, newly);
    }
  }

  // ==================== TUTORIAL ====================

  void _showTutorial() {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;
    TutorialOverlay(
      context: context,
      steps: [
        TutorialStep(
          targetKey: _tipKey,
          title: l10n.tutorialSleepTipTitle,
          description: l10n.tutorialSleepTipDesc,
          tag: 'sleep_tip',
        ),
        TutorialStep(
          targetKey: _gridKey,
          title: l10n.tutorialSleepGridTitle,
          description: l10n.tutorialSleepGridDesc,
          tag: 'sleep_grid',
        ),
        TutorialStep(
          targetKey: _graphKey,
          title: l10n.tutorialSleepGraphTitle,
          description: l10n.tutorialSleepGraphDesc,
          tag: 'sleep_graph',
        ),
        TutorialStep(
          targetKey: _checkinKey,
          title: l10n.tutorialSleepCheckinTitle,
          description: l10n.tutorialSleepCheckinDesc,
          tag: 'sleep_checkin',
        ),
      ],
      nextText: l10n.tutorialNext,
      skipText: l10n.tutorialSkip,
      finshText: l10n.tutorialGotIt,
      onComplete: () => SfxService().buttonClick(),
      tooltipBackgroundColor: theme.background,
      titleTextColor: theme.text,
      descriptionTextColor: theme.text,
      nextButtonStyle: ElevatedButton.styleFrom(
        backgroundColor: theme.primary,
        foregroundColor: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      skipButtonStyle: TextButton.styleFrom(
        foregroundColor: theme.text,
      ),
      finishButtonStyle: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: theme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
    ).show();
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth >= 560;
        return isLandscape ? _buildLandscape(context) : _buildPortrait(context);
      },
    );
  }

  Widget _buildMascotTip(AppLocalizations l10n, SleepSettings sleepSettings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Image.asset(
            AssetLoader.getMascotAsset(_tipMascotExpression(sleepSettings)),
            width: 80,
            height: 80,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getMascotTip(l10n, sleepSettings),
              style: AppTypography.bodyMedium(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortrait(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sleepSettings = DataManager().sleepSettings;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeyedSubtree(
            key: _tipKey,
            child: _buildMascotTip(l10n, sleepSettings),
          ),

          const SizedBox(height: 12),
          _buildSleepTipsCard(l10n),
          const SizedBox(height: 24),

          Text(l10n.sleepLog, style: AppTypography.h4(context)),
          const SizedBox(height: 4),
          Text(
            l10n.tapDayToLogSleep,
            style: AppTypography.bodySmall(context).copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          KeyedSubtree(key: _gridKey, child: _buildDayGrid()),
          const SizedBox(height: 16),
          KeyedSubtree(key: _graphKey, child: _buildSleepGraph(l10n)),
          const SizedBox(height: 16),
          KeyedSubtree(key: _checkinKey, child: _buildCheckInForm(l10n)),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          Text(l10n.sleepSchedule, style: AppTypography.h4(context)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: AppTimePicker(
                  label: l10n.bedtime,
                  time: sleepSettings.bedtimeMinutes != null
                      ? _sleepService
                          .minutesToTimeOfDay(sleepSettings.bedtimeMinutes!)
                      : const TimeOfDay(hour: 22, minute: 0),
                  onChanged: (time) {
                    final updated = sleepSettings.copyWith(
                        bedtimeMinutes:
                            _sleepService.timeOfDayToMinutes(time));
                    DataManager().saveSleepSettings(updated);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppTimePicker(
                  label: l10n.wakeTime,
                  time: sleepSettings.wakeTimeMinutes != null
                      ? _sleepService
                          .minutesToTimeOfDay(sleepSettings.wakeTimeMinutes!)
                      : const TimeOfDay(hour: 7, minute: 0),
                  onChanged: (time) {
                    final updated = sleepSettings.copyWith(
                        wakeTimeMinutes:
                            _sleepService.timeOfDayToMinutes(time));
                    DataManager().saveSleepSettings(updated);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildReminderRow(l10n),
        ],
      ),
    );
  }

  Widget _buildLandscape(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sleepSettings = DataManager().sleepSettings;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left: tip + tips card + day grid + graph
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyedSubtree(
                  key: _tipKey,
                  child: _buildMascotTip(l10n, sleepSettings),
                ),
                const SizedBox(height: 12),
                _buildSleepTipsCard(l10n),
                const SizedBox(height: 24),
                Text(l10n.sleepLog, style: AppTypography.h4(context)),
                const SizedBox(height: 4),
                Text(
                  l10n.tapDayToLogSleep,
                  style: AppTypography.bodySmall(context).copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                KeyedSubtree(key: _gridKey, child: _buildDayGrid()),
                const SizedBox(height: 16),
                KeyedSubtree(key: _graphKey, child: _buildSleepGraph(l10n)),
              ],
            ),
          ),
        ),

        VerticalDivider(
            width: 1, thickness: 1, color: theme.colorScheme.outline),

        // Right: check-in form + schedule & reminder
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyedSubtree(
                    key: _checkinKey, child: _buildCheckInForm(l10n)),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(l10n.sleepSchedule, style: AppTypography.h4(context)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTimePicker(
                        label: l10n.bedtime,
                        time: sleepSettings.bedtimeMinutes != null
                            ? _sleepService.minutesToTimeOfDay(
                                sleepSettings.bedtimeMinutes!)
                            : const TimeOfDay(hour: 22, minute: 0),
                        onChanged: (time) {
                          final updated = sleepSettings.copyWith(
                              bedtimeMinutes:
                                  _sleepService.timeOfDayToMinutes(time));
                          DataManager().saveSleepSettings(updated);
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTimePicker(
                        label: l10n.wakeTime,
                        time: sleepSettings.wakeTimeMinutes != null
                            ? _sleepService.minutesToTimeOfDay(
                                sleepSettings.wakeTimeMinutes!)
                            : const TimeOfDay(hour: 7, minute: 0),
                        onChanged: (time) {
                          final updated = sleepSettings.copyWith(
                              wakeTimeMinutes:
                                  _sleepService.timeOfDayToMinutes(time));
                          DataManager().saveSleepSettings(updated);
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildReminderRow(l10n),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== DAY GRID ====================

  Widget _buildDayGrid() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final labelStyle = AppTypography.bodySmall(context).copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.sleepLastWeek, style: labelStyle),
        const SizedBox(height: 4),
        Opacity(opacity: 0.6, child: _buildDayRow(13, applyEditOpacity: false)),
        const SizedBox(height: 8),
        Text(l10n.sleepThisWeek, style: labelStyle),
        const SizedBox(height: 4),
        _buildDayRow(6, applyEditOpacity: true),
      ],
    );
  }

  /// Builds a 7-cell row starting from [firstDataIdx] down to [firstDataIdx - 6].
  /// Leftmost cell = oldest day, rightmost = newest.
  Widget _buildDayRow(int firstDataIdx, {required bool applyEditOpacity}) {
    final theme = Theme.of(context);
    return Row(
      children: List.generate(7, (i) {
        final dataIdx = firstDataIdx - i;
        final date = _dateFor(dataIdx);
        final log = _logFor(dataIdx);
        final hasLog = log != null;
        final isSelected = dataIdx == _selectedDayIndex;
        final canEdit = _canEdit(dataIdx);

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
            child: AspectRatio(
              aspectRatio: 1,
              child: Opacity(
                opacity: applyEditOpacity ? (canEdit ? 1.0 : 0.65) : 1.0,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex = dataIdx;
                      _loadLogForSelectedDay();
                    });
                    SfxService().buttonClick();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(
                          color: borderColor, width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: AppTypography.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasLog ? _qualityEmoji(log.quality) : '',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ==================== GRAPH ====================

  Widget _buildSleepGraph(AppLocalizations l10n) {
    final logs = DataManager().sleepLogs;
    final durationValues = <double?>[];
    final qualityValues = <double?>[];
    final labels = <String>[];

    // Oldest → newest (left to right), i=13 = 13 days ago, i=0 = today
    for (int i = 13; i >= 0; i--) {
      final date = _dateFor(i);
      final log = logs.cast<SleepLog?>().firstWhere(
            (l) =>
                l != null &&
                l.date.year == date.year &&
                l.date.month == date.month &&
                l.date.day == date.day,
            orElse: () => null,
          );
      durationValues.add(log?.durationHours);
      qualityValues.add(log?.quality?.toDouble());
      // Show label only on even positions to avoid overlap (7 visible out of 14)
      final idx = 13 - i; // array position 0..13
      labels.add(idx.isEven ? '${date.day}/${date.month}' : '');
    }

    final hasAnyLog = durationValues.any((v) => v != null) ||
        qualityValues.any((v) => v != null);

    final graphValues = _showDurationGraph ? durationValues : qualityValues;
    final graphMaxY = _showDurationGraph ? 12.0 : 5.0;
    final graphUnit = _showDurationGraph ? l10n.hoursUnit : '';

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.sleepHistory, style: AppTypography.bodyMedium(context)),
        const SizedBox(height: 8),
        if (hasAnyLog)
          LineGraph(
            values: graphValues,
            labels: labels,
            minY: 0,
            maxY: graphMaxY,
            yUnit: graphUnit,
            highlightIndex: 13 - _selectedDayIndex,
          )
        else
          SizedBox(
            height: 80,
            child: Center(
              child: Text(
                l10n.noSleepData,
                style: AppTypography.bodySmall(context).copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGraphTabButton(
              label: l10n.sleepDuration,
              selected: _showDurationGraph,
              onTap: () => setState(() => _showDurationGraph = true),
            ),
            const SizedBox(width: 8),
            _buildGraphTabButton(
              label: l10n.sleepQuality,
              selected: !_showDurationGraph,
              onTap: () => setState(() => _showDurationGraph = false),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== CHECK-IN FORM ====================

  Widget _buildCheckInForm(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final selectedDate = _dateFor(_selectedDayIndex);
    final isToday = _selectedDayIndex == 0;
    final dateStr =
        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    final canEdit = _canEdit(_selectedDayIndex);

    String durationStr = '--';
    final dur = _logDurationMinutes;
    if (dur != null) {
      final h = dur ~/ 60;
      final m = dur % 60;
      durationStr = m > 0 ? '${h}h ${m}m' : '${h}h';
    }

    final canSave = canEdit && _logQuality != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: date + duration badge + lock icon for read-only
        Row(
          children: [
            Text(
              isToday ? l10n.todaysJournal : dateStr,
              style: AppTypography.bodyLarge(context)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            if (!canEdit && !_isDebugMode) ...[
              const SizedBox(width: 6),
              Icon(Icons.lock_outline,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
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

        // Bedtime + Wake time
        Row(
          children: [
            Expanded(
              child: AppTimePicker(
                label: l10n.actualBedtime,
                time: _logBedtimeMinutes != null
                    ? _sleepService.minutesToTimeOfDay(_logBedtimeMinutes!)
                    : const TimeOfDay(hour: 22, minute: 0),
                onChanged: canEdit
                    ? (t) => setState(() {
                          _logBedtimeMinutes =
                              _sleepService.timeOfDayToMinutes(t);
                        })
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTimePicker(
                label: l10n.actualWakeTime,
                time: _logWakeTimeMinutes != null
                    ? _sleepService.minutesToTimeOfDay(_logWakeTimeMinutes!)
                    : const TimeOfDay(hour: 7, minute: 0),
                onChanged: canEdit
                    ? (t) => setState(() {
                          _logWakeTimeMinutes =
                              _sleepService.timeOfDayToMinutes(t);
                        })
                    : null,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Sleep quality
        Text(l10n.sleepQuality, style: AppTypography.bodyMedium(context)),
        const SizedBox(height: 8),
        _buildQualityRow(theme, isReadOnly: !canEdit),

        if (canEdit) ...[
          const SizedBox(height: 16),
          Center(
            child: AppButton(
              label: l10n.save,
              onPressed: canSave ? _saveLog : null,
              isDisabled: !canSave,
            ),
          ),
          if (_logQuality == null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.selectQualityToSave,
                style: AppTypography.bodySmall(context).copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildQualityRow(ThemeData theme, {required bool isReadOnly}) {
    return Opacity(
      opacity: isReadOnly ? 0.5 : 1.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (i) {
          final score = i + 1;
          final isSelected = _logQuality == score;
          return GestureDetector(
            onTap: isReadOnly
                ? null
                : () {
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
                  _qualityEmojis[i],
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ==================== SLEEP TIPS CARD ====================

  Widget _buildSleepTipsCard(AppLocalizations l10n) {
    final tips = [
      l10n.sleepTip1, l10n.sleepTip2, l10n.sleepTip3, l10n.sleepTip4,
      l10n.sleepTip5, l10n.sleepTip6, l10n.sleepTip7, l10n.sleepTip8,
      l10n.sleepTip9, l10n.sleepTip10,
    ];
    final tip = tips[_currentTipIndex % tips.length];
    return AppCard(
      title: l10n.sleepTipsCardTitle,
      isExpandable: true,
      initiallyExpanded: false,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sleepTipsLead,
            style: AppTypography.bodySmall(context).copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(tip, style: AppTypography.bodyMedium(context)),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _currentTipIndex = (_currentTipIndex + 1) % tips.length;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SCHEDULE & REMINDER ====================

  Widget _buildReminderRow(AppLocalizations l10n) {
    final userSettings = DataManager().userSettings;
    final sleepSettings = DataManager().sleepSettings;
    final bedtimeMinutes = sleepSettings.bedtimeMinutes ?? 1320;
    final bh = bedtimeMinutes ~/ 60;
    final bm = bedtimeMinutes % 60;
    final bedtimeStr =
        '${bh.toString().padLeft(2, '0')}:${bm.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.sleepReminder,
                    style: AppTypography.bodyMedium(context)),
                if (userSettings.sleepReminderEnabled)
                  Text(
                    bedtimeStr,
                    style: AppTypography.bodySmall(context).copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
            Switch(
              value: userSettings.sleepReminderEnabled,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (val) async {
                if (val) {
                  final permitted = await Notifier.requestPermissions();
                  if (!mounted) return;
                  if (!permitted) {
                    SfxService().error();
                    return;
                  }
                }
                // Sync reminder time to bedtime from sleep schedule
                final updated = userSettings.copyWith(
                  sleepReminderEnabled: val,
                  sleepReminderTimeMinutes: bedtimeMinutes,
                );
                await DataManager().saveUserSettings(updated);
                if (!mounted) return;
                if (val) {
                  await Notifier.scheduleSleepReminder(updated);
                } else {
                  await Notifier.cancelSleepReminder();
                }
                setState(() {});
              },
            ),
          ],
        ),
        if (_isDebugMode) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              await Notifier.debugScheduleSleepNotification();
              SfxService().buttonClick();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('[DEBUG] Sleep notification sent immediately!'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.deepPurple,
                  ),
                );
              }
            },
            icon: const Icon(Icons.bug_report, size: 18),
            label: const Text('[DEBUG] Test Sleep Notification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  // ==================== SHARED WIDGET ====================

  // ==================== GRAPH TAB BUTTON ====================

  Widget _buildGraphTabButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall(context).copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ==================== SHARED WIDGET ====================
}
