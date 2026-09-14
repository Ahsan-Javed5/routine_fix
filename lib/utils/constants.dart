import 'package:flutter/material.dart';
import '../models/task_model.dart';

Color priorityColor(Priority p) {
  switch (p) {
    case Priority.high:
      return Colors.redAccent;
    case Priority.medium:
      return Colors.orangeAccent;
    case Priority.low:
      return Colors.green;
  }
}

String priorityLabel(Priority p) {
  switch (p) {
    case Priority.high:
      return 'High';
    case Priority.medium:
      return 'Medium';
    case Priority.low:
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
