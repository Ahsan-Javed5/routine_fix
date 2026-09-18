class AiRoutineLog {
  final String id;
  final String goal;
  final DateTime createdAt;
  final List<String> taskTitles;
  final int addedCount;

  AiRoutineLog({
    required this.id,
    required this.goal,
    required this.createdAt,
    required this.taskTitles,
    required this.addedCount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'goal': goal,
        'createdAt': createdAt.toIso8601String(),
        'taskTitles': taskTitles,
        'addedCount': addedCount,
      };

  factory AiRoutineLog.fromJson(Map<String, dynamic> json) => AiRoutineLog(
        id: json['id'],
        goal: json['goal'],
        createdAt: DateTime.parse(json['createdAt']),
        taskTitles: List<String>.from(json['taskTitles'] ?? []),
        addedCount: json['addedCount'] ?? 0,
      );
}
