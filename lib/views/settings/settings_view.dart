import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/reminder_controller.dart';
import '../../models/task_model.dart';
import '../../models/occasional_model.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _busy = false;

  void _feedback(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError ? AppColors.emberCoral : AppColors.inkNavy,
      colorText: Colors.white,
      titleText: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      messageText: Text(message,
          style: const TextStyle(color: Colors.white, fontSize: 13)),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
      isDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _SectionLabel('Appearance'),
        Card(
          child: Obx(() => Column(
                children: ThemeModeOption.values.map((mode) {
                  return RadioListTile<ThemeModeOption>(
                    value: mode,
                    groupValue: themeCtrl.themeMode.value,
                    onChanged: (v) => themeCtrl.setMode(v!),
                    title: Text(mode.label),
                    secondary: Icon(
                      mode == ThemeModeOption.light
                          ? Icons.light_mode_rounded
                          : mode == ThemeModeOption.dark
                              ? Icons.dark_mode_rounded
                              : Icons.brightness_auto_rounded,
                    ),
                  );
                }).toList(),
              )),
        ),
        const SizedBox(height: 20),
        _SectionLabel('Notifications'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_active_rounded,
                color: AppColors.signalTeal),
            title: const Text('Recheck notification permissions'),
            subtitle: const Text(
                'If reminders have stopped arriving, tap to re-request permission'),
            onTap: () async {
              await NotificationService.instance.init();
              _feedback('Checked', 'Notification permissions re-verified');
            },
          ),
        ),
        const SizedBox(height: 20),
        _SectionLabel('Backup'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file_rounded,
                    color: AppColors.signalTeal),
                title: const Text('Export backup'),
                subtitle: const Text(
                    'Save all tasks & occasional reminders as a JSON file'),
                trailing: _busy ? const _Spinner() : null,
                onTap: _busy ? null : () => _exportBackup(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.download_rounded,
                    color: AppColors.amberGold),
                title: const Text('Import backup'),
                subtitle: const Text('Restore from a previously exported file'),
                trailing: _busy ? const _Spinner() : null,
                onTap: _busy ? null : () => _importBackup(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionLabel('Data'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_forever_rounded,
                color: AppColors.emberCoral),
            title: const Text('Reset all app data'),
            subtitle: const Text('Deletes all tasks, reminders, and reports'),
            onTap: () => _confirmReset(context),
          ),
        ),
        const SizedBox(height: 20),
        _SectionLabel('About'),
        Card(
          child: Column(
            children: const [
              ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('RoutineFix'),
                  subtitle: Text('Version 1.0.0')),
              ListTile(
                leading: Icon(Icons.favorite_border_rounded),
                title: Text('Built to help you stay disciplined'),
                subtitle: Text(
                    'For students, professionals, and anyone building better daily habits.'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    setState(() => _busy = true);
    try {
      final taskCtrl = Get.find<TaskController>();
      final reminderCtrl = Get.find<ReminderController>();

      final backup = {
        'app': 'RoutineFix',
        'exportedAt': DateTime.now().toIso8601String(),
        'tasks': taskCtrl.allTasks.map((t) => t.toJson()).toList(),
        'occasional':
            reminderCtrl.occasionalList.map((o) => o.toJson()).toList(),
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);

      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/routinefix_backup_$stamp.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles([XFile(file.path)],
          text: 'RoutineFix backup — ${taskCtrl.allTasks.length} tasks, '
              '${reminderCtrl.occasionalList.length} occasional reminders');
    } catch (e) {
      _feedback('Export failed', 'Could not create backup: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      setState(() => _busy = true);
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final tasksJson =
          (data['tasks'] as List? ?? []).cast<Map<String, dynamic>>();
      final occasionalJson =
          (data['occasional'] as List? ?? []).cast<Map<String, dynamic>>();

      final tasks = tasksJson.map((e) => TaskModel.fromJson(e)).toList();
      final occasional =
          occasionalJson.map((e) => OccasionalModel.fromJson(e)).toList();

      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore backup?'),
          content: Text(
              'This will replace all current data with ${tasks.length} tasks '
              'and ${occasional.length} occasional reminders from the backup. '
              'This cannot be undone.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amberGold),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      await Get.find<TaskController>().restoreTasks(tasks);
      await Get.find<ReminderController>().restoreItems(occasional);
      _feedback('Restored',
          '${tasks.length} tasks and ${occasional.length} reminders restored');
    } catch (e) {
      _feedback('Import failed', 'Could not read backup file: $e',
          isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _confirmReset(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
            'This will permanently delete all your tasks, occasional reminders, and reports. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.emberCoral),
            onPressed: () async {
              final taskCtrl = Get.find<TaskController>();
              final reminderCtrl = Get.find<ReminderController>();
              for (final t in taskCtrl.allTasks.toList()) {
                await taskCtrl.deleteTask(t.id);
              }
              for (final o in reminderCtrl.occasionalList.toList()) {
                await reminderCtrl.deleteReminder(o.id);
              }
              Get.back();
              _feedback('Done', 'All data has been reset');
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
    );
  }
}
