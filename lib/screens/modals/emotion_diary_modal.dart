import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/line_graph.dart';
import '../../core/l10n/app_localizations.dart';
import 'package:flutter_tutorial_overlay/flutter_tutorial_overlay.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/utils/auth_service.dart';
import '../../core/providers/score_provider.dart';
import '../../core/providers/achievement_provider.dart';
import '../../core/widgets/achievement_popup.dart';
import '../../models/index.dart';

/// Modal quản lý nhật ký cảm xúc
class EmotionDiaryModal extends StatefulWidget {
  const EmotionDiaryModal({super.key});

  @override
  State<EmotionDiaryModal> createState() => _EmotionDiaryModalState();

  /// Helper để show modal
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modalKey = GlobalKey<_EmotionDiaryModalState>();
    return AppModal.show(
      context: context,
      title: l10n.emotionDiary,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      onHelpPressed: () => modalKey.currentState?._showTutorial(),
      content: EmotionDiaryModal(key: modalKey),
    );
  }
}

class _EmotionDiaryModalState extends State<EmotionDiaryModal> {
  // 0 = today … 13 = 13 days ago (data index, matches sleep guide convention)
  int _selectedDayIndex = 0;

  final GlobalKey _historyKey = GlobalKey();
  final GlobalKey _questionsKey = GlobalKey();
  final GlobalKey _notesKey = GlobalKey();
  final GlobalKey _saveKey = GlobalKey();

  // Likert scale values (1-5, null = not selected)
  int? _overallFeeling;
  int? _stressLevel;
  int? _productivity;

  final TextEditingController _diaryController = TextEditingController();
  final int _maxDiaryLength = 400;

  // Debug mode state
  bool _isDebugMode = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadDiaryForSelectedDay();
    _checkDebugMode();

