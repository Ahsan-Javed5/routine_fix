enum Repetition { none, daily, alternateDay, weekly, custom }

enum TaskPriority { high, medium, low }

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
  TaskPriority priority;
  bool isOneTimeCustom;
  TaskStatus status;
  DateTime? completedAt;
  Map<String, String> occurrenceStatus;
  DateTime createdAt; // Creation date
  DateTime? archivedAtDate; // Soft deletion date

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.taskDate,
    this.taskTime,
    this.repetition = Repetition.none,
    this.customDays = const [],
    this.durationMinutes = 30,
    this.priority = TaskPriority.medium,
    this.isOneTimeCustom = false,
    this.status = TaskStatus.pending,
    this.completedAt,
    Map<String, String>? occurrenceStatus,
    DateTime? createdAt,
    this.archivedAtDate,
  })  : occurrenceStatus = occurrenceStatus ?? {},
        createdAt = createdAt ?? DateTime.now();

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? taskDate,
    String? taskTime,
    Repetition? repetition,
    List<int>? customDays,
    int? durationMinutes,
    TaskPriority? priority,
    bool? isOneTimeCustom,
    TaskStatus? status,
    DateTime? completedAt,
    Map<String, String>? occurrenceStatus,
    DateTime? createdAt,
    DateTime? archivedAtDate,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      taskDate: taskDate ?? this.taskDate,
      taskTime: taskTime ?? this.taskTime,
      repetition: repetition ?? this.repetition,
      customDays: customDays ?? this.customDays,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      priority: priority ?? this.priority,
      isOneTimeCustom: isOneTimeCustom ?? this.isOneTimeCustom,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      occurrenceStatus: occurrenceStatus ?? Map.from(this.occurrenceStatus),
      createdAt: createdAt ?? this.createdAt,
      archivedAtDate: archivedAtDate ?? this.archivedAtDate,
    );
  }

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
        'createdAt': createdAt.toIso8601String(),
        'archivedAtDate': archivedAtDate?.toIso8601String(),
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        taskDate:
            json['taskDate'] != null ? DateTime.parse(json['taskDate']) : null,
        taskTime: json['taskTime'],
        repetition: Repetition.values.firstWhere(
          (e) => e.name == json['repetition'],
          orElse: () => Repetition.none,
        ),
        customDays: List<int>.from(json['customDays'] ?? []),
        durationMinutes: json['durationMinutes'] ?? 30,
        priority: TaskPriority.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => TaskPriority.medium,
        ),
        isOneTimeCustom: json['isOneTimeCustom'] ?? false,
        status: TaskStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TaskStatus.pending,
        ),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
        occurrenceStatus:
            Map<String, String>.from(json['occurrenceStatus'] ?? {}),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        archivedAtDate: json['archivedAtDate'] != null
            ? DateTime.parse(json['archivedAtDate'])
            : null,
      );
}
