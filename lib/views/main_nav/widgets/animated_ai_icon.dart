import 'dart:math';
import 'package:flutter/material.dart';
import '/utils/app_theme.dart';

class AnimatedAiIcon extends StatefulWidget {
  final bool active;

  const AnimatedAiIcon({
    super.key,
    this.active = false,
  });

  @override
  State<AnimatedAiIcon> createState() => AnimatedAiIconState();
}

class AnimatedAiIconState extends State<AnimatedAiIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final Random _random = Random();

  late final List<_Sparkle> _sparkles;

  @override
  void initState() {
    super.initState();

    _sparkles = List.generate(
      12,
      (_) => _Sparkle(
        x: _random.nextDouble() * 2 - 1,
        y: _random.nextDouble() * 2 - 1,
        size: 1.0 + _random.nextDouble() * 1.5,
        delay: _random.nextDouble(),
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.active
        ? AppColors.signalTeal
        : Theme.of(context).iconTheme.color;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final pulse = 1.0 + (sin(_controller.value * 2 * pi) * 0.06);

        return SizedBox(
          width: 35,
          height: 35,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
// Tiny continuously moving sparkles
              CustomPaint(
                size: const Size(28, 28),
                painter: _SparklePainter(
                  progress: _controller.value,
                  sparkles: _sparkles,
                  color: iconColor as Color,
                ),
              ),

// Main AI icon
              Transform.scale(
                scale: pulse,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: iconColor,
                  size: 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sparkle {
  final double x;
  final double y;
  final double size;
  final double delay;

  _Sparkle({
    required this.x,
    required this.y,
    required this.size,
    required this.delay,
  });
}

class _SparklePainter extends CustomPainter {
  final double progress;
  final List<_Sparkle> sparkles;
  final Color color;

  _SparklePainter({
    required this.progress,
    required this.sparkles,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    for (final sparkle in sparkles) {
      double t = (progress + sparkle.delay) % 1.0;

// Start near the icon and float outward
      final distance = Curves.easeOut.transform(t);

      final center = Offset(
        size.width / 2 + sparkle.x * 30 * distance,
        size.height / 2 + sparkle.y * 30 * distance,
      );

// Fade in quickly, then fade out
      double opacity;

      if (t < 0.15) {
        opacity = t / 0.15;
      } else {
        opacity = 1.0 - ((t - 0.15) / 0.85);
      }

      paint.color = color.withValues(
        alpha: opacity.clamp(0.0, 1.0),
      );

      canvas.drawCircle(
        center,
        sparkle.size * (1.0 - t * 0.35),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
