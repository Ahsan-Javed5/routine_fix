import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../utils/app_theme.dart';

class DisciplineRingHero extends StatelessWidget {
  final double percent;
  final int done;
  final int total;
  final int currentStreak;
  final int bestStreak;

  const DisciplineRingHero({
    super.key,
    required this.percent,
    required this.done,
    required this.total,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

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
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _greeting(),
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: CustomPaint(
                  painter: _RingPainter(percent: percent),
                  child: Center(
                    child: Text(
                      '${(percent * 100).round()}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Discipline Ring',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? 'No tasks planned'
                          : '$done of $total tasks done',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      percent >= 1 && total > 0
                          ? 'Perfect day — keep the streak alive!'
                          : total == 0
                              ? 'Add a task to get started.'
                              : 'Keep going, you\'ve got this.',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (currentStreak > 0 || bestStreak > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _streakPill(
                  icon: Icons.local_fire_department_rounded,
                  label: currentStreak == 1
                      ? '1 day streak'
                      : '$currentStreak day streak',
                  color: const Color(0xFFFF8A3D),
                  emphasized: currentStreak > 0,
                ),
                const SizedBox(width: 10),
                _streakPill(
                  icon: Icons.emoji_events_rounded,
                  label: 'Best: $bestStreak',
                  color: AppColors.amberGold,
                  emphasized: false,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _streakPill({
    required IconData icon,
    required String label,
    required Color color,
    required bool emphasized,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized
            ? color.withOpacity(0.18)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: emphasized ? color : Colors.white60),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: emphasized ? Colors.white : Colors.white60)),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    if (hour < 21) return 'Good evening 🌇';
    return 'Winding down 🌙';
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
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.percent != percent;
}
