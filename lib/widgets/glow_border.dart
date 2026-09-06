import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';

/// يلف حدود العنصر بضوء متحرك (أبيض + تيل) يدور باستمرار
class AnimatedGlowBorder extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double borderWidth;

  const AnimatedGlowBorder({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.borderWidth = 2.5,
  });

  @override
  State<AnimatedGlowBorder> createState() => _AnimatedGlowBorderState();
}

class _AnimatedGlowBorderState extends State<AnimatedGlowBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _GlowBorderPainter(
            progress: _controller.value,
            borderRadius: widget.borderRadius,
            borderWidth: widget.borderWidth,
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: widget.child,
      ),
    );
  }
}

class _GlowBorderPainter extends CustomPainter {
  final double progress;
  final BorderRadius borderRadius;
  final double borderWidth;

  _GlowBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = borderRadius.toRRect(Offset.zero & size);
    final path = Path()..addRRect(rrect);

    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      transform: GradientRotation(2 * math.pi * progress),
      colors: [
        AppColors.primaryTeal.withOpacity(0.15),
        Colors.white,
        AppColors.primaryTeal.withOpacity(0.15),
        AppColors.primaryTeal.withOpacity(0.05),
        AppColors.primaryTeal.withOpacity(0.15),
      ],
      stops: const [0.0, 0.12, 0.24, 0.6, 1.0],
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = gradient.createShader(Offset.zero & size);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
