import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
    final TimezoneInfo currentTimeZone =
        await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_notification');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Normal Notification Permission (Android 13+)
      await androidPlugin.requestNotificationsPermission();

      // Exact Alarms Permission (Required for precise scheduling)
      await androidPlugin.requestExactAlarmsPermission();
    }

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
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    if (beforeTime.isAfter(tz.TZDateTime.now(tz.local))) {
      await _plugin.zonedSchedule(
        payload: task.id,
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
        payload: task.id,
        _idFor(task.id, '${occurrenceDate}_main'),
        'Task Time!',
        '${task.title} - it\'s time now.',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static const String _nudgeTitle = 'Pending Tasks Reminder';

  static const List<List<int>> _nudgeSlots = [
    [20, 0],
    [21, 30],
    [23, 0],
  ];

  Future<void> _cancelNudges() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.title == _nudgeTitle) {
        await _plugin.cancel(p.id);
      }
    }
  }

  /// pendingCount == 0 ho to koi nudge nahi, aur purane duplicates bhi hat jate hain.
  Future<void> syncNightlyNudges(DateTime today, int pendingCount) async {
    await _cancelNudges();
    if (pendingCount <= 0) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'nudge_channel',
        'Pending Task Nudges',
        channelDescription: 'Reminds you of pending tasks in the evening',
        importance: Importance.defaultImportance,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final dayKey = '${today.year}-${today.month}-${today.day}';
    final now = tz.TZDateTime.now(tz.local);
    final body = pendingCount == 1
        ? 'You still have 1 pending task today. Finish up to keep your streak!'
        : 'You still have $pendingCount pending tasks today. Finish up to keep your streak!';

    for (final slot in _nudgeSlots) {
      final time = tz.TZDateTime(
          tz.local, today.year, today.month, today.day, slot[0], slot[1]);
      if (!time.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        _idFor('nudge_$dayKey', '${slot[0]}_${slot[1]}'),
        _nudgeTitle,
        body,
        time,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
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

  Future<void> cancelOccasional(String id) =>
      _plugin.cancel(_idFor(id, '_occasional'));

  Future<void> cancelAllForTask(String taskId) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.payload == taskId) await _plugin.cancel(p.id);
    }
  }
}
