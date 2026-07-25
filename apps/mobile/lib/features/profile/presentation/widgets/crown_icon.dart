import 'package:flutter/material.dart';

abstract final class PlaceColors {
  static const gold = Color(0xFFFFC857);
  static const silver = Color(0xFFC7CED6);
  static const bronze = Color(0xFFC47A55);

  static Color forPlace(int place) {
    return switch (place) {
      1 => gold,
      2 => silver,
      _ => bronze,
    };
  }
}

class CrownIcon extends StatelessWidget {
  const CrownIcon({super.key, required this.color, this.size = 22});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.78),
      painter: _CrownPainter(color),
    );
  }
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final crown = Path()
      ..moveTo(size.width * 0.08, size.height * 0.24)
      ..lineTo(size.width * 0.30, size.height * 0.50)
      ..lineTo(size.width * 0.50, size.height * 0.10)
      ..lineTo(size.width * 0.70, size.height * 0.50)
      ..lineTo(size.width * 0.92, size.height * 0.24)
      ..lineTo(size.width * 0.82, size.height * 0.78)
      ..lineTo(size.width * 0.18, size.height * 0.78)
      ..close();

    canvas.drawPath(crown.shift(const Offset(0, 1.5)), shadow);
    canvas.drawPath(crown, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.17,
          size.height * 0.78,
          size.width * 0.66,
          size.height * 0.14,
        ),
        Radius.circular(size.height * 0.07),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CrownPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
