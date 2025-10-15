import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/l10n/app_localizations.dart';

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
  final int _maxDiaryLength = 200;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = 14; // Default to today
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

  // Mock data for history (replace with real data later)
  List<Map<String, dynamic>> _getMockHistory() {
    final now = DateTime.now();
    return List.generate(15, (index) {
      final date = now.subtract(Duration(days: 14 - index));
      final hasData = index < 10; // Mock: only last 10 days have data
      
      return {
        'date': date,
        'hasData': hasData,
        'avgScore': hasData ? 2.0 + (index % 5) * 0.6 : null,
      };
    });
  }

  bool _isToday(int index) => index == 14;
  
  bool _canEdit(int index) => _isToday(index);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final history = _getMockHistory();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========== HISTORY SECTION ==========
        _buildHistorySection(history),
        
        const SizedBox(height: 24),
        const Divider(color: AppColors.border, height: 1, thickness: 1.5),
        const SizedBox(height: 16),
        
        // ========== CHECK-IN SECTION ==========
        _buildCheckInSection(l10n),
      ],
    );
  }

  Widget _buildHistorySection(List<Map<String, dynamic>> history) {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.historyLast2Weeks,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
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
            return _buildDayButton(history[index], index);
          },
        ),
        
        const SizedBox(height: 12),
        Text(
          l10n.tapDayToViewDetails,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.text.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDayButton(Map<String, dynamic> dayData, int index) {
    final date = dayData['date'] as DateTime;
    final hasData = dayData['hasData'] as bool;
    final avgScore = dayData['avgScore'] as double?;
    final isSelected = _selectedDayIndex == index;
    
    // Determine border color
    Color borderColor;
    if (isSelected) {
      borderColor = AppColors.secondary;
    } else if (hasData) {
      borderColor = AppColors.primary;
    } else {
      borderColor = AppColors.border;
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDayIndex = index;
          // TODO: Load data for selected day
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
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

  Widget _buildCheckInSection(AppLocalizations l10n) {
    final isReadOnly = !_canEdit(_selectedDayIndex ?? 14);
    
    // Lấy history để hiển thị date subtitle
    final history = _getMockHistory();
    final dayData = history[_selectedDayIndex ?? 14];
    final date = dayData['date'] as DateTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========== TITLE ==========
        Text(
          isReadOnly ? l10n.dailyJournal : l10n.todaysJournal,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        
        // ========== DATE SUBTITLE ==========
        Text(
          _formatDate(date, l10n),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
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
          onChanged: isReadOnly ? null : (val) => setState(() => _overallFeeling = val),
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
          onChanged: isReadOnly ? null : (val) => setState(() => _stressLevel = val),
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
          onChanged: isReadOnly ? null : (val) => setState(() => _productivity = val),
        ),
        
        const SizedBox(height: 20),
        
        // Diary text area
        _buildDiaryTextArea(l10n, isReadOnly),
        
        if (!isReadOnly) ...[
          const SizedBox(height: 20),
          _buildSaveButton(l10n),
        ],
      ],
    );
  }

  Widget _buildLikertQuestion({
    required String question,
    required int? value,
    required List<String> labels,
    required Function(int)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
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
                    activeColor: AppColors.primary,
                  ),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.text.withOpacity(0.8),
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

  Widget _buildDiaryTextArea(AppLocalizations l10n, bool isReadOnly) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _diaryController,
          readOnly: isReadOnly,
          maxLines: 4,
          maxLength: _maxDiaryLength,
          decoration: InputDecoration(
            hintText: isReadOnly ? '' : l10n.writeYourThoughts,
            hintStyle: TextStyle(
              color: AppColors.border,
              fontWeight: FontWeight.normal,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
            style: TextStyle(
              fontSize: 12,
              color: AppColors.text.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(AppLocalizations l10n) {
    final canSave = _overallFeeling != null && 
                    _stressLevel != null && 
                    _productivity != null;
    
    return Center(
      child: AppButton(
        label: l10n.save,
        onPressed: canSave ? _saveCheckIn : null,
        isDisabled: !canSave,
      ),
    );
  }

  void _saveCheckIn() {
    // TODO: Save to Hive
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.journalSaved),
        duration: const Duration(seconds: 2),
      ),
    );
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
}