import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/task_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  int _idFor(String taskId, String suffix) =>
      (taskId + suffix).hashCode & 0x7fffffff;

  Future<void> scheduleTaskReminders(
      TaskModel task, DateTime occurrenceDate) async {
    if (task.taskTime == null) return;
    final parts = task.taskTime!.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final scheduledTime = tz.TZDateTime(
      tz.local,
      occurrenceDate.year,
      occurrenceDate.month,
      occurrenceDate.day,
      hour,
      minute,
    );
    final beforeTime = scheduledTime.subtract(const Duration(minutes: 15));

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_channel',
        'Task Reminders',
        channelDescription: 'Reminders for scheduled tasks',
        importance: Importance.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    if (beforeTime.isAfter(tz.TZDateTime.now(tz.local))) {
      await _plugin.zonedSchedule(
        _idFor(task.id, '${occurrenceDate}_pre'),
        'Upcoming Task in 15 mins',
        task.title,
        beforeTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    if (scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) {
      await _plugin.zonedSchedule(
        _idFor(task.id, '${occurrenceDate}_main'),
        'Task Time!',
        '${task.title} - it\'s time now.',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> scheduleNightlyNudges(DateTime today) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'nudge_channel',
        'Pending Task Nudges',
        channelDescription: 'Reminds you of pending tasks after 8 PM',
        importance: Importance.defaultImportance,
      ),
      iOS: DarwinNotificationDetails(),
    );

    for (int hour = 20; hour <= 23; hour++) {
      for (int minute in [0, 30]) {
        if (hour == 23 && minute == 30) continue;
        final time = tz.TZDateTime(
            tz.local, today.year, today.month, today.day, hour, minute);
        if (time.isBefore(tz.TZDateTime.now(tz.local))) continue;
        await _plugin.zonedSchedule(
          _idFor('nudge_$today', '${hour}_$minute'),
          'Pending Tasks Reminder',
          'You still have pending tasks today. Finish up to keep your streak!',
          time,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> cancelRemainingNudges(DateTime today) async {
    for (int hour = 20; hour <= 23; hour++) {
      for (int minute in [0, 30]) {
        await _plugin.cancel(_idFor('nudge_$today', '${hour}_$minute'));
      }
    }
  }

  Future<void> scheduleOccasionalReminder(
      String id, String title, DateTime date, String? time) async {
    if (time == null) return;
    final parts = time.split(':');
    final scheduledTime = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'occasional_channel',
        'Occasional Reminders',
        channelDescription: 'One-off event reminders',
        importance: Importance.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _idFor(id, '_occasional'),
      'Occasional Reminder',
      title,
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAllForTask(String taskId) async {}
}
