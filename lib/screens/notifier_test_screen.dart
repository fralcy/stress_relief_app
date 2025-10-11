import 'package:flutter/material.dart';
import '../core/utils/notifier.dart';
import '../core/utils/data_manager.dart';
import '../models/schedule_task.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

/// Screen đơn giản để test Notifier
class NotifierTestScreen extends StatefulWidget {
  const NotifierTestScreen({super.key});

  @override
  State<NotifierTestScreen> createState() => _NotifierTestScreenState();
}

class _NotifierTestScreenState extends State<NotifierTestScreen> {
  bool _permissionGranted = false;
  List<ScheduleTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _tasks = DataManager().scheduleTasks;
    });
  }

  Future<void> _requestPermission() async {
    final granted = await Notifier.requestPermissions();
    setState(() {
      _permissionGranted = granted;
    });
    
    if (granted) {
      _showSnackBar('Permission granted ✓');
      
      // Test notification luôn sau khi có permission
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 998,
          channelKey: 'task_channel',
          title: '✅ Permission Test',
          body: 'Notification permission granted successfully!',
          notificationLayout: NotificationLayout.Default,
        ),
      );
    } else {
      _showSnackBar('Permission denied ✗');
    }
  }

  Future<void> _addTestTask() async {
    // Tạo task test: bắt đầu sau 30 giây
    final now = DateTime.now();
    final startTime = now.add(const Duration(seconds: 30));
    
    final task = ScheduleTask.create(
      title: 'Test Task ${_tasks.length + 1}',
      startTime: TimeOfDay(hour: startTime.hour, minute: startTime.minute),
      endTime: TimeOfDay(hour: startTime.hour, minute: startTime.minute + 30),
    );
    
    await DataManager().addScheduleTask(task);
    _loadTasks();
    _showSnackBar('Task added (starts in 30 sec)');
  }
  
  Future<void> _scheduleInstantNotification() async {
    // Test notification NGAY LẬP TỨC (không cần schedule)
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 999,
        channelKey: 'task_channel',
        title: '⚡ Test Notification',
        body: 'This is an instant test notification!',
        notificationLayout: NotificationLayout.Default,
      ),
    );
    
    _showSnackBar('⚡ Instant notification sent!');
  }

  Future<void> _scheduleTaskNotification(int index) async {
    final task = _tasks[index];
    final settings = DataManager().userSettings;
    
    await Notifier.scheduleTaskReminder(
      taskIndex: index,
      task: task,
      minutesBefore: settings.taskReminderTime,
    );
    
    _showSnackBar('Notification scheduled for "${task.title}"');
  }

  Future<void> _scheduleSleepNotification() async {
    final settings = DataManager().userSettings;
    await Notifier.scheduleSleepReminder(settings);
    
    final time = settings.sleepReminderTime;
    _showSnackBar('Sleep reminder set at ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
  }

  Future<void> _updateAllNotifications() async {
    final settings = DataManager().userSettings;
    await Notifier.updateAllTaskReminders(
      tasks: _tasks,
      settings: settings,
    );
    _showSnackBar('All notifications updated');
  }

  Future<void> _cancelAllNotifications() async {
    await Notifier.cancelAllNotifications();
    _showSnackBar('All notifications cancelled');
  }

  Future<void> _deleteTask(int index) async {
    await Notifier.cancelTaskReminder(index);
    await DataManager().removeScheduleTask(index);
    _loadTasks();
    _showSnackBar('Task deleted');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = DataManager().userSettings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifier Test'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Permission section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Permission',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _permissionGranted ? Icons.check_circle : Icons.cancel,
                        color: _permissionGranted ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(_permissionGranted ? 'Granted' : 'Not granted'),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _requestPermission,
                        child: const Text('Request'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          
          // Quick test
          Card(
            color: Colors.amber[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚡ Quick Test',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Test notification immediately (appears in 5 seconds)'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _scheduleInstantNotification,
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Test Now (5s)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Settings info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2. Current Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Task reminder: ${settings.taskReminderEnabled ? "ON" : "OFF"} (${settings.taskReminderTime} min before)'),
                  Text('Sleep reminder: ${settings.sleepReminderEnabled ? "ON" : "OFF"} (${settings.sleepReminderTime.hour}:${settings.sleepReminderTime.minute.toString().padLeft(2, '0')})'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sleep notification
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '3. Sleep Notification',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _scheduleSleepNotification,
                    child: const Text('Schedule Sleep Reminder'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Task notifications
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '4. Task Notifications',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addTestTask,
                        tooltip: 'Add test task',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  if (_tasks.isEmpty)
                    const Text('No tasks. Add a test task!'),
                  
                  ..._tasks.asMap().entries.map((entry) {
                    final index = entry.key;
                    final task = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.grey[100],
                      child: ListTile(
                        title: Text(task.title),
                        subtitle: Text(
                          '${task.startTime.hour}:${task.startTime.minute.toString().padLeft(2, '0')} - '
                          '${task.endTime.hour}:${task.endTime.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications, size: 20),
                              onPressed: () => _scheduleTaskNotification(index),
                              tooltip: 'Schedule notification',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _deleteTask(index),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _tasks.isEmpty ? null : _updateAllNotifications,
                    child: const Text('Update All Task Notifications'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Danger zone
          Card(
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '5. Danger Zone',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _cancelAllNotifications,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Cancel All Notifications'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Instructions
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to test:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. Request permission'),
                  Text('2. Click "⚡ Test Now" for instant test (5 sec)'),
                  Text('3. Or add task manually (starts in 30 sec)'),
                  Text('4. Schedule notification for that task'),
                  Text('5. Test sleep reminder'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}