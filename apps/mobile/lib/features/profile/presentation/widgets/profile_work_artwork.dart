import 'dart:math' as math;

import 'package:creative_gym_mobile/features/profile/domain/profile_data.dart';
import 'package:creative_gym_mobile/shared/widgets/authenticated_media.dart';
import 'package:flutter/material.dart';

class ProfileWorkArtwork extends StatelessWidget {
  const ProfileWorkArtwork({super.key, required this.work});

  final ProfileWork work;

  @override
  Widget build(BuildContext context) {
    final fallback = LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _ArtworkPainter(work),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
    return AuthenticatedMedia(
      mediaUrl: work.mediaUrl,
      fallback: fallback,
      fit: BoxFit.cover,
    );
  }
}

class _ArtworkPainter extends CustomPainter {
  const _ArtworkPainter(this.work);

  final ProfileWork work;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final start = Color(work.paletteStart);
    final end = Color(work.paletteEnd);
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [start, end],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final light = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final shade = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    switch (work.composition % 6) {
      case 0:
        canvas.drawCircle(
          Offset(size.width * 0.72, size.height * 0.27),
          size.shortestSide * 0.24,
          light,
        );
        canvas.drawRect(
          Rect.fromLTWH(
            size.width * 0.12,
            size.height * 0.48,
            size.width * 0.45,
            size.height * 0.52,
          ),
          shade,
        );
      case 1:
        final path = Path()
          ..moveTo(0, size.height * 0.72)
          ..lineTo(size.width * 0.62, size.height * 0.18)
          ..lineTo(size.width, size.height * 0.46)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, shade);
        canvas.drawCircle(
          Offset(size.width * 0.28, size.height * 0.30),
          size.shortestSide * 0.10,
          light,
        );
      case 2:
        for (var index = 0; index < 4; index++) {
          canvas.save();
          canvas.translate(size.width * 0.5, size.height * 0.5);
          canvas.rotate(-0.35 + index * 0.18);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: size.width * 1.3,
              height: size.height * 0.08,
            ),
            index.isEven ? light : shade,
          );
          canvas.restore();
        }
      case 3:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.45),
            width: size.width * 0.72,
            height: size.height * 0.28,
          ),
          light,
        );
        canvas.drawRect(
          Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38),
          shade,
        );
      case 4:
        final path = Path();
        for (var index = 0; index <= 8; index++) {
          final x = size.width * index / 8;
          final y = size.height * (0.48 + math.sin(index * 1.2) * 0.12);
          if (index == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, shade);
        canvas.drawCircle(
          Offset(size.width * 0.75, size.height * 0.22),
          size.shortestSide * 0.13,
          light,
        );
      default:
        for (var index = 0; index < 5; index++) {
          final inset = size.shortestSide * (0.08 + index * 0.07);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect.deflate(inset),
              Radius.circular(size.shortestSide * 0.04),
            ),
            index.isEven ? light : shade,
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant _ArtworkPainter oldDelegate) {
    return oldDelegate.work != work;
  }
}
