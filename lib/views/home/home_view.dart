import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:routine_fix/views/home/widgets/date_strip.dart';
import 'package:routine_fix/views/home/widgets/discipline_ring_hero.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/reminder_controller.dart';
import '../../models/task_model.dart';
import '../../models/occasional_model.dart';
import '../../utils/app_theme.dart';

class HomeView extends GetView<TaskController> {
  const HomeView({super.key});

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final reminderController = Get.find<ReminderController>();

    return Obx(() {
      final tasks = controller.tasksForSelectedDate;
      final date = controller.selectedDate.value;

      final occasionalToday = reminderController.occasionalList
          .where((o) => _sameDay(o.date, date))
          .toList();

      final taskDoneCount = tasks
          .where((t) => controller.statusOn(t, date) == TaskStatus.done)
          .length;
      final occasionalDoneCount =
          occasionalToday.where((o) => o.isConfirmed == true).length;

      final totalCount = tasks.length + occasionalToday.length;
      final doneCount = taskDoneCount + occasionalDoneCount;
      final percent = totalCount == 0 ? 0.0 : doneCount / totalCount;

      final isEmpty = tasks.isEmpty && occasionalToday.isEmpty;

      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: DisciplineRingHero(
                  percent: percent,
                  done: doneCount,
                  total: totalCount,
                  currentStreak: controller.currentStreak,
                  bestStreak: controller.bestStreak)),
          SliverToBoxAdapter(child: DateStrip(controller: controller)),
          if (isEmpty)
            SliverFillRemaining(
                hasScrollBody: false, child: _EmptyDay(date: date))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < occasionalToday.length) {
                      final item = occasionalToday[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OccasionalCard(
                            item: item, controller: reminderController),
                      );
                    }
                    final task = tasks[index - occasionalToday.length];
                    final status = controller.statusOn(task, date);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TaskCard(
                          task: task,
                          status: status,
                          date: date,
                          controller: controller),
                    );
                  },
                  childCount: occasionalToday.length + tasks.length,
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _OccasionalCard extends StatelessWidget {
  final OccasionalModel item;
  final ReminderController controller;

  const _OccasionalCard({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final done = item.isConfirmed == true;
    final missed = item.isConfirmed == false;
    final today = DateTime.now();
    final isFuture = DateTime(item.date.year, item.date.month, item.date.day)
        .isAfter(DateTime(today.year, today.month, today.day));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(done ? 0.02 : 0.05),
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
          side: BorderSide(
            color: AppColors.amberGold.withOpacity(done ? 0.15 : 0.35),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isFuture ? null : () => controller.confirmDone(item, !done),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 62,
                  decoration: BoxDecoration(
                    color: AppColors.amberGold.withOpacity(done ? 0.35 : 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                                decoration:
                                    done ? TextDecoration.lineThrough : null,
                                color: done ? Colors.grey : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(item.description,
                            style: TextStyle(
                                fontSize: 12.5, color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _chip(Icons.event_note_rounded, 'Occasional',
                              AppColors.amberGold),
                          if (item.time != null)
                            _chip(Icons.schedule_rounded, item.time!,
                                Colors.blueGrey),
                          if (missed)
                            _chip(Icons.cancel_rounded, 'Missed',
                                AppColors.emberCoral),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Checkbox(
                  value: done,
                  shape: const CircleBorder(),
                  activeColor: AppColors.amberGold,
                  onChanged: isFuture
                      ? null
                      : (_) => controller.confirmDone(item, !done),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final TaskStatus status;
  final DateTime date;
  final TaskController controller;

  const _TaskCard({
    required this.task,
    required this.status,
    required this.date,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final done = status == TaskStatus.done;
    final today = DateTime.now();
    final isFuture = DateTime(date.year, date.month, date.day)
        .isAfter(DateTime(today.year, today.month, today.day));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(done ? 0.02 : 0.05),
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
          side: BorderSide(
            color: done
                ? Colors.grey.withOpacity(0.2)
                : priorityColor(task.priority).withOpacity(0.18),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isFuture ? null : () => controller.toggleComplete(task, date),
          onLongPress: () => _confirmDelete(context, task, date, controller),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 62,
                  decoration: BoxDecoration(
                    color: priorityColor(task.priority)
                        .withOpacity(done ? 0.35 : 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                          decoration: done ? TextDecoration.lineThrough : null,
                          color: done ? Colors.grey : null,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(task.description,
                            style: TextStyle(
                                fontSize: 12.5, color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _chip(
                              Icons.flag_rounded,
                              priorityLabel(task.priority),
                              priorityColor(task.priority)),
                          if (task.taskTime != null)
                            _chip(Icons.schedule_rounded, task.taskTime!,
                                Colors.blueGrey),
                          _chip(
                              Icons.repeat_rounded,
                              repetitionLabel(task.repetition),
                              Colors.blueGrey),
                          _chip(Icons.timer_outlined,
                              '${task.durationMinutes}m', Colors.blueGrey),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedScale(
                  scale: done ? 1.05 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: Checkbox(
                    value: done,
                    shape: const CircleBorder(),
                    activeColor: priorityColor(task.priority),
                    onChanged: isFuture
                        ? null
                        : (_) => controller.toggleComplete(task, date),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, TaskModel task, DateTime date,
    TaskController controller) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Stop Routine?'),
      content: const Text(
          'This will delete the task for today & future days. Past history will remain saved.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ),
  );
  if (confirm == true) {
    await controller.archiveTask(task, date);
  }
}

class _EmptyDay extends StatelessWidget {
  final DateTime date;
  const _EmptyDay({required this.date});

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.self_improvement_rounded, size: 56, color: iconColor),
            const SizedBox(height: 12),
            const Text('Nothing planned for this day',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Tap + below to add a priority task.',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
