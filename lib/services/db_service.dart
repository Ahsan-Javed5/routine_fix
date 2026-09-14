import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/task_model.dart';
import '../models/occasional_model.dart';

/// Lightweight local storage using JSON files in app documents directory.
/// Data size for this app (text only) stays in KBs-to-low-MBs even after years of use.
class DbService {
  static final DbService instance = DbService._internal();
  DbService._internal();

  File? _tasksFile;
  File? _occasionalFile;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _tasksFile = File('${dir.path}/tasks.json');
    _occasionalFile = File('${dir.path}/occasional.json');
    if (!await _tasksFile!.exists()) {
      await _tasksFile!.writeAsString(jsonEncode([]));
    }
    if (!await _occasionalFile!.exists()) {
      await _occasionalFile!.writeAsString(jsonEncode([]));
    }
  }

  // ---------------- Tasks ----------------
  Future<List<TaskModel>> loadTasks() async {
    final content = await _tasksFile!.readAsString();
    final List data = jsonDecode(content);
    return data.map((e) => TaskModel.fromJson(e)).toList();
  }

  Future<void> saveTasks(List<TaskModel> tasks) async {
    final data = tasks.map((t) => t.toJson()).toList();
    await _tasksFile!.writeAsString(jsonEncode(data));
  }

  // ---------------- Occasional Reminders ----------------
  Future<List<OccasionalModel>> loadOccasional() async {
    final content = await _occasionalFile!.readAsString();
    final List data = jsonDecode(content);
    return data.map((e) => OccasionalModel.fromJson(e)).toList();
  }

  Future<void> saveOccasional(List<OccasionalModel> items) async {
    final data = items.map((t) => t.toJson()).toList();
    await _occasionalFile!.writeAsString(jsonEncode(data));
  }
}
