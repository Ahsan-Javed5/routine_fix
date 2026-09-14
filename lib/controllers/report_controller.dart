import 'package:get/get.dart';
import 'package:collection/collection.dart';
import '../models/task_model.dart';
import '../models/report_model.dart';
import '../models/occasional_model.dart';
import '../services/recurrence_service.dart';
import 'task_controller.dart';
import 'reminder_controller.dart';

class ReportController extends GetxController {
  final TaskController taskController = Get.find<TaskController>();
  final ReminderController reminderController = Get.find<ReminderController>();

  DailyReport dailyReportFor(DateTime date) {
    final tasks = taskController.allTasks
        .where((t) => RecurrenceService.occursOn(t, date))
        .toList();
    int completed = 0;
    int missed = 0;
    for (final t in tasks) {
      final status = taskController.statusOn(t, date);
      if (status == TaskStatus.done) {
        completed++;
      } else if (date.isBefore(DateTime.now())) {
        missed++;
      }
    }

    final occasional = reminderController.occasionalList.firstWhereOrNull(
      (o) => RecurrenceService.dateKey(o.date) == RecurrenceService.dateKey(date),
    );
    String? occSummary;
    if (occasional != null) {
      final status = occasional.isConfirmed == null
          ? 'awaiting confirmation'
          : (occasional.isConfirmed! ? 'Completed' : 'Not Completed');
      occSummary = '${occasional.title} - $status';
    }

    return DailyReport(
      date: date,
      total: tasks.length,
      completed: completed,
      missed: missed,
      occasionalSummary: occSummary,
    );
  }

  PeriodReport periodReport(DateTime start, DateTime end) {
    final Map<Priority, List<TaskStatus>> byPriority = {
      Priority.high: [],
      Priority.medium: [],
      Priority.low: [],
    };

    for (DateTime d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      final tasks = taskController.allTasks.where((t) => RecurrenceService.occursOn(t, d));
      for (final t in tasks) {
        byPriority[t.priority]!.add(taskController.statusOn(t, d));
      }
    }

    PriorityStats buildStats(List<TaskStatus> list) {
      final total = list.length;
      final completed = list.where((s) => s == TaskStatus.done).length;
      final missed = total - completed;
      return PriorityStats(total: total, completed: completed, missed: missed);
    }

    final occItems = reminderController.occasionalList
        .where((o) => !o.date.isBefore(start) && !o.date.isAfter(end))
        .map((o) => {
              'title': o.title,
              'date': o.date,
              'status': o.isConfirmed == null
                  ? 'Awaiting confirmation'
                  : (o.isConfirmed! ? 'Completed' : 'Not Completed'),
            })
        .toList();

    return PeriodReport(
      start: start,
      end: end,
      high: buildStats(byPriority[Priority.high]!),
      medium: buildStats(byPriority[Priority.medium]!),
      low: buildStats(byPriority[Priority.low]!),
      occasionalItems: occItems,
    );
  }

  PeriodReport weeklyReport(DateTime anyDayInWeek) {
    final start = anyDayInWeek.subtract(Duration(days: anyDayInWeek.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return periodReport(start, end);
  }

  PeriodReport monthlyReport(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    return periodReport(start, end);
  }
}
