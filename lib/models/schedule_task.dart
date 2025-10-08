import 'package:flutter/material.dart';
// Model cho task trong lịch trình hàng ngày
class ScheduleTask {
  final String title;            // Tên công việc
  final TimeOfDay startTime;     // Giờ bắt đầu (ví dụ: 08:00)
  final TimeOfDay endTime;       // Giờ kết thúc (ví dụ: 10:00)
  final bool isCompleted;        // Đã hoàn thành chưa

  ScheduleTask({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.isCompleted,
  });

  /// Constructor cho task mới (chưa hoàn thành)
  factory ScheduleTask.create({
    required String title,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) {
    return ScheduleTask(
      title: title,
      startTime: startTime,
      endTime: endTime,
      isCompleted: false,
    );
  }

  // Tạo bản sao với các thay đổi
  ScheduleTask copyWith({
    String? title,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isCompleted,
  }) {
    return ScheduleTask(
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
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
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes - startMinutes;
  }

  // Kiểm tra task có đang diễn ra không
  bool isActiveAt(TimeOfDay currentTime) {
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    
    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }
}