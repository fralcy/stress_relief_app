import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/notifier.dart';
import '../../core/utils/schedule_task_service.dart';
import '../../core/utils/overlap_detector.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/utils/auth_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/score_provider.dart';
import '../../models/schedule_task.dart';

// Export
export 'schedule_task_modal.dart';

/// Modal quản lý lịch trình công việc
class ScheduleTaskModal extends StatefulWidget {
  const ScheduleTaskModal({super.key});

  @override
  State<ScheduleTaskModal> createState() => _ScheduleTaskModalState();

  /// Helper để show modal
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasOverlap = OverlapDetector.hasAnyOverlap(DataManager().scheduleTasks);
    
    return AppModal.show(
      context: context,
      title: hasOverlap ? '⚠️ ${l10n.scheduleTask}' : l10n.scheduleTask,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      content: const ScheduleTaskModal(),
    );
  }
}

class _ScheduleTaskModalState extends State<ScheduleTaskModal> {
  final TextEditingController _titleController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 0);
  
  List<ScheduleTask> _tasks = [];
  Set<int> _overlappingIndexes = {};
  
  final Map<int, bool> _editingMode = {};
  final Map<int, TextEditingController> _editControllers = {};
  final Map<int, TimeOfDay> _editStartTimes = {};
  final Map<int, TimeOfDay> _editEndTimes = {};

  // Debug mode state
  bool _isDebugMode = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _updateNotifications();
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
    _titleController.dispose();
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadTasks() {
    setState(() {
      _tasks = DataManager().scheduleTasks;
      _tasks.sort((a, b) => a.startTimeMinutes.compareTo(b.startTimeMinutes));
      _overlappingIndexes = OverlapDetector.findOverlappingTasks(_tasks);
    });
  }

  Future<void> _updateNotifications() async {
    final settings = DataManager().userSettings;
    await Notifier.updateAllTaskReminders(
      tasks: _tasks,
      settings: settings,
    );
  }

  Future<void> _addTask() async {
    if (_titleController.text.trim().isEmpty) {
      SfxService().error();
      return;
    }

    final task = ScheduleTask.create(
      title: _titleController.text.trim(),
      startTime: _startTime,
      endTime: _endTime,
    );

    await DataManager().addScheduleTask(task);
    _titleController.clear();
    _loadTasks();
    await _updateNotifications();
    SfxService().buttonClick();
  }

  Future<void> _toggleTask(int index) async {
    final task = _tasks[index];
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await DataManager().updateScheduleTask(index, updatedTask);
    _loadTasks();
    await _updateNotifications();

    // Play appropriate sound
    if (updatedTask.isCompleted) {
      SfxService().taskComplete();
    } else {
      SfxService().buttonClick();
    }
  }

  Future<void> _toggleIsDaily(int index) async {
    final task = _tasks[index];
    final updatedTask = task.copyWith(isDaily: !task.isDaily);
    await DataManager().updateScheduleTask(index, updatedTask);
    _loadTasks();
    SfxService().buttonClick();
  }

  Future<void> _deleteTask(int index) async {
    await DataManager().removeScheduleTask(index);
    _loadTasks();
    await _updateNotifications();
    SfxService().buttonClick();
  }

  Future<void> _updateTask(int index) async {
    final controller = _editControllers[index];
    
    if (controller == null || controller.text.trim().isEmpty) {
      SfxService().error();
      return;
    }

    final task = _tasks[index];
    final startTime = _editStartTimes[index] ?? task.startTime;
    final endTime = _editEndTimes[index] ?? task.endTime;
    
    final updatedTask = task.copyWith(
      title: controller.text.trim(),
      startTime: startTime,
      endTime: endTime,
    );
    await DataManager().updateScheduleTask(index, updatedTask);
    
    setState(() {
      _editingMode[index] = false;
      _editStartTimes.remove(index);
      _editEndTimes.remove(index);
    });
    _loadTasks();
    SfxService().buttonClick();
  }

  Future<void> _claimPoints() async {
    // Lấy profile từ provider
    final profile = context.read<ScoreProvider>().profile;
    final tasks = DataManager().scheduleTasks;

    // Check đã claim hôm nay chưa (bypass in debug mode)
    if (!_isDebugMode && !ScheduleTaskService.canClaimToday(profile.lastPointsClaimDate)) {
      SfxService().error();
      return;
    }

    // Tính điểm từ completed tasks
    final points = ScheduleTaskService.calculatePoints(tasks);
    if (points == 0) {
      SfxService().error();
      return;
    }

    // Cộng điểm qua provider ← KEY!
    await context.read<ScoreProvider>().addPoints(points);

    // Update last claim date (skip in debug mode to allow multiple claims)
    if (!_isDebugMode) {
      await context.read<ScoreProvider>().updateLastClaimDate(DateTime.now());
    }

    // Xử lý tasks: xóa completed non-daily, reset completed daily
    final processedTasks = ScheduleTaskService.processTasksAfterClaim(tasks);
    await DataManager().saveScheduleTasks(processedTasks);

    SfxService().reward();
    _loadTasks();
  }

  Future<void> _debugTriggerTaskNotification(int index) async {
    if (!_isDebugMode) return; // Safety guard

    final task = _tasks[index];

    // Use Notifier utility method
    await Notifier.debugScheduleTaskNotification(
      task: task,
      taskIndex: index,
    );

    SfxService().buttonClick();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('[DEBUG] Task notification sent immediately!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.deepPurple,
        ),
      );
    }
  }

  Future<void> _debugTriggerDefaultNotification() async {
    if (!_isDebugMode) return; // Safety guard

    // Use Notifier utility method for default test
    await Notifier.debugScheduleDefaultNotification();

    SfxService().buttonClick();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('[DEBUG] Test notification sent immediately!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.deepPurple,
        ),
      );
    }
  }

  Future<void> _pickTime({
    required TimeOfDay initialTime,
    required Function(TimeOfDay) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      SfxService().buttonClick();
      setState(() {
        onPicked(picked);
      });
    }
  }

  String _formatTime(TimeOfDay time) => ScheduleTaskService.formatTime(time);
  int _completedCount() => ScheduleTaskService.countCompletedTasks(_tasks);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========== ADD TASK SECTION ==========
        _buildAddSection(l10n, theme),
        
        const SizedBox(height: 24),
        Divider(color: theme.border, height: 1, thickness: 1.5),
        const SizedBox(height: 16),
        
        // ========== TASK LIST SECTION ==========
        _buildTaskList(theme),
        
        const SizedBox(height: 16),
        Divider(color: theme.border, height: 1, thickness: 1.5),
        const SizedBox(height: 16),
        
        // ========== FOOTER ==========
        _buildFooter(l10n, theme),
      ],
    );
  }

  Widget _buildAddSection(AppLocalizations l10n, AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task name input
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: l10n.taskName,
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
              borderSide: BorderSide(color: theme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        
        const SizedBox(height: 12),
        
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTimePicker(
                time: _startTime,
                onTap: () => _pickTime(
                  initialTime: _startTime,
                  onPicked: (time) => _startTime = time,
                ),
                theme: theme,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Builder(
                builder: (context) => Text('-', style: AppTypography.h4(context, color: theme.text)),
              ),
            ),
            Expanded(
              child: _buildTimePicker(
                time: _endTime,
                onTap: () => _pickTime(
                  initialTime: _endTime,
                  onPicked: (time) => _endTime = time,
                ),
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isDebugMode)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppButton(
                label: l10n.addTask,
                onPressed: _addTask,
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _debugTriggerDefaultNotification,
                icon: const Icon(Icons.bug_report, size: 18),
                label: const Text('Test Noti'),
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
          )
        else
          Center(
            child: AppButton(
              label: l10n.addTask,
              onPressed: _addTask,
            ),
          ),
      ],
    );
  }

  Widget _buildTimePicker({
    required TimeOfDay time,
    required VoidCallback onTap,
    required AppTheme theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.border, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(
              builder: (context) => Text(
                _formatTime(time),
                style: AppTypography.labelMedium(context,
                  color: theme.background,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              color: theme.background,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(AppTheme theme) {
    if (_tasks.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Builder(
            builder: (context) => Text(
              l10n.noTasksYet,
              style: AppTypography.bodyMedium(context, color: theme.text),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          return _buildTaskItem(index, theme);
        },
      ),
    );
  }

  Widget _buildTaskItem(int index, AppTheme theme) {
    final task = _tasks[index];
    final isEditing = _editingMode[index] ?? false;
    final hasOverlap = _overlappingIndexes.contains(index);
    
    if (!_editControllers.containsKey(index)) {
      _editControllers[index] = TextEditingController(text: task.title);
    }
    
    if (isEditing && !_editStartTimes.containsKey(index)) {
      _editStartTimes[index] = task.startTime;
      _editEndTimes[index] = task.endTime;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.theme.background,
        border: Border.all(
          color: hasOverlap ? Colors.orange : context.theme.border,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => _toggleTask(index),
                  activeColor: theme.primary,
                  side: BorderSide(color: theme.border, width: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              
              // Warning icon if overlap
              if (hasOverlap) ...[
                const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
              ],
              
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: _editControllers[index],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.border, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      )
                    : Builder(
                        builder: (ctx) => Text(
                          task.title,
                          style: AppTypography.bodyLarge(ctx,
                            color: context.theme.text,
                          ).copyWith(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.repeat_outlined,
                  color: task.isDaily ? theme.primary : theme.border,
                ),
                onPressed: () => _toggleIsDaily(index),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: Icon(Icons.close, color: theme.primary),
                onPressed: () => _deleteTask(index),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isEditing)
                Expanded(
                  child: Row(
                    children: [
                      _buildTimePicker(
                        time: _editStartTimes[index] ?? task.startTime,
                        onTap: () => _pickTime(
                          initialTime: _editStartTimes[index] ?? task.startTime,
                          onPicked: (time) {
                            setState(() {
                              _editStartTimes[index] = time;
                            });
                          },
                        ),
                        theme: theme,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Builder(
                          builder: (ctx) => Text('-', style: AppTypography.bodyMedium(ctx, color: theme.text)),
                        ),
                      ),
                      _buildTimePicker(
                        time: _editEndTimes[index] ?? task.endTime,
                        onTap: () => _pickTime(
                          initialTime: _editEndTimes[index] ?? task.endTime,
                          onPicked: (time) {
                            setState(() {
                              _editEndTimes[index] = time;
                            });
                          },
                        ),
                        theme: theme,
                      ),
                    ],
                  ),
                )
              else
                Builder(
                  builder: (ctx) => Text(
                    '${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}',
                    style: AppTypography.bodyMedium(ctx, color: theme.text),
                  ),
                ),
              if (isEditing)
                IconButton(
                  onPressed: () => _updateTask(index),
                  icon: Icon(Icons.check, color: theme.primary),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                )
              else
                IconButton(
                  onPressed: () {
                    setState(() {
                      _editingMode[index] = true;
                    });
                  },
                  icon: Icon(Icons.edit, color: theme.primary),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              if (_isDebugMode)
                IconButton(
                  onPressed: () => _debugTriggerTaskNotification(index),
                  icon: const Icon(Icons.bug_report, color: Colors.deepPurple),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  tooltip: '[DEBUG] Trigger notification in 10s',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n, AppTheme theme) {
    final profile = context.watch<ScoreProvider>().profile;
    final pendingPoints = ScheduleTaskService.getPendingPoints(_tasks);
    final canClaim = ScheduleTaskService.canClaimToday(profile.lastPointsClaimDate) && pendingPoints > 0;

    return Column(
      children: [
        // Hiển thị điểm dự kiến
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: (ctx) => Text(
                l10n.expectedPoints,
                style: AppTypography.labelMedium(ctx,
                  color: theme.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Builder(
              builder: (ctx) => Text(
                '$pendingPoints',
                style: AppTypography.h4(ctx,
                  color: theme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Button claim điểm
        AppButton(
          label: l10n.endDayAndClaimPoints,
          onPressed: _claimPoints,
          isDisabled: !canClaim,
        ),
        
        const SizedBox(height: 8),
        
        // Helper text
        Builder(
          builder: (ctx) => Text(
            canClaim
              ? '${l10n.completedTasks.replaceAll('{count}', '${_completedCount()}')}'
              : profile.lastPointsClaimDate != null
                ? l10n.alreadyClaimedToday
                : l10n.noCompletedTasks,
            style: AppTypography.bodySmall(ctx,
              color: theme.border,
            ),
          ),
        ),
      ],
    );
  }
}