import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.tint = Colors.white,
    this.radius = AppTheme.radiusL,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color tint;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        border: Border.all(color: const Color(0xFFE3E7E2)),
        borderRadius: borderRadius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

class SoftChip extends StatelessWidget {
  const SoftChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEEA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryDark),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
