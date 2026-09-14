import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import '../services/recurrence_service.dart';

class TaskController extends GetxController {
  final RxList<TaskModel> allTasks = <TaskModel>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }

  Future<void> loadTasks() async {
    allTasks.value = await DbService.instance.loadTasks();
  }

  /// Tasks that occur on the currently selected date.
  List<TaskModel> get tasksForSelectedDate {
    return allTasks
        .where((t) => RecurrenceService.occursOn(t, selectedDate.value))
        .toList()
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
  }

  String _key(DateTime date) => RecurrenceService.dateKey(date);

  TaskStatus statusOn(TaskModel task, DateTime date) {
    final key = _key(date);
    final raw = task.occurrenceStatus[key];
    if (raw == null) return TaskStatus.pending;
    return TaskStatus.values.firstWhere((e) => e.name == raw, orElse: () => TaskStatus.pending);
  }

  Future<void> addTask(TaskModel task) async {
    allTasks.add(task);
    await DbService.instance.saveTasks(allTasks);
    if (task.taskTime != null && task.taskDate != null) {
      await NotificationService.instance.scheduleTaskReminders(task, task.taskDate!);
    }
  }

  Future<void> toggleComplete(TaskModel task, DateTime date) async {
    final key = _key(date);
    final current = statusOn(task, date);
    task.occurrenceStatus[key] = current == TaskStatus.done ? TaskStatus.pending.name : TaskStatus.done.name;
    await DbService.instance.saveTasks(allTasks);
    allTasks.refresh();

    // If all of today's tasks are now done, cancel remaining nightly nudges.
    final today = DateTime.now();
    if (_key(date) == _key(today)) {
      final todays = tasksForSelectedDate;
      final allDone = todays.every((t) => statusOn(t, today) == TaskStatus.done);
      if (allDone && todays.isNotEmpty) {
        await NotificationService.instance.cancelRemainingNudges(today);
      }
    }
  }

  Future<void> deleteTask(String id) async {
    allTasks.removeWhere((t) => t.id == id);
    await DbService.instance.saveTasks(allTasks);
  }

  String newId() => const Uuid().v4();
}
