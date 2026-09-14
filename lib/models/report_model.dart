class DailyReport {
  final DateTime date;
  final int total;
  final int completed;
  final int missed;
  final String? occasionalSummary;

  DailyReport({
    required this.date,
    required this.total,
    required this.completed,
    required this.missed,
    this.occasionalSummary,
  });

  double get completionPercent => total == 0 ? 0 : (completed / total) * 100;
}

class PriorityStats {
  final int total;
  final int completed;
  final int missed;

  PriorityStats({required this.total, required this.completed, required this.missed});

  double get completedPercent => total == 0 ? 0 : (completed / total) * 100;
  double get missedPercent => total == 0 ? 0 : (missed / total) * 100;
}

class PeriodReport {
  final DateTime start;
  final DateTime end;
  final PriorityStats high;
  final PriorityStats medium;
  final PriorityStats low;
  final List<Map<String, dynamic>> occasionalItems; // {title, date, status}

  PeriodReport({
    required this.start,
    required this.end,
    required this.high,
    required this.medium,
    required this.low,
    required this.occasionalItems,
  });
}
