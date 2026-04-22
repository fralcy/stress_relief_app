// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/index.dart';
import 'data_manager.dart';

class Notifier {
  static const String taskChannelKey = 'task_channel';
  static const String sleepChannelKey = 'sleep_channel';
  static const int sleepNotificationId = 0;

  static final Map<int, Timer> _timers = {};
  static const String _iconPath = 'icons/Icon-192.png';

  /// Reinitializes timers from persisted settings — handles F5 page refresh.
  ///
  /// DataManager must be initialized before this is called (guaranteed by
  /// the order in main.dart). Permission is NOT requested here — only from
  /// user gestures in the Settings screen.
  static Future<void> initialize() async {
    final dm = DataManager();
    final settings = dm.userSettings;
    final tasks = dm.scheduleTasks;
    await updateAllTaskReminders(tasks: tasks, settings: settings);
    await scheduleSleepReminder(settings);
  }

  static int _getTaskNotificationId(int taskIndex) => taskIndex + 1;

  static void _show({
    required String title,
    required String body,
    required String tag,
    bool requireInteraction = false,
  }) {
    if (!html.Notification.supported) return;
    if (html.Notification.permission != 'granted') return;
    html.Notification(
      title,
      body: body,
      tag: tag,
      icon: _iconPath,
      // requireInteraction: requireInteraction, // uncomment nếu muốn user phải click mới đóng
    );
  }

  static void _setTimer(int id, Timer timer) {
    _timers[id]?.cancel();
    _timers[id] = timer;
  }

  static void _cancelTimer(int id) {
    _timers[id]?.cancel();
    _timers.remove(id);
  }

  static Future<void> scheduleTaskReminder({
    required int taskIndex,
    required ScheduleTask task,
    required int minutesBefore,
  }) async {
    if (task.isCompleted) return;
    final id = _getTaskNotificationId(taskIndex);
    final now = DateTime.now();
    final taskDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      task.startTime.hour,
      task.startTime.minute,
    );
    final reminderTime = taskDateTime.subtract(Duration(minutes: minutesBefore));
    if (!reminderTime.isAfter(now)) return;
    _setTimer(
      id,
      Timer(reminderTime.difference(now), () {
        _show(
          title: 'Sắp đến giờ làm việc! ⏰',
          body: '${task.title} sẽ bắt đầu trong $minutesBefore phút',
          tag: 'task_$taskIndex',
        );
        _timers.remove(id);
      }),
    );
  }

  static Future<void> scheduleSleepReminder(UserSettings settings) async {
    if (!settings.sleepReminderEnabled) return;
    _scheduleNextSleepFiring(settings.sleepReminderTime);
  }

  /// Recursive Timer pattern — emulates awesome_notifications' `repeats: true`.
  static void _scheduleNextSleepFiring(TimeOfDay sleepTime) {
    final now = DateTime.now();
    DateTime next = DateTime(
      now.year,
      now.month,
      now.day,
      sleepTime.hour,
      sleepTime.minute,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    _setTimer(
      sleepNotificationId,
      Timer(next.difference(now), () {
        _show(
          title: 'Đã đến giờ đi ngủ! 😴',
          body: 'Hãy nghỉ ngơi để ngày mai tràn đầy năng lượng nhé!',
          tag: 'sleep',
          requireInteraction: true,
        );
        _scheduleNextSleepFiring(sleepTime);
      }),
    );
  }

  static Future<void> cancelTaskReminder(int taskIndex) async =>
      _cancelTimer(_getTaskNotificationId(taskIndex));

  static Future<void> cancelSleepReminder() async =>
      _cancelTimer(sleepNotificationId);

  static Future<void> cancelAllNotifications() async {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }

  /// Sequential await matches notifier_io.dart behavior.
  /// Task list is typically small (<20 items) so lag is negligible.
  static Future<void> updateAllTaskReminders({
    required List<ScheduleTask> tasks,
    required UserSettings settings,
  }) async {
    for (int i = 0; i < tasks.length; i++) {
      await cancelTaskReminder(i);
    }
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

  /// Must be called from a user gesture (button tap in Settings) — not from
  /// initialize(). Browsers silently block the permission prompt at page load.
  static Future<bool> requestPermissions() async {
    if (!html.Notification.supported) return false;
    final current = html.Notification.permission;
    if (current == 'granted') return true;
    if (current == 'denied') return false;
    return await html.Notification.requestPermission() == 'granted';
  }

  static Future<bool> isNotificationAllowed() async {
    if (!html.Notification.supported) return false;
    return html.Notification.permission == 'granted';
  }

  // ==================== DEBUG METHODS ====================

  static Future<void> debugScheduleTaskNotification({
    required ScheduleTask task,
    required int taskIndex,
  }) async {
    _show(
      title: '⚡ [DEBUG] Task Notification',
      body: '${task.title} - Test notification',
      tag: 'debug_task_$taskIndex',
    );
  }

  static Future<void> debugScheduleDefaultNotification() async {
    _show(
      title: '⚡ [DEBUG] Test Notification',
      body: 'This is an instant test notification!',
      tag: 'debug_default',
    );
  }

  static Future<void> debugScheduleSleepNotification() async {
    _show(
      title: '⚡ [DEBUG] Sleep Reminder',
      body: 'Đã đến giờ đi ngủ! 😴 (test notification)',
      tag: 'debug_sleep',
    );
  }
}
