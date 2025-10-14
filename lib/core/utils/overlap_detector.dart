// Detect tasks có thời gian trùng lặp

import '../../models/schedule_task.dart';

class OverlapDetector {
  /// Kiểm tra 2 tasks có overlap không
  static bool hasOverlap(ScheduleTask task1, ScheduleTask task2) {
    // Task 1 bắt đầu trước khi task 2 kết thúc
    // VÀ task 2 bắt đầu trước khi task 1 kết thúc
    return task1.startTimeMinutes < task2.endTimeMinutes &&
           task2.startTimeMinutes < task1.endTimeMinutes;
  }

  /// Tìm tất cả tasks có overlap
  /// Returns: Set các index của tasks bị overlap
  static Set<int> findOverlappingTasks(List<ScheduleTask> tasks) {
    final overlappingIndexes = <int>{};

    for (int i = 0; i < tasks.length; i++) {
      for (int j = i + 1; j < tasks.length; j++) {
        if (hasOverlap(tasks[i], tasks[j])) {
          overlappingIndexes.add(i);
          overlappingIndexes.add(j);
        }
      }
    }

    return overlappingIndexes;
  }

  /// Kiểm tra có task nào bị overlap không
  static bool hasAnyOverlap(List<ScheduleTask> tasks) {
    return findOverlappingTasks(tasks).isNotEmpty;
  }
}
