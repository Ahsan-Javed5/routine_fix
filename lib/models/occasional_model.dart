class OccasionalModel {
  String id;
  String title;
  String description;
  DateTime date;
  String? time; // "HH:mm"
  bool? isConfirmed; // null = not yet responded
  DateTime? confirmedAt;

  OccasionalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.time,
    this.isConfirmed,
    this.confirmedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'time': time,
        'isConfirmed': isConfirmed,
        'confirmedAt': confirmedAt?.toIso8601String(),
      };

  factory OccasionalModel.fromJson(Map<String, dynamic> json) => OccasionalModel(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        date: DateTime.parse(json['date']),
        time: json['time'],
        isConfirmed: json['isConfirmed'],
        confirmedAt: json['confirmedAt'] != null ? DateTime.parse(json['confirmedAt']) : null,
      );
}
