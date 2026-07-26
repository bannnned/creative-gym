import 'dart:typed_data';

import 'package:creative_gym_mobile/app/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SoftMemoryImage extends StatelessWidget {
  const SoftMemoryImage({
    super.key,
    required this.bytes,
    required this.placeholder,
    required this.revealKey,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final Uint8List bytes;
  final Widget placeholder;
  final Object revealKey;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.isReduced(context);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          placeholder,
          Image.memory(
            bytes,
            fit: fit,
            alignment: alignment,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, _) {
              if (frame == null) {
                return const SizedBox.shrink();
              }
              if (reduceMotion) {
                return child;
              }
              return child
                  .animate(key: ValueKey('soft-image-$revealKey'))
                  .fadeIn(
                    duration: AppMotion.duration(context, AppMotion.expressive),
                    curve: Curves.easeOutCubic,
                  )
                  .blurXY(
                    begin: 10,
                    end: 0,
                    duration: AppMotion.duration(context, AppMotion.expressive),
                    curve: Curves.easeOutCubic,
                  )
                  .scaleXY(
                    begin: 1.015,
                    end: 1,
                    duration: AppMotion.duration(context, AppMotion.expressive),
                    curve: Curves.easeOutCubic,
                  );
            },
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
