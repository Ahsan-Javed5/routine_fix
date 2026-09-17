import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/reminder_controller.dart';
import '../../models/occasional_model.dart';
import '../../utils/app_theme.dart';

class OccasionalView extends GetView<ReminderController> {
  const OccasionalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.occasionalList.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      if (items.isEmpty) {
        return _EmptyState(onAdd: () => showAddOccasionalDialog(context));
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final needsConfirmation = item.isConfirmed == null &&
              item.date.isBefore(DateTime.now().add(const Duration(hours: 1)));
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.amberGold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 2),
                        if (item.description.isNotEmpty)
                          Text(item.description,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                          '${item.date.toLocal().toString().split(' ')[0]}'
                          '${item.time != null ? " • ${item.time}" : ""}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  if (needsConfirmation)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: AppColors.sageGreen),
                          onPressed: () => controller.confirmDone(item, true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel,
                              color: AppColors.emberCoral),
                          onPressed: () => controller.confirmDone(item, false),
                        ),
                      ],
                    )
                  else
                    _StatusPill(item: item),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

class _StatusPill extends StatelessWidget {
  final OccasionalModel item;
  const _StatusPill({required this.item});

  @override
  Widget build(BuildContext context) {
    final label = item.isConfirmed == null
        ? 'Upcoming'
        : (item.isConfirmed! ? 'Done' : 'Missed');
    final color = item.isConfirmed == null
        ? Colors.blueGrey
        : (item.isConfirmed! ? AppColors.sageGreen : AppColors.emberCoral);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available_rounded,
                size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No occasional reminders yet',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text(
              'Add a one-off event — like a family visit or appointment — and confirm later whether you went.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Public so it can be triggered from the shared expandable FAB in MainNavView.
void showAddOccasionalDialog(BuildContext context) {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final Rx<DateTime?> date = Rx<DateTime?>(null);
  final Rx<TimeOfDay?> time = Rx<TimeOfDay?>(null);
  final RxBool dateMissing = false.obs;
  final RxBool titleMissing = false.obs;

  Get.dialog(
    StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New Occasional Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() => TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        errorText:
                            titleMissing.value ? 'Title is required' : null,
                      ),
                    )),
                const SizedBox(height: 8),
                TextField(
                    controller: descCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Description')),
                Obx(() => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.calendar_today_rounded,
                          color: dateMissing.value ? Colors.redAccent : null),
                      title: Text(
                        date.value == null
                            ? 'Pick Date (required)'
                            : date.value!.toLocal().toString().split(' ')[0],
                        style: TextStyle(
                            color: dateMissing.value ? Colors.redAccent : null),
                      ),
                      subtitle: dateMissing.value
                          ? const Text('Please select a date',
                              style: TextStyle(
                                  color: Colors.redAccent, fontSize: 12))
                          : null,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (d != null) {
                          date.value = d;
                          dateMissing.value = false;
                        }
                      },
                    )),
                Obx(() => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time_rounded),
                      title: Text(time.value == null
                          ? 'Pick Time (optional)'
                          : time.value!.format(context)),
                      onTap: () async {
                        final t = await showTimePicker(
                            context: context, initialTime: TimeOfDay.now());
                        if (t != null) time.value = t;
                      },
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                titleMissing.value = titleCtrl.text.trim().isEmpty;
                dateMissing.value = date.value == null;
                if (titleMissing.value || dateMissing.value) return;

                final item = OccasionalModel(
                  id: Get.find<ReminderController>().newId(),
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  date: date.value!,
                  time: time.value != null
                      ? '${time.value!.hour.toString().padLeft(2, '0')}:${time.value!.minute.toString().padLeft(2, '0')}'
                      : null,
                );
                await Get.find<ReminderController>().addReminder(item);
                Get.back();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}
