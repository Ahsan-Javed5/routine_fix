import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../models/task_model.dart';
import '../../utils/app_theme.dart';

class AddTaskView extends GetView<TaskController> {
  const AddTaskView({super.key});

  @override
  Widget build(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final Rx<DateTime?> pickedDate = Rx<DateTime?>(null);
    final Rx<TimeOfDay?> pickedTime = Rx<TimeOfDay?>(null);
    final Rx<Repetition> repetition = Repetition.none.obs;
    final Rx<Priority> priority = Priority.medium.obs;
    final RxBool isOneTime = false.obs;
    final RxList<int> customDays = <int>[].obs;
    final RxInt duration = 30.obs;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _sectionCard(
            title: 'What\'s the task?',
            icon: Icons.edit_note_rounded,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
          _sectionCard(
            title: 'When',
            icon: Icons.event_rounded,
            children: [
              Obx(() => _pickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: pickedDate.value == null ? 'Task date (optional)' : pickedDate.value!.toLocal().toString().split(' ')[0],
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (d != null) pickedDate.value = d;
                    },
                  )),
              const SizedBox(height: 8),
              Obx(() => _pickerTile(
                    icon: Icons.access_time_rounded,
                    label: pickedTime.value == null ? 'Task time (optional)' : pickedTime.value!.format(context),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (t != null) pickedTime.value = t;
                    },
                  )),
            ],
          ),
          _sectionCard(
            title: 'Repetition',
            icon: Icons.repeat_rounded,
            children: [
              Obx(() => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: Repetition.values.map((r) {
                      return ChoiceChip(
                        label: Text(_repLabel(r)),
                        selected: repetition.value == r,
                        onSelected: (_) => repetition.value = r,
                      );
                    }).toList(),
                  )),
              Obx(() {
                if (repetition.value != Repetition.custom) return const SizedBox.shrink();
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 6,
                    children: List.generate(7, (i) {
                      final dayNum = i + 1;
                      return FilterChip(
                        label: Text(days[i]),
                        selected: customDays.contains(dayNum),
                        onSelected: (sel) => sel ? customDays.add(dayNum) : customDays.remove(dayNum),
                      );
                    }),
                  ),
                );
              }),
              const SizedBox(height: 4),
              Obx(() => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('One-time task (specific day only)'),
                    value: isOneTime.value,
                    onChanged: (v) => isOneTime.value = v ?? false,
                  )),
            ],
          ),
          _sectionCard(
            title: 'Duration',
            icon: Icons.timer_outlined,
            children: [
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => duration.value = (duration.value - 5).clamp(5, 480),
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Text('${duration.value} min', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton.filledTonal(
                        onPressed: () => duration.value = (duration.value + 5).clamp(5, 480),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  )),
            ],
          ),
          _sectionCard(
            title: 'Priority',
            icon: Icons.flag_rounded,
            children: [
              Obx(() => SegmentedButton<Priority>(
                    segments: Priority.values.map((p) {
                      return ButtonSegment(
                        value: p,
                        label: Text(priorityLabel(p)),
                        icon: Icon(Icons.circle, size: 12, color: priorityColor(p)),
                      );
                    }).toList(),
                    selected: {priority.value},
                    onSelectionChanged: (s) => priority.value = s.first,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) {
                  Get.snackbar('Missing title', 'Please enter a task title');
                  return;
                }
                final task = TaskModel(
                  id: controller.newId(),
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  taskDate: pickedDate.value,
                  taskTime: pickedTime.value != null
                      ? '${pickedTime.value!.hour.toString().padLeft(2, '0')}:${pickedTime.value!.minute.toString().padLeft(2, '0')}'
                      : null,
                  repetition: isOneTime.value ? Repetition.none : repetition.value,
                  customDays: customDays.toList(),
                  durationMinutes: duration.value,
                  priority: priority.value,
                  isOneTimeCustom: isOneTime.value,
                );
                await controller.addTask(task);
                Get.back();
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save Task', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  String _repLabel(Repetition r) => repetitionLabel(r);

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.signalTeal),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _pickerTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