    // Listen to text changes for character counter
    _diaryController.addListener(() {
      setState(() {});
    });
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
    _diaryController.dispose();
    super.dispose();
  }

  // ==================== HELPERS ====================

  /// dataIdx 0 = today, dataIdx 13 = 13 days ago
  DateTime _getDateForIndex(int dataIdx) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: dataIdx));
  }

  bool _isToday(int dataIdx) => dataIdx == 0;

  bool _canEdit(int dataIdx) {
    if (_isDebugMode) return true;
    return _isToday(dataIdx);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Map<String, dynamic> _getDayData(int dataIdx) {
    final date = _getDateForIndex(dataIdx);
    final diaries = DataManager().emotionDiaries;
    final diary = diaries.where((d) => _isSameDay(d.date, date)).firstOrNull;
    return {
      'date': date,
      'hasData': diary != null,
      'avgScore': diary != null ? (diary.q1 + diary.q2 + diary.q3) / 3.0 : null,
    };
  }

  // Get emoji based on average likert score (1-5)
  String _getEmojiForScore(double? score) {
    if (score == null) return '';
    if (score <= 1.5) return '😢';
    if (score <= 2.5) return '😕';
    if (score <= 3.5) return '😐';
    if (score <= 4.5) return '🙂';
    return '😊';
  }

  // ==================== BUILD ====================

  void _showTutorial() {
    final l10n = AppLocalizations.of(context);
    TutorialOverlay(
      context: context,
      steps: [
        TutorialStep(targetKey: _historyKey, title: l10n.tutorialDiaryHistoryTitle, description: l10n.tutorialDiaryHistoryDesc, tag: 'diary_history'),
        TutorialStep(targetKey: _questionsKey, title: l10n.tutorialDiaryQuestionsTitle, description: l10n.tutorialDiaryQuestionsDesc, tag: 'diary_questions'),
        TutorialStep(targetKey: _notesKey, title: l10n.tutorialDiaryNotesTitle, description: l10n.tutorialDiaryNotesDesc, tag: 'diary_notes'),
        TutorialStep(targetKey: _saveKey, title: l10n.tutorialDiarySaveTitle, description: l10n.tutorialDiarySaveDesc, tag: 'diary_save'),
      ],
      nextText: l10n.tutorialNext,
      skipText: l10n.tutorialSkip,
      finshText: l10n.tutorialGotIt,
      onComplete: () => SfxService().buttonClick(),
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== HISTORY SECTION ==========
          KeyedSubtree(key: _historyKey, child: _buildHistorySection(l10n, theme)),

          const SizedBox(height: 24),
          Divider(color: theme.border, height: 1, thickness: 1.5),
          const SizedBox(height: 16),

          // ========== CHECK-IN SECTION ==========
          _buildCheckInSection(l10n, theme),
        ],
      ),
    );
  }

  // ==================== HISTORY SECTION ====================

  Widget _buildHistorySection(AppLocalizations l10n, AppTheme theme) {
    final labelStyle = AppTypography.bodySmall(context,
        color: theme.text.withOpacity(0.6));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.historyLast2Weeks,
          style: AppTypography.bodyLarge(context, color: theme.text)
              .copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Last week row (older, dimmed)
        Text(l10n.sleepLastWeek, style: labelStyle),
        const SizedBox(height: 4),
        Opacity(opacity: 0.6, child: _buildDayRow(13, theme)),
        const SizedBox(height: 8),

        // This week row (recent, full opacity)
        Text(l10n.sleepThisWeek, style: labelStyle),
        const SizedBox(height: 4),
        _buildDayRow(6, theme),

        const SizedBox(height: 16),
        _buildMoodGraph(l10n, theme),

        const SizedBox(height: 12),
        Text(
          l10n.tapDayToViewDetails,
          style: labelStyle,
        ),
      ],
    );
  }

  /// Builds a 7-cell row starting from [firstDataIdx] down to [firstDataIdx - 6].
  /// Leftmost = oldest, rightmost = newest.
  Widget _buildDayRow(int firstDataIdx, AppTheme theme) {
    return Row(
      children: List.generate(7, (i) => _buildDayCell(firstDataIdx - i, theme)),
    );
  }

  Widget _buildDayCell(int dataIdx, AppTheme theme) {
    final dayData = _getDayData(dataIdx);
    final date = dayData['date'] as DateTime;
    final hasData = dayData['hasData'] as bool;
    final avgScore = dayData['avgScore'] as double?;
    final isSelected = _selectedDayIndex == dataIdx;

    Color borderColor;
    if (isSelected) {
      borderColor = theme.secondary;
    } else if (hasData) {
      borderColor = theme.primary;
    } else {
      borderColor = theme.border;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: AspectRatio(
          aspectRatio: 1,
          child: InkWell(
            onTap: () {
              SfxService().buttonClick();
              setState(() {
                _selectedDayIndex = dataIdx;
                _loadDiaryForSelectedDay();
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.background,
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: AppTypography.bodyMedium(context,
                        color: theme.text, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getEmojiForScore(avgScore),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodGraph(AppLocalizations l10n, AppTheme theme) {
    final diaries = DataManager().emotionDiaries;
    final values = <double?>[];
    final labels = <String>[];

    // Oldest → newest (left to right), i=13 = 13 days ago, i=0 = today
    for (int i = 13; i >= 0; i--) {
      final date = _getDateForIndex(i);
      final diary =
          diaries.where((d) => _isSameDay(d.date, date)).firstOrNull;
      values.add(
          diary != null ? (diary.q1 + diary.q2 + diary.q3) / 3.0 : null);
      // Show label only on even positions to avoid overlap
      final j = 13 - i;
      labels.add(j.isEven ? '${date.day}/${date.month}' : '');
    }

    final hasAnyData = values.any((v) => v != null);

    if (!hasAnyData) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            l10n.noDiaryData,
            style: AppTypography.bodySmall(context,
                color: theme.text.withOpacity(0.6)),
          ),
        ),
      );
    }

    return LineGraph(
      values: values,
      labels: labels,
      minY: 1,
      maxY: 5,
      yUnit: '',
      highlightIndex: 13 - _selectedDayIndex,
    );
  }

  // ==================== CHECK-IN SECTION ====================

  Widget _buildCheckInSection(AppLocalizations l10n, AppTheme theme) {
    final isReadOnly = !_canEdit(_selectedDayIndex);
    final dayData = _getDayData(_selectedDayIndex);
    final date = dayData['date'] as DateTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========== TITLE ==========
        Text(
          isReadOnly
              ? (_isDebugMode
                  ? '${l10n.dailyJournal} [DEBUG: Edit Enabled]'
                  : l10n.dailyJournal)
              : l10n.todaysJournal,
          style: AppTypography.h4(context, color: theme.text),
        ),
        const SizedBox(height: 16),

        // ========== DATE SUBTITLE ==========
        Text(
          _formatDate(date, l10n),
          style: AppTypography.bodyMedium(context,
              color: theme.text, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        KeyedSubtree(
          key: _questionsKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question 1: Overall feeling
              _buildLikertQuestion(
                question: l10n.howDoYouFeelOverall,
                value: _overallFeeling,
                labels: [l10n.veryBad, l10n.bad, l10n.neutral, l10n.good, l10n.great],
                onChanged: isReadOnly
                    ? null
                    : (val) {
                        SfxService().buttonClick();
                        setState(() => _overallFeeling = val);
                      },
                theme: theme,
              ),
              const SizedBox(height: 20),
              // Question 2: Stress level
              _buildLikertQuestion(
                question: l10n.howWasYourStressLevel,
                value: _stressLevel,
                labels: [l10n.veryHigh, l10n.high, l10n.moderate, l10n.low, l10n.relaxed],
                onChanged: isReadOnly
                    ? null
                    : (val) {
                        SfxService().buttonClick();
                        setState(() => _stressLevel = val);
                      },
                theme: theme,
              ),
              const SizedBox(height: 20),
              // Question 3: Productivity
              _buildLikertQuestion(
                question: l10n.howProductiveWereYou,
                value: _productivity,
                labels: [l10n.none, l10n.little, l10n.average, l10n.good, l10n.very],
                onChanged: isReadOnly
                    ? null
                    : (val) {
                        SfxService().buttonClick();
                        setState(() => _productivity = val);
                      },
                theme: theme,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        KeyedSubtree(key: _notesKey, child: _buildDiaryTextArea(l10n, isReadOnly, theme)),

        if (!isReadOnly) ...[
          const SizedBox(height: 20),
          KeyedSubtree(key: _saveKey, child: _buildSaveButton(l10n, theme)),
        ],
      ],
    );
  }

  Widget _buildLikertQuestion({
    required String question,
    required int? value,
    required List<String> labels,
    required Function(int)? onChanged,
    required AppTheme theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: AppTypography.bodyMedium(context,
              color: theme.text, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        // 5 radio buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final optionValue = index + 1;
            return Expanded(
              child: Column(
                children: [
                  Radio<int>(
                    value: optionValue,
                    groupValue: value,
                    onChanged:
                        onChanged != null ? (val) => onChanged(val!) : null,
                    activeColor: theme.primary,
                  ),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: AppTypography.captionSmall(context,
                        color: theme.text.withOpacity(0.8)),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDiaryTextArea(
      AppLocalizations l10n, bool isReadOnly, AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _diaryController,
          readOnly: isReadOnly,
          maxLines: 10,
          minLines: 5,
          maxLength: _maxDiaryLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          decoration: InputDecoration(
            hintText: isReadOnly ? '' : l10n.writeYourThoughts,
            hintStyle: TextStyle(
              color: theme.border,
              fontWeight: FontWeight.normal,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.border, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.primary, width: 1.5),
            ),
            counterText: '',
          ),
        ),
        const SizedBox(height: 4),

        // Custom character counter (right aligned)
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_diaryController.text.length}/$_maxDiaryLength',
            style: AppTypography.bodySmall(context,
                color: theme.text.withOpacity(0.6)),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n, AppTheme theme) {
    final canSave = _overallFeeling != null &&
        _stressLevel != null &&
        _productivity != null;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final diaries = DataManager().emotionDiaries;
    final isFirstTimeToday =
        !diaries.any((d) => _isSameDay(d.date, todayDate));

    return Column(
      children: [
        Center(
          child: AppButton(
            label: l10n.save,
            onPressed: canSave ? _saveCheckIn : null,
            isDisabled: !canSave,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isFirstTimeToday ? l10n.saveToEarnPoints : l10n.alreadySavedToday,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall(context,
              color: isFirstTimeToday ? theme.primary : theme.border,
              fontWeight:
                  isFirstTimeToday ? FontWeight.w500 : FontWeight.normal),
        ),
      ],
    );
  }

  // ==================== SAVE ====================

  void _saveCheckIn() async {
    if (_diaryController.text.length > _maxDiaryLength) {
      _diaryController.text =
          _diaryController.text.substring(0, _maxDiaryLength);
    }

    final selectedDate = _getDateForIndex(_selectedDayIndex);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final isSavingToday = _isSameDay(selectedDate, todayDate);

    final diaries = DataManager().emotionDiaries;
    final existingIndex =
        diaries.indexWhere((d) => _isSameDay(d.date, selectedDate));
    final isFirstTimeForDate = existingIndex == -1;

    final newDiary = EmotionDiary(
      date: selectedDate,
      q1: _overallFeeling!,
      q2: _stressLevel!,
      q3: _productivity!,
      notes: _diaryController.text,
    );

    if (existingIndex != -1) {
      diaries[existingIndex] = newDiary;
    } else {
      diaries.add(newDiary);
    }

    diaries.sort((a, b) => b.date.compareTo(a.date));
    if (diaries.length > 14) diaries.removeRange(14, diaries.length);

    await DataManager().saveEmotionDiaries(diaries);

    if (isSavingToday && isFirstTimeForDate) {
      SfxService().reward();
      const diaryPoints = 20;
      await context.read<ScoreProvider>().addPoints(diaryPoints);
    } else {
      SfxService().buttonClick();
    }

    if (mounted && isFirstTimeForDate) {
      final score = context.read<ScoreProvider>();
      final newly =
          await context.read<AchievementProvider>().onDiaryAdded(score);
      if (newly.isNotEmpty && mounted) {
        AchievementPopup.show(context, newly);
      }
    }

    if (mounted) setState(() {});
  }

  // ==================== HELPERS ====================

  void _loadDiaryForSelectedDay() {
    final targetDate = _getDateForIndex(_selectedDayIndex);
    final diaries = DataManager().emotionDiaries;
    final diary =
        diaries.where((d) => _isSameDay(d.date, targetDate)).firstOrNull;

    setState(() {
      if (diary != null) {
        _overallFeeling = diary.q1;
        _stressLevel = diary.q2;
        _productivity = diary.q3;
        _diaryController.text = diary.notes;
      } else {
        _overallFeeling = null;
        _stressLevel = null;
        _productivity = null;
        _diaryController.text = '';
      }
    });
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'vi') {
      final months = [
        'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
        'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    }
  }
}
