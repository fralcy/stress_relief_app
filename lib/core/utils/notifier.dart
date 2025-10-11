import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../models/index.dart';

class Notifier {
  // Notification channels
  static const String taskChannelKey = 'task_channel';
  static const String sleepChannelKey = 'sleep_channel';
  static const int sleepNotificationId = 0;

  /// Khởi tạo notification service
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // App icon (sẽ dùng icon mặc định)
      [
        NotificationChannel(
          channelKey: taskChannelKey,
          channelName: 'Task Reminders',
          channelDescription: 'Nhắc nhở công việc cần làm',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
        ),
        NotificationChannel(
          channelKey: sleepChannelKey,
          channelName: 'Sleep Reminders',
          channelDescription: 'Nhắc nhở giờ đi ngủ',
          defaultColor: const Color(0xFF5B9DD4),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
        ),
      ],
    );
  }

  /// Tạo notification ID từ task index
  /// Offset +1 để tránh conflict với sleepNotificationId (0)
  static int _getTaskNotificationId(int taskIndex) {
    return taskIndex + 1;
  }

  /// Đăng ký nhắc việc cần làm
  /// [taskIndex] - Index của task trong Hive box
  /// [task] - Task cần nhắc
  /// [minutesBefore] - Số phút nhắc trước
  static Future<void> scheduleTaskReminder({
    required int taskIndex,
    required ScheduleTask task,
    required int minutesBefore,
  }) async {
    if (task.isCompleted) return;

    final now = DateTime.now();
    final taskDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      task.startTime.hour,
      task.startTime.minute,
    );
    
    final reminderTime = taskDateTime.subtract(Duration(minutes: minutesBefore));

    // Chỉ schedule nếu thời gian nhắc chưa qua
    if (reminderTime.isAfter(now)) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _getTaskNotificationId(taskIndex),
          channelKey: taskChannelKey,
          title: 'Sắp đến giờ làm việc! ⏰',
          body: '${task.title} sẽ bắt đầu trong $minutesBefore phút',
          notificationLayout: NotificationLayout.Default,
          payload: {'type': 'task', 'index': taskIndex.toString()},
        ),
        schedule: NotificationCalendar(
          year: reminderTime.year,
          month: reminderTime.month,
          day: reminderTime.day,
          hour: reminderTime.hour,
          minute: reminderTime.minute,
          second: 0,
          millisecond: 0,
        ),
      );
    }
  }

  /// Đăng ký nhắc giờ đi ngủ hàng ngày
  /// [settings] - UserSettings chứa thông tin nhắc ngủ
  static Future<void> scheduleSleepReminder(UserSettings settings) async {
    if (!settings.sleepReminderEnabled) return;

    final sleepTime = settings.sleepReminderTime;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: sleepNotificationId,
        channelKey: sleepChannelKey,
        title: 'Đã đến giờ đi ngủ! 😴',
        body: 'Hãy nghỉ ngơi để ngày mai tràn đầy năng lượng nhé!',
        notificationLayout: NotificationLayout.Default,
        payload: {'type': 'sleep'},
      ),
      schedule: NotificationCalendar(
        hour: sleepTime.hour,
        minute: sleepTime.minute,
        second: 0,
        millisecond: 0,
        repeats: true, // Lặp lại hàng ngày
      ),
    );
  }

  /// Hủy nhắc việc cụ thể
  static Future<void> cancelTaskReminder(int taskIndex) async {
    await AwesomeNotifications().cancel(_getTaskNotificationId(taskIndex));
  }

  /// Hủy nhắc giờ ngủ
  static Future<void> cancelSleepReminder() async {
    await AwesomeNotifications().cancel(sleepNotificationId);
  }

  /// Hủy tất cả thông báo
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  /// Cập nhật tất cả task reminders
  /// Gọi khi user thay đổi setting hoặc thêm/sửa task
  static Future<void> updateAllTaskReminders({
    required List<ScheduleTask> tasks,
    required UserSettings settings,
  }) async {
    // Hủy tất cả task notifications cũ
    for (int i = 0; i < tasks.length; i++) {
      await cancelTaskReminder(i);
    }

    // Schedule lại nếu enabled
    if (settings.taskReminderEnabled) {
      for (int i = 0; i < tasks.length; i++) {
        await scheduleTaskReminder(
          taskIndex: i,
          task: tasks[i],
          minutesBefore: settings.taskReminderTime,
        );
      }
    }
  }

  /// Kiểm tra quyền notification
  static Future<bool> requestPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    
    if (!isAllowed) {
      return await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    
    return true;
  }

  /// Kiểm tra xem notification có được bật không
  static Future<bool> isNotificationAllowed() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }
}