import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/reminder_controller.dart';
import '../../utils/app_theme.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

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
        _SectionLabel('Data'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: AppColors.emberCoral),
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
              ListTile(leading: Icon(Icons.info_outline_rounded), title: Text('RoutineFix'), subtitle: Text('Version 1.0.0')),
              ListTile(
                leading: Icon(Icons.favorite_border_rounded),
                title: Text('Built to help you stay disciplined'),
                subtitle: Text('For students, professionals, and anyone building better daily habits.'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmReset(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text('This will permanently delete all your tasks, occasional reminders, and reports. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emberCoral),
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
              Get.snackbar('Done', 'All data has been reset');
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
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
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
    );
  }
}
