import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:flutter/material.dart';

enum GlassButtonVariant { primary, tonal, quiet }

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GlassButtonVariant.primary,
    this.minHeight = 56,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final GlassButtonVariant variant;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == GlassButtonVariant.primary;
    final isQuiet = variant == GlassButtonVariant.quiet;
    final foreground = isPrimary ? Colors.white : AppTheme.ink;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryDark,
                      AppTheme.primary,
                      AppTheme.accent,
                    ],
                    stops: [0, 0.62, 1],
                  )
                : null,
            color: isPrimary
                ? null
                : Colors.white.withValues(alpha: isQuiet ? 0.22 : 0.42),
            border: Border.all(
              color: isPrimary
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.58),
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            boxShadow: [
              if (isPrimary)
                BoxShadow(
                  color: AppTheme.primaryDark.withValues(alpha: 0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (icon != null) ...[
                    _ButtonIcon(icon: icon!, isPrimary: isPrimary),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonIcon extends StatelessWidget {
  const _ButtonIcon({required this.icon, required this.isPrimary});

  final IconData icon;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isPrimary
            ? Colors.white.withValues(alpha: 0.16)
            : AppTheme.primaryDark.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(
          icon,
          size: 18,
          color: isPrimary ? Colors.white : AppTheme.primaryDark,
        ),
      ),
    );
  }
}
