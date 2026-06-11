import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _GradientField()),
        const Positioned.fill(child: _GrainOverlay()),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _GradientField extends StatelessWidget {
  const _GradientField();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF7F2E8),
            Color(0xFFE8F1EB),
            Color(0xFFE9EEF6),
            Color(0xFFF2E4DA),
          ],
          stops: [0, 0.34, 0.68, 1],
        ),
      ),
    );
  }
}

class _GrainOverlay extends StatelessWidget {
  const _GrainOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GrainPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()..color = Colors.black.withValues(alpha: 0.018);
    final lightPaint = Paint()..color = Colors.white.withValues(alpha: 0.018);
    final count = (size.width * size.height / 950).clamp(260, 720).round();

    for (var i = 0; i < count; i++) {
      final x = ((i * 47) % size.width.toInt()).toDouble();
      final y = ((i * 83) % size.height.toInt()).toDouble();
      canvas.drawCircle(
        Offset(x, y),
        i.isEven ? 0.42 : 0.32,
        i.isEven ? darkPaint : lightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
