import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/task_controller.dart';
import '../../../utils/app_theme.dart';

void showAiRoutineSheet(BuildContext context) {
  final goalCtrl = TextEditingController();
  final taskController = Get.find<TaskController>();

  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('✨ AI Routine Generator'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              '${taskController.aiUsesToday}/${TaskController.dailyAiLimit} used today',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 8),
          TextField(
            controller: goalCtrl,
            decoration: const InputDecoration(
              labelText: 'Your goal',
              hintText: 'e.g. better sleep, exam prep',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final goal = goalCtrl.text.trim();
            if (goal.isEmpty) return;
            Get.back();
            _runGeneration(context, taskController, goal);
          },
          child: const Text('Generate'),
        ),
      ],
    ),
  );
}

Future<void> _runGeneration(
    BuildContext context, TaskController controller, String goal) async {
  Get.dialog(
    const AlertDialog(
      content: Row(children: [
        CircularProgressIndicator(),
        SizedBox(width: 16),
        Text('AI is thinking...'),
      ]),
    ),
    barrierDismissible: false,
  );

  try {
    final suggestions = await controller.generateAiSuggestions(goal);
    Get.back();
    _showPreview(context, controller, suggestions);
  } catch (e) {
    Get.back();
    Get.snackbar('AI Error', e.toString(),
        backgroundColor: AppColors.emberCoral, colorText: Colors.white);
  }
}

void _showPreview(BuildContext context, TaskController controller,
    List<Map<String, dynamic>> suggestions) {
  final selected = List<bool>.filled(suggestions.length, true);

  Get.dialog(
    StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Review suggested tasks'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(suggestions.length, (i) {
                final t = suggestions[i];
                return CheckboxListTile(
                  value: selected[i],
                  onChanged: (v) => setState(() => selected[i] = v ?? false),
                  title: Text(t['title']),
                  subtitle: Text(
                      '${t['description']}${t['time'] != null ? ' • ${t['time']}' : ''}'),
                );
              }),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final picked = <Map<String, dynamic>>[
                  for (int i = 0; i < suggestions.length; i++)
                    if (selected[i]) suggestions[i],
                ];
                Get.back();
                await controller.addAiTasks(picked);
                Get.snackbar(
                    'Added', '${picked.length} tasks added to your routine');
              },
              child: const Text('Add Selected'),
            ),
          ],
        );
      },
    ),
  );
}
