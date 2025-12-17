import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/utils/auth_service.dart';
import '../../core/providers/score_provider.dart';
import '../../models/index.dart';

/// Modal quản lý nhật ký cảm xúc
class EmotionDiaryModal extends StatefulWidget {
  const EmotionDiaryModal({super.key});

  @override
  State<EmotionDiaryModal> createState() => _EmotionDiaryModalState();

  /// Helper để show modal
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.emotionDiary,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      content: const EmotionDiaryModal(),
    );
  }
}

class _EmotionDiaryModalState extends State<EmotionDiaryModal> {
  int? _selectedDayIndex; // null = today (index 14)
  
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
    _selectedDayIndex = 14; // Default to today
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

  // Get emoji based on average likert score (1-5)
  String _getEmojiForScore(double? score) {
    if (score == null) return '';
    if (score <= 1.5) return '😢';
    if (score <= 2.5) return '😕';
    if (score <= 3.5) return '😐';
    if (score <= 4.5) return '🙂';
    return '😊';
  }

  // Get history data for the last 15 days
  List<Map<String, dynamic>> _getHistory() {
    final diaries = DataManager().emotionDiaries;
    
    return List.generate(15, (index) {
      final date = _getDateForIndex(index);
      final diary = diaries.where((d) => _isSameDay(d.date, date)).firstOrNull;
      
      return {
        'date': date,
        'hasData': diary != null,
        'avgScore': diary != null ? (diary.q1 + diary.q2 + diary.q3) / 3.0 : null,
      };
    });
  }

  bool _isToday(int index) => index == 14;

