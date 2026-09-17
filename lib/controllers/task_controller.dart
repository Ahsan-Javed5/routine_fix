import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/ai_service.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import '../services/recurrence_service.dart';

class TaskController extends GetxController {
  final RxList<TaskModel> allTasks = <TaskModel>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  static const int dailyAiLimit = 5;
  final _storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }

  String _aiUsageKey() {
    final d = DateTime.now();
    return 'ai_usage_${d.year}-${d.month}-${d.day}';
  }

  int get aiUsesToday => _storage.read(_aiUsageKey()) ?? 0;

  bool get canUseAiToday => aiUsesToday < dailyAiLimit;

  void _incrementAiUsage() {
    _storage.write(_aiUsageKey(), aiUsesToday + 1);
  }

  Future<List<Map<String, dynamic>>> generateAiSuggestions(String goal) async {
    if (!canUseAiToday) {
      throw Exception(
          'Daily AI limit reached ($dailyAiLimit/day). Try again tomorrow.');
    }
    final suggestions = await AiService.instance.generateRoutine(goal);
    _incrementAiUsage();
    return suggestions;
  }

  Future<void> addAiTasks(List<Map<String, dynamic>> picked) async {
    for (final t in picked) {
      final task = TaskModel(
        id: newId(),
        title: t['title'],
        description: t['description'] ?? '',
        taskTime: t['time'],
        repetition: Repetition.daily,
      );
      await addTask(task);
    }
  }

  Future<void> loadTasks() async {
    allTasks.value = await DbService.instance.loadTasks();
  }

  /// Tasks that occur on the currently selected date.
  List<TaskModel> get tasksForSelectedDate => tasksForDate(selectedDate.value);

  /// Tasks that occur on any given date.
  List<TaskModel> tasksForDate(DateTime date) {
    return allTasks.where((t) {
      if (t.archivedAtDate != null) {
        final d = DateTime(date.year, date.month, date.day);
        final archived = DateTime(
          t.archivedAtDate!.year,
          t.archivedAtDate!.month,
          t.archivedAtDate!.day,
        );

        if (!d.isBefore(archived)) return false;
      }

      return RecurrenceService.occursOn(t, date);
    }).toList()
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
  }

  String _key(DateTime date) => RecurrenceService.dateKey(date);

  TaskStatus statusOn(TaskModel task, DateTime date) {
    final key = _key(date);
    final raw = task.occurrenceStatus[key];
    if (raw == null) return TaskStatus.pending;
    return TaskStatus.values
        .firstWhere((e) => e.name == raw, orElse: () => TaskStatus.pending);
  }

  Future<void> addTask(TaskModel task) async {
    allTasks.add(task);
    await DbService.instance.saveTasks(allTasks);
    if (task.taskTime != null && task.taskDate != null) {
      await NotificationService.instance
          .scheduleTaskReminders(task, task.taskDate!);
    }
  }

  Future<void> toggleComplete(TaskModel task, DateTime date) async {
    final key = _key(date);
    final current = statusOn(task, date);
    task.occurrenceStatus[key] = current == TaskStatus.done
        ? TaskStatus.pending.name
        : TaskStatus.done.name;
    await DbService.instance.saveTasks(allTasks);
    allTasks.refresh();

    // If all of today's tasks are now done, cancel remaining nightly nudges.
    final today = DateTime.now();
    if (_key(date) == _key(today)) {
      final todays = tasksForSelectedDate;
      final allDone =
          todays.every((t) => statusOn(t, today) == TaskStatus.done);
      if (allDone && todays.isNotEmpty) {
        await NotificationService.instance.cancelRemainingNudges(today);
      }
    }
  }

  Future<void> deleteTask(String id) async {
    allTasks.removeWhere((t) => t.id == id);
    await DbService.instance.saveTasks(allTasks);
  }

  /// Soft delete task for selected date onwards
  Future<void> archiveTask(TaskModel task, DateTime currentDate) async {
    final updatedTask = task.copyWith(archivedAtDate: currentDate);
    final index = allTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      allTasks[index] = updatedTask;
      await DbService.instance.saveTasks(allTasks);
      allTasks.refresh();
    }
  }

  /// Replaces all tasks (used when restoring a backup).
  Future<void> restoreTasks(List<TaskModel> tasks) async {
    allTasks.value = tasks;
    await DbService.instance.saveTasks(allTasks);
  }

  String newId() => const Uuid().v4();

  // ---------------- Streak tracking ----------------

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _earliestDay {
    if (allTasks.isEmpty) return _dayOnly(DateTime.now());
    final earliest = allTasks
        .map((t) => t.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return _dayOnly(earliest);
  }

  /// A day only "breaks" the streak if tasks were planned for it and not
  /// all completed. Days with nothing planned are skipped, not counted.
  bool _isPerfectDay(DateTime day) {
    final dayTasks = tasksForDate(day);
    if (dayTasks.isEmpty) return true; // neutral, doesn't break the streak
    return dayTasks.every((t) => statusOn(t, day) == TaskStatus.done);
  }

  bool _hasTasks(DateTime day) => tasksForDate(day).isNotEmpty;

  /// Consecutive days up to today (inclusive) where every planned task
  /// was completed. Days with nothing planned don't break the chain.
  int get currentStreak {
    final earliest = _earliestDay;
    final today = _dayOnly(DateTime.now());
    int streak = 0;
    for (int i = 0;; i++) {
      final day = today.subtract(Duration(days: i));
      if (day.isBefore(earliest)) break;
      if (!_hasTasks(day)) continue;
      if (_isPerfectDay(day)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Longest streak ever achieved.
  int get bestStreak {
    final earliest = _earliestDay;
    final today = _dayOnly(DateTime.now());
    int best = 0;
    int running = 0;
    for (DateTime day = earliest;
        !day.isAfter(today);
        day = day.add(const Duration(days: 1))) {
      if (!_hasTasks(day)) continue;
      if (_isPerfectDay(day)) {
        running++;
        if (running > best) best = running;
      } else {
        running = 0;
      }
    }
    return best;
  }
}
