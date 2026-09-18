import '../models/task_model.dart';

class RecurrenceService {
  /// Returns true if [task] has an occurrence on [date].
  static bool occursOn(TaskModel task, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final created = DateTime(
      task.createdAt.year,
      task.createdAt.month,
      task.createdAt.day,
    );

    if (d.isBefore(created)) return false;

    if (task.archivedAtDate != null) {
      final archived = DateTime(
        task.archivedAtDate!.year,
        task.archivedAtDate!.month,
        task.archivedAtDate!.day,
      );
      if (!d.isBefore(archived)) return false;
    }

    // 3. One-Time / Non-repeating task logic
    if (task.isOneTimeCustom || task.repetition == Repetition.none) {
      if (task.taskDate == null) return false;
      final td = DateTime(
        task.taskDate!.year,
        task.taskDate!.month,
        task.taskDate!.day,
      );
      return td == d;
    }

    // 4. Repeating task start date logic
    final start = task.taskDate != null
        ? DateTime(
            task.taskDate!.year, task.taskDate!.month, task.taskDate!.day)
        : created;

    if (d.isBefore(start)) return false;

    switch (task.repetition) {
      case Repetition.daily:
        return true;
      case Repetition.alternateDay:
        final diff = d.difference(start).inDays;
        return diff % 2 == 0;
      case Repetition.weekly:
        return d.weekday == start.weekday;
      case Repetition.custom:
        return task.customDays.contains(d.weekday);
      default:
        return false;
    }
  }

  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
