import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/ai_routine_log.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import '../services/recurrence_service.dart';
import '../services/ai_service.dart';

class TaskController extends GetxController {
  final RxList<TaskModel> allTasks = <TaskModel>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  static const int dailyAiLimit = 10;
  final _storage = GetStorage();

  final RxInt _aiUsesToday = 0.obs;
  final Rx<DateTime?> _aiWindowStart = Rx<DateTime?>(null);
  final Rx<DateTime> _nowTick = DateTime.now().obs;
  final RxList<AiRoutineLog> aiHistory = <AiRoutineLog>[].obs;

  Timer? _tickTimer;

  @override
  void onInit() {
    super.onInit();
    loadTasks();
    _loadAiUsage();
    _loadAiHistory();
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _nowTick.value = DateTime.now();
      _checkWindowExpiry();
    });
  }

  @override
  void onClose() {
    _tickTimer?.cancel();
    super.onClose();
  }

  Future<void> loadTasks() async {
    allTasks.value = await DbService.instance.loadTasks();
  }

  List<TaskModel> get tasksForSelectedDate => tasksForDate(selectedDate.value);

  List<TaskModel> tasksForDate(DateTime date) {
    return allTasks.where((t) => RecurrenceService.occursOn(t, date)).toList()
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
  }

  int get todayTaskCount => tasksForDate(DateTime.now()).length;

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

  Future<void> archiveTask(TaskModel task, DateTime currentDate) async {
    final updatedTask = task.copyWith(archivedAtDate: currentDate);
    final index = allTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      allTasks[index] = updatedTask;
      await DbService.instance.saveTasks(allTasks);
      allTasks.refresh();
    }
  }

  Future<void> restoreTasks(List<TaskModel> tasks) async {
    allTasks.value = tasks;
    await DbService.instance.saveTasks(allTasks);
  }

  String newId() => const Uuid().v4();

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _earliestDay {
    if (allTasks.isEmpty) return _dayOnly(DateTime.now());
    final earliest = allTasks
        .map((t) => t.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return _dayOnly(earliest);
  }

  bool _isPerfectDay(DateTime day) {
    final dayTasks = tasksForDate(day);
    if (dayTasks.isEmpty) return true;
    return dayTasks.every((t) => statusOn(t, day) == TaskStatus.done);
  }

  bool _hasTasks(DateTime day) => tasksForDate(day).isNotEmpty;

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

  void _loadAiUsage() {
    final count = _storage.read('ai_usage_count') as int? ?? 0;
    final startStr = _storage.read('ai_usage_window_start') as String?;
    final start = startStr != null ? DateTime.tryParse(startStr) : null;
    _aiUsesToday.value = count;
    _aiWindowStart.value = start;
    _checkWindowExpiry();
  }

  void _checkWindowExpiry() {
    final start = _aiWindowStart.value;
    if (start != null &&
        DateTime.now().difference(start) >= const Duration(hours: 24)) {
      _aiUsesToday.value = 0;
      _aiWindowStart.value = null;
      _storage.remove('ai_usage_count');
      _storage.remove('ai_usage_window_start');
    }
  }

  int get aiUsesToday {
    _checkWindowExpiry();
    return _aiUsesToday.value;
  }

  bool get canUseAiToday => aiUsesToday < dailyAiLimit;

  String get aiLimitResetLabel {
    final start = _aiWindowStart.value;
    if (start == null) return '';
    final resetAt = start.add(const Duration(hours: 24));
    final diff = resetAt.difference(_nowTick.value);
    if (diff.isNegative) return 'Resets shortly';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h <= 0) return 'Resets in ${m}m';
    return 'Resets in ${h}h ${m}m';
  }

  void _incrementAiUsage() {
    _checkWindowExpiry();
    if (_aiWindowStart.value == null) {
      _aiWindowStart.value = DateTime.now();
      _storage.write(
          'ai_usage_window_start', _aiWindowStart.value!.toIso8601String());
    }
    _aiUsesToday.value += 1;
    _storage.write('ai_usage_count', _aiUsesToday.value);
  }

  Future<List<Map<String, dynamic>>> generateAiSuggestions(String goal,
      {List<String>? avoidTitles}) async {
    if (!canUseAiToday) {
      throw Exception(
          'Daily AI limit reached ($dailyAiLimit/24h). $aiLimitResetLabel');
    }
    final suggestions = await AiService.instance
        .generateRoutine(goal, avoidTitles: avoidTitles);
    _incrementAiUsage();
    return suggestions;
  }

  Future<void> addAiTasks(String goal, List<Map<String, dynamic>> all,
      List<Map<String, dynamic>> picked) async {
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
    _logAiHistory(
        goal, all.map((e) => e['title'].toString()).toList(), picked.length);
  }

  void _loadAiHistory() {
    final raw = _storage.read('ai_history') as List<dynamic>? ?? [];
    aiHistory.value = raw
        .map((e) => AiRoutineLog.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        .reversed
        .toList();
  }

  Future<void> updateTask(TaskModel updated) async {
    final index = allTasks.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      allTasks[index] = updated;
      await DbService.instance.saveTasks(allTasks);
      allTasks.refresh();
      if (updated.taskTime != null && updated.taskDate != null) {
        await NotificationService.instance
            .scheduleTaskReminders(updated, updated.taskDate!);
      }
    }
  }

  void _logAiHistory(String goal, List<String> titles, int addedCount) {
    final log = AiRoutineLog(
      id: newId(),
      goal: goal,
      createdAt: DateTime.now(),
      taskTitles: titles,
      addedCount: addedCount,
    );
    aiHistory.insert(0, log);
    if (aiHistory.length > 20) aiHistory.removeRange(20, aiHistory.length);
    _storage.write(
        'ai_history', aiHistory.reversed.map((e) => e.toJson()).toList());
  }
}