  bool _canEdit(int index) {
    // Debug mode: cho phép edit mọi ngày trong 15-day history
    if (_isDebugMode) return true;

    // Production: chỉ cho phép edit today
    return _isToday(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final history = _getHistory();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== HISTORY SECTION ==========
          _buildHistorySection(history, theme),

          const SizedBox(height: 24),
          Divider(color: theme.border, height: 1, thickness: 1.5),
          const SizedBox(height: 16),

          // ========== CHECK-IN SECTION ==========
          _buildCheckInSection(l10n, theme),
        ],
      ),
    );
  }

  Widget _buildHistorySection(List<Map<String, dynamic>> history, AppTheme theme) {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.historyLast2Weeks,
          style: AppTypography.bodyLarge(context, color: theme.text).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // 5x3 Grid of day buttons
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: 15,
          itemBuilder: (context, index) {
            return _buildDayButton(history[index], index, theme);
          },
        ),
        
        const SizedBox(height: 12),
        Text(
          l10n.tapDayToViewDetails,
          style: AppTypography.bodySmall(context,
            color: theme.text.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDayButton(Map<String, dynamic> dayData, int index, AppTheme theme) {
    final date = dayData['date'] as DateTime;
    final hasData = dayData['hasData'] as bool;
    final avgScore = dayData['avgScore'] as double?;
    final isSelected = _selectedDayIndex == index;
    
    // Determine border color
    Color borderColor;
    if (isSelected) {
      borderColor = theme.secondary;
    } else if (hasData) {
      borderColor = theme.primary;
    } else {
      borderColor = theme.border;
    }

    return InkWell(
      onTap: () {
        SfxService().buttonClick();
        setState(() {
          _selectedDayIndex = index;
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
                color: theme.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getEmojiForScore(avgScore),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInSection(AppLocalizations l10n, AppTheme theme) {
    final isReadOnly = !_canEdit(_selectedDayIndex ?? 14);
    
    // Lấy history để hiển thị date subtitle
    final history = _getHistory();
    final dayData = history[_selectedDayIndex ?? 14];
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
          style: AppTypography.h4(context,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 16),
        
        // ========== DATE SUBTITLE ==========
        Text(
          _formatDate(date, l10n),
          style: AppTypography.bodyMedium(context,
            color: theme.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Question 1: Overall feeling
        _buildLikertQuestion(
          question: l10n.howDoYouFeelOverall,
          value: _overallFeeling,
          labels: [
            l10n.veryBad,
            l10n.bad,
            l10n.neutral,
            l10n.good,
            l10n.great,
          ],
          onChanged: isReadOnly ? null : (val) {
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
          labels: [
            l10n.veryHigh,
            l10n.high,
            l10n.moderate,
            l10n.low,
            l10n.relaxed,
          ],
          onChanged: isReadOnly ? null : (val) {
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
          labels: [
            l10n.none,
            l10n.little,
            l10n.average,
            l10n.good,
            l10n.very,
          ],
          onChanged: isReadOnly ? null : (val) {
            SfxService().buttonClick();
            setState(() => _productivity = val);
          },
          theme: theme,
        ),
        
        const SizedBox(height: 20),
        
        // Diary text area
        _buildDiaryTextArea(l10n, isReadOnly, theme),
        
        if (!isReadOnly) ...[
          const SizedBox(height: 20),
          _buildSaveButton(l10n, theme),
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
            color: theme.text,
            fontWeight: FontWeight.w600,
          ),
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
                    onChanged: onChanged != null ? (val) => onChanged(val!) : null,
                    activeColor: theme.primary,
                  ),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: AppTypography.captionSmall(context,
                      color: theme.text.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDiaryTextArea(AppLocalizations l10n, bool isReadOnly, AppTheme theme) {
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
            counterText: '', // Hide default counter
          ),
        ),
        const SizedBox(height: 4),
        
        // Custom character counter (right aligned)
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_diaryController.text.length}/$_maxDiaryLength',
            style: AppTypography.bodySmall(context,
              color: theme.text.withOpacity(0.6),
            ),
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
    final isFirstTimeToday = !diaries.any((d) => _isSameDay(d.date, todayDate));

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
        
        // Helper text
        Text(
          isFirstTimeToday
            ? l10n.saveToEarnPoints
            : l10n.alreadySavedToday,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall(context,
            color: isFirstTimeToday ? theme.primary : theme.border,
            fontWeight: isFirstTimeToday ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _saveCheckIn() async {
  // Validate notes length
  if (_diaryController.text.length > _maxDiaryLength) {
    _diaryController.text = _diaryController.text.substring(0, _maxDiaryLength);
  }

    // Get the selected date (not always today!)
    final selectedDate = _getDateForIndex(_selectedDayIndex ?? 14);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final isSavingToday = _isSameDay(selectedDate, todayDate);

    final diaries = DataManager().emotionDiaries;
    final existingIndex = diaries.indexWhere((d) => _isSameDay(d.date, selectedDate));
    final isFirstTimeForDate = existingIndex == -1;

    final newDiary = EmotionDiary(
      date: selectedDate, // Save to selected date, not always today
      q1: _overallFeeling!,
      q2: _stressLevel!,
      q3: _productivity!,
      notes: _diaryController.text,
    );

    // Update or add diary
    if (existingIndex != -1) {
      diaries[existingIndex] = newDiary;
    } else {
      diaries.add(newDiary);
    }

    // Sort by date (newest first) and keep only last 15 days
    diaries.sort((a, b) => b.date.compareTo(a.date));
    if (diaries.length > 15) {
      diaries.removeRange(15, diaries.length);
    }

    // Save to data manager
    await DataManager().saveEmotionDiaries(diaries);

    // Award points ONLY if first time saving to TODAY (not past dates)
    if (isSavingToday && isFirstTimeForDate) {
      SfxService().reward(); // Play reward sound for first time
      const diaryPoints = 20;
      await context.read<ScoreProvider>().addPoints(diaryPoints);
    } else {
      SfxService().buttonClick(); // Regular save sound
    }

    if (mounted) {
      setState(() {}); // Force rebuild to update save button state


    }
  }

  // Helper để format date theo locale
  String _formatDate(DateTime date, AppLocalizations l10n) {
    // Kiểm tra locale hiện tại
    final locale = Localizations.localeOf(context);
    
    if (locale.languageCode == 'vi') {
      // Tiếng Việt: "15 Tháng 10, 2025"
      final months = [
        'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
        'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    } else {
      // Tiếng Anh: "15 Oct, 2025"
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    }
  }

  // Load diary data for selected day
  void _loadDiaryForSelectedDay() {
    if (_selectedDayIndex == null) return;
    
    final targetDate = _getDateForIndex(_selectedDayIndex!);
    final diaries = DataManager().emotionDiaries;
    
    final diary = diaries.where((d) => _isSameDay(d.date, targetDate)).firstOrNull;
    
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

  // Get date for history index (0 = 14 days ago, 14 = today)
  DateTime _getDateForIndex(int index) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: 14 - index));
  }

  // Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}