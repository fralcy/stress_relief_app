import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/data_manager.dart';
import '../../core/utils/notifier.dart';
import '../../core/l10n/app_localizations.dart';
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
    return AppModal.show(
      context: context,
      title: l10n.scheduleTask,
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
  final Map<int, bool> _editingMode = {};
  final Map<int, TextEditingController> _editControllers = {};
  final Map<int, TimeOfDay> _editStartTimes = {};
  final Map<int, TimeOfDay> _editEndTimes = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _updateNotifications();
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
      // Sắp xếp theo thời gian bắt đầu tăng dần
      _tasks.sort((a, b) => a.startTimeMinutes.compareTo(b.startTimeMinutes));
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
      _showToast('Vui lòng nhập tên công việc');
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
    _showToast('Đã thêm công việc');
  }

  Future<void> _toggleTask(int index) async {
    final task = _tasks[index];
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await DataManager().updateScheduleTask(index, updatedTask);
    _loadTasks();
  }

  Future<void> _deleteTask(int index) async {
    await DataManager().removeScheduleTask(index);
    _loadTasks();
    await _updateNotifications();
    _showToast('Đã xóa công việc');
  }

  Future<void> _updateTask(int index) async {
    final controller = _editControllers[index];
    if (controller == null || controller.text.trim().isEmpty) {
      _showToast('Tên công việc không được để trống');
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
    _showToast('Đã cập nhật');
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      setState(() {
        onPicked(picked);
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _completedCount() {
    return _tasks.where((task) => task.isCompleted).length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========== ADD TASK SECTION ==========
        _buildAddSection(l10n),
        
        const SizedBox(height: 24),
        const Divider(color: AppColors.border, height: 1, thickness: 1.5),
        const SizedBox(height: 16),
        
        // ========== TASK LIST SECTION ==========
        _buildTaskList(),
        
        const SizedBox(height: 16),
        const Divider(color: AppColors.border, height: 1, thickness: 1.5),
        const SizedBox(height: 16),
        
        // ========== FOOTER ==========
        _buildFooter(),
      ],
    );
  }

  Widget _buildAddSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task name input
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: l10n.taskName,
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Time pickers
        Row(
          children: [
            Text(
              '${l10n.time}: ',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            _buildTimePicker(
              time: _startTime,
              onTap: () => _pickTime(
                initialTime: _startTime,
                onPicked: (time) => _startTime = time,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '-',
                style: TextStyle(color: AppColors.text, fontSize: 18),
              ),
            ),
            _buildTimePicker(
              time: _endTime,
              onTap: () => _pickTime(
                initialTime: _endTime,
                onPicked: (time) => _endTime = time,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Add button
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
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(time),
              style: const TextStyle(
                color: AppColors.background,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.arrow_drop_down,
              color: AppColors.background,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    if (_tasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Chưa có công việc nào',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
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
          return _buildTaskItem(index);
        },
      ),
    );
  }

  Widget _buildTaskItem(int index) {
    final task = _tasks[index];
    final isEditing = _editingMode[index] ?? false;
    
    if (!_editControllers.containsKey(index)) {
      _editControllers[index] = TextEditingController(text: task.title);
    }
    
    // Lưu thời gian hiện tại cho edit mode
    if (isEditing && !_editStartTimes.containsKey(index)) {
      _editStartTimes[index] = task.startTime;
      _editEndTimes[index] = task.endTime;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Toggle complete button
              SizedBox(
                width: 40,
                height: 40,
                child: Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => _toggleTask(index),
                  activeColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border, width: 1.5),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Task name (editable if in edit mode)
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: _editControllers[index],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      )
                    : Text(
                        task.title,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
              ),
              
              const SizedBox(width: 8),
              
              // Delete button
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.primary),
                onPressed: () => _deleteTask(index),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Time display and Edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isEditing)
                // Editable time pickers
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
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('-', style: TextStyle(color: AppColors.text, fontSize: 14)),
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
                      ),
                    ],
                  ),
                )
              else
                // Read-only time display
                Text(
                  '${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                  ),
                ),
              
              AppButton(
                label: isEditing ? 'Lưu' : 'Sửa',
                onPressed: () {
                  if (isEditing) {
                    _updateTask(index);
                  } else {
                    setState(() {
                      _editingMode[index] = true;
                    });
                  }
                },
                width: 70,
                height: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Hoàn thành: ${_completedCount()}/${_tasks.length}',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Kiếm được: 50',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}