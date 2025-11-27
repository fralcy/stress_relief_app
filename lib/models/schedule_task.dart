import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'schedule_task.g.dart';

// Model cho task trong lịch trình hàng ngày
@HiveType(typeId: 2)
class ScheduleTask {
  @HiveField(0)
  final String title;            // Tên công việc
  
  @HiveField(1)
  final int startTimeMinutes;    // Giờ bắt đầu lưu dưới dạng minutes (ví dụ: 08:00 = 480)
  
  @HiveField(2)
  final int endTimeMinutes;      // Giờ kết thúc lưu dưới dạng minutes (ví dụ: 10:00 = 600)
  
  @HiveField(3)
  final bool isCompleted;        // Đã hoàn thành chưa

  @HiveField(4)
  final bool isDaily;            // Task hàng ngày (không xóa khi kết thúc ngày)

  ScheduleTask({
    required this.title,
    required this.startTimeMinutes,
    required this.endTimeMinutes,
    required this.isCompleted,
    this.isDaily = false,
  });

  // Helper getters để convert sang TimeOfDay
  TimeOfDay get startTime {
    final hours = startTimeMinutes ~/ 60;
    final minutes = startTimeMinutes % 60;
    return TimeOfDay(hour: hours, minute: minutes);
  }

  TimeOfDay get endTime {
    final hours = endTimeMinutes ~/ 60;
    final minutes = endTimeMinutes % 60;
    return TimeOfDay(hour: hours, minute: minutes);
  }

  /// Constructor cho task mới (chưa hoàn thành)
  factory ScheduleTask.create({
    required String title,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    bool isDaily = false,
  }) {
    return ScheduleTask(
      title: title,
      startTimeMinutes: startTime.hour * 60 + startTime.minute,
      endTimeMinutes: endTime.hour * 60 + endTime.minute,
      isCompleted: false,
      isDaily: isDaily,
    );
  }

  // Tạo bản sao với các thay đổi
  ScheduleTask copyWith({
    String? title,
    int? startTimeMinutes,
    int? endTimeMinutes,
    TimeOfDay? startTime, // Cho phép truyền TimeOfDay
    TimeOfDay? endTime,   // Cho phép truyền TimeOfDay
    bool? isCompleted,
    bool? isDaily,
  }) {
    // Convert TimeOfDay sang minutes nếu được truyền
    int? finalStartMinutes = startTimeMinutes;
    if (startTime != null) {
      finalStartMinutes = startTime.hour * 60 + startTime.minute;
    }

    int? finalEndMinutes = endTimeMinutes;
    if (endTime != null) {
      finalEndMinutes = endTime.hour * 60 + endTime.minute;
    }

    return ScheduleTask(
      title: title ?? this.title,
      startTimeMinutes: finalStartMinutes ?? this.startTimeMinutes,
      endTimeMinutes: finalEndMinutes ?? this.endTimeMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      isDaily: isDaily ?? this.isDaily,
    );
  }

  // Đánh dấu task đã hoàn thành
  ScheduleTask markCompleted() {
    return copyWith(isCompleted: true);
  }

  // Đánh dấu task chưa hoàn thành
  ScheduleTask markIncomplete() {
    return copyWith(isCompleted: false);
  }

  // Tính thời lượng của task (phút)
  int get durationInMinutes {
    return endTimeMinutes - startTimeMinutes;
  }

  // Kiểm tra task có đang diễn ra không
  bool isActiveAt(TimeOfDay currentTime) {
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    return currentMinutes >= startTimeMinutes && currentMinutes < endTimeMinutes;
  }
}