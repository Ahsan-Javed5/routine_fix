import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../controllers/task_controller.dart';
import '../../models/task_model.dart';
import '../../utils/app_theme.dart';

class HomeView extends GetView<TaskController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tasks = controller.tasksForSelectedDate;
      final date = controller.selectedDate.value;
      final doneCount = tasks.where((t) => controller.statusOn(t, date) == TaskStatus.done).length;
      final percent = tasks.isEmpty ? 0.0 : doneCount / tasks.length;

      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _DisciplineRingHero(percent: percent, done: doneCount, total: tasks.length)),
          SliverToBoxAdapter(child: _DateStrip(controller: controller)),
          if (tasks.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _EmptyDay(date: date))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = tasks[index];
                    final status = controller.statusOn(task, date);
                    return _TaskCard(task: task, status: status, date: date, controller: controller);
                  },
                  childCount: tasks.length,
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _DisciplineRingHero extends StatelessWidget {
  final double percent;
  final int done;
  final int total;
  const _DisciplineRingHero({required this.percent, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal : AppColors.inkNavy,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: CustomPaint(
              painter: _RingPainter(percent: percent),
              child: Center(
                child: Text(
                  '${(percent * 100).round()}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Discipline Ring', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  total == 0 ? 'No tasks planned' : '$done of $total tasks done',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  percent >= 1 && total > 0
                      ? 'Perfect day — keep the streak alive!'
                      : total == 0
                          ? 'Add a task to get started.'
                          : 'Keep going, you\'ve got this.',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  _RingPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = AppColors.signalTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * math.pi * percent;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.percent != percent;
}

class _DateStrip extends StatelessWidget {
  final TaskController controller;
  const _DateStrip({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedDate.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => controller.selectedDate.value = selected.subtract(const Duration(days: 1)),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selected,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) controller.selectedDate.value = picked;
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Text(
                        _relativeLabel(selected),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        DateFormat('EEEE, MMM d').format(selected),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => controller.selectedDate.value = selected.add(const Duration(days: 1)),
            ),
          ],
        ),
      );
    });
  }

  String _relativeLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('MMM d, yyyy').format(d);
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final TaskStatus status;
  final DateTime date;
  final TaskController controller;
  const _TaskCard({required this.task, required this.status, required this.date, required this.controller});

  @override
  Widget build(BuildContext context) {
    final done = status == TaskStatus.done;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => controller.toggleComplete(task, date),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 62,
                decoration: BoxDecoration(
                  color: priorityColor(task.priority),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done ? Colors.grey : null,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(task.description, style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _chip(Icons.flag_rounded, priorityLabel(task.priority), priorityColor(task.priority)),
                        if (task.taskTime != null) _chip(Icons.schedule_rounded, task.taskTime!, Colors.blueGrey),
                        _chip(Icons.repeat_rounded, repetitionLabel(task.repetition), Colors.blueGrey),
                        _chip(Icons.timer_outlined, '${task.durationMinutes}m', Colors.blueGrey),
                      ],
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: done,
                shape: const CircleBorder(),
                onChanged: (_) => controller.toggleComplete(task, date),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final DateTime date;
  const _EmptyDay({required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.self_improvement_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Nothing planned for this day', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Tap + below to add a priority task.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
