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
      final all = controller.occasionalList.toList();
      if (all.isEmpty) {
        return _EmptyState(onAdd: () => showAddOccasionalDialog(context));
      }

      final upcoming = all.where((e) => e.isConfirmed == null).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final history = all.where((e) => e.isConfirmed != null).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          if (upcoming.isNotEmpty) ...[
            _SectionLabel('Upcoming'),
            const SizedBox(height: 8),
            ...upcoming.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReminderCard(item: item),
                )),
            const SizedBox(height: 12),
          ],
          if (history.isNotEmpty) ...[
            _SectionLabel('History'),
            const SizedBox(height: 8),
            ...history.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReminderCard(item: item),
                )),
          ],
        ],
      );
    });
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey));
  }
}

class _ReminderCard extends StatelessWidget {
  final OccasionalModel item;
  const _ReminderCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReminderController>();
    final needsConfirmation = item.isConfirmed == null &&
        item.date.isBefore(DateTime.now().add(const Duration(hours: 1)));
    final statusColor = item.isConfirmed == null
        ? AppColors.amberGold
        : (item.isConfirmed! ? AppColors.sageGreen : AppColors.emberCoral);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showAddOccasionalDialog(context, existing: item),
          onLongPress: () => _confirmDelete(context, item, controller),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5,
                      height: 54,
                      decoration: BoxDecoration(
                        color: statusColor,
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
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(item.description,
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            '${item.date.toLocal().toString().split(' ')[0]}'
                            '${item.time != null ? " • ${item.time}" : ""}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    if (!needsConfirmation) _StatusPill(item: item),
                  ],
                ),
                if (needsConfirmation) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.sageGreen,
                            side: BorderSide(
                                color: AppColors.sageGreen.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => controller.confirmDone(item, true),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Attended'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.emberCoral,
                            side: BorderSide(
                                color: AppColors.emberCoral.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => controller.confirmDone(item, false),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Missed'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, OccasionalModel item,
    ReminderController controller) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete reminder?'),
      content: Text('"${item.title}" will be permanently removed.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.emberCoral),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirm == true) {
    await controller.deleteReminder(item.id);
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
            FilledButton.icon(
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.signalTeal),
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
/// Pass [existing] to edit an item instead of creating a new one.
void showAddOccasionalDialog(BuildContext context,
    {OccasionalModel? existing}) {
  final isEdit = existing != null;
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');
  final Rx<DateTime?> date = Rx<DateTime?>(existing?.date);
  final Rx<TimeOfDay?> time = Rx<TimeOfDay?>(existing?.time != null
      ? TimeOfDay(
          hour: int.parse(existing!.time!.split(':')[0]),
          minute: int.parse(existing.time!.split(':')[1]),
        )
      : null);
  final RxBool dateMissing = false.obs;
  final RxBool titleMissing = false.obs;

  Get.dialog(
    StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          title: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.inkNavy,
                  AppColors.inkNavy.withOpacity(0.88)
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.amberGold.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      isEdit
                          ? Icons.edit_calendar_rounded
                          : Icons.event_note_rounded,
                      color: AppColors.amberGold,
                      size: 20),
                ),
                const SizedBox(width: 12),
                Text(isEdit ? 'Edit Reminder' : 'New Occasional Reminder',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
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
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    )),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                Obx(() => _pickerTile(
                      icon: Icons.calendar_today_rounded,
                      label: date.value == null
                          ? 'Pick Date (required)'
                          : date.value!.toLocal().toString().split(' ')[0],
                      highlight: dateMissing.value,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: date.value ?? DateTime.now(),
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 1)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (d != null) {
                          date.value = d;
                          dateMissing.value = false;
                        }
                      },
                    )),
                const SizedBox(height: 8),
                Obx(() => _pickerTile(
                      icon: Icons.access_time_rounded,
                      label: time.value == null
                          ? 'Pick Time (optional)'
                          : time.value!.format(context),
                      onTap: () async {
                        final t = await showTimePicker(
                            context: context,
                            initialTime: time.value ?? TimeOfDay.now());
                        if (t != null) time.value = t;
                      },
                    )),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
                onPressed: () => Get.back(), child: const Text('Cancel')),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.signalTeal),
              onPressed: () async {
                titleMissing.value = titleCtrl.text.trim().isEmpty;
                dateMissing.value = date.value == null;
                if (titleMissing.value || dateMissing.value) return;

                final timeStr = time.value != null
                    ? '${time.value!.hour.toString().padLeft(2, '0')}:${time.value!.minute.toString().padLeft(2, '0')}'
                    : null;
                final controller = Get.find<ReminderController>();

                if (isEdit) {
                  await controller.updateReminder(
                    existing,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    date: date.value!,
                    time: timeStr,
                  );
                } else {
                  final item = OccasionalModel(
                    id: controller.newId(),
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    date: date.value!,
                    time: timeStr,
                  );
                  await controller.addReminder(item);
                }
                Get.back();
              },
              child: Text(isEdit ? 'Update' : 'Save'),
            ),
          ],
        );
      },
    ),
  );
}

Widget _pickerTile({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  bool highlight = false,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
            color: highlight ? Colors.redAccent : Colors.grey.shade300,
            width: highlight ? 1.4 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 18, color: highlight ? Colors.redAccent : Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: highlight
                      ? const TextStyle(color: Colors.redAccent)
                      : null)),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: highlight ? Colors.redAccent : Colors.grey),
        ],
      ),
    ),
  );
}
