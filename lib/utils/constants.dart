import 'package:flutter/material.dart';
import '../models/task_model.dart';

Color priorityColor(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:
      return Colors.redAccent;
    case TaskPriority.medium:
      return Colors.orangeAccent;
    case TaskPriority.low:
      return Colors.green;
  }
}

String priorityLabel(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:
      return 'High';
    case TaskPriority.medium:
      return 'Medium';
    case TaskPriority.low:
      return 'Low';
  }
}

String repetitionLabel(Repetition r) {
  switch (r) {
    case Repetition.none:
      return 'One-time';
    case Repetition.daily:
      return 'Daily';
    case Repetition.alternateDay:
      return 'Alternate Day';
    case Repetition.weekly:
      return 'Weekly';
    case Repetition.custom:
      return 'Custom Days';
  }
}
