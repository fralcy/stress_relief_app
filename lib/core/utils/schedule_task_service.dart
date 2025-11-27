// Service tính điểm và nhận điểm
import 'package:flutter/material.dart';
import '../../models/index.dart';

class ScheduleTaskService {
  /// Tính điểm từ danh sách tasks
  /// Rule: 2 phút = 1 điểm, làm tròn xuống
  static int calculatePoints(List<ScheduleTask> tasks) {
    int totalMinutes = 0;
    for (var task in tasks) {
      if (task.isCompleted) {
        totalMinutes += task.durationInMinutes;
      }
    }
    return totalMinutes ~/ 2;
  }

  /// Kiểm tra có thể claim điểm hôm nay không
  static bool canClaimToday(DateTime? lastClaimDate) {
    if (lastClaimDate == null) return true;
    
    final now = DateTime.now();
    final lastClaim = DateTime(
      lastClaimDate.year,
      lastClaimDate.month,
      lastClaimDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    
    return today.isAfter(lastClaim);
  }

  /// Tính điểm dự kiến từ completed tasks (chưa claim)
  static int getPendingPoints(List<ScheduleTask> tasks) {
    return calculatePoints(tasks);
  }

  /// Đếm số task đã hoàn thành
  static int countCompletedTasks(List<ScheduleTask> tasks) {
    return tasks.where((task) => task.isCompleted).length;
  }

  /// Format TimeOfDay thành string HH:mm
  static String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Xử lý tasks sau khi claim:
  /// - Daily tasks: reset về chưa hoàn thành
  /// - Non-daily completed tasks: xóa bỏ
  /// - Non-daily incomplete tasks: giữ nguyên
  static List<ScheduleTask> processTasksAfterClaim(List<ScheduleTask> tasks) {
    return tasks.map((task) {
      if (task.isCompleted && task.isDaily) {
        // Task hàng ngày: reset về chưa hoàn thành
        return task.copyWith(isCompleted: false);
      } else if (!task.isCompleted) {
        // Task chưa hoàn thành: giữ nguyên
        return task;
      } else {
        // Task đã hoàn thành nhưng không phải daily: sẽ bị lọc bỏ
        return null;
      }
    }).where((task) => task != null).cast<ScheduleTask>().toList();
  }
}