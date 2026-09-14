enum Repetition { none, daily, alternateDay, weekly, custom }

enum Priority { high, medium, low }

enum TaskStatus { pending, done, missed }

class TaskModel {
  String id;
  String title;
  String description;
  DateTime? taskDate; // optional base date
  String? taskTime; // stored as "HH:mm", optional
  Repetition repetition;
  List<int> customDays; // 1=Mon ... 7=Sun, used if repetition == custom
  int durationMinutes;
  Priority priority;
  bool isOneTimeCustom;
  TaskStatus status;
  DateTime? completedAt;
  // Per-date completion map for recurring tasks: "yyyy-MM-dd" -> status
  Map<String, String> occurrenceStatus;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.taskDate,
    this.taskTime,
    this.repetition = Repetition.none,
    this.customDays = const [],
    this.durationMinutes = 30,
    this.priority = Priority.medium,
    this.isOneTimeCustom = false,
    this.status = TaskStatus.pending,
    this.completedAt,
    Map<String, String>? occurrenceStatus,
  }) : occurrenceStatus = occurrenceStatus ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'taskDate': taskDate?.toIso8601String(),
        'taskTime': taskTime,
        'repetition': repetition.name,
        'customDays': customDays,
        'durationMinutes': durationMinutes,
        'priority': priority.name,
        'isOneTimeCustom': isOneTimeCustom,
        'status': status.name,
        'completedAt': completedAt?.toIso8601String(),
        'occurrenceStatus': occurrenceStatus,
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        taskDate: json['taskDate'] != null ? DateTime.parse(json['taskDate']) : null,
        taskTime: json['taskTime'],
        repetition: Repetition.values.firstWhere(
          (e) => e.name == json['repetition'],
          orElse: () => Repetition.none,
        ),
        customDays: List<int>.from(json['customDays'] ?? []),
        durationMinutes: json['durationMinutes'] ?? 30,
        priority: Priority.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => Priority.medium,
        ),
        isOneTimeCustom: json['isOneTimeCustom'] ?? false,
        status: TaskStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TaskStatus.pending,
        ),
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
        occurrenceStatus: Map<String, String>.from(json['occurrenceStatus'] ?? {}),
      );
}
