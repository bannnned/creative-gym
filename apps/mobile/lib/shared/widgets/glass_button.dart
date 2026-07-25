import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as liquid;

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
    final foreground = isPrimary ? Colors.white : AppTheme.ink;

    if (variant != GlassButtonVariant.quiet) {
      return liquid.GlassButton.custom(
        label: label,
        onTap: onPressed,
        width: double.infinity,
        height: minHeight,
        useOwnLayer: true,
        quality: liquid.GlassQuality.standard,
        style: isPrimary
            ? liquid.GlassButtonStyle.prominent
            : liquid.GlassButtonStyle.filled,
        shape: const liquid.LiquidRoundedRectangle(
          borderRadius: AppTheme.radiusM,
        ),
        interactionScale: 0.98,
        stretch: 0.12,
        settings: liquid.LiquidGlassSettings(
          glassColor: isPrimary
              ? AppTheme.primaryDark.withValues(alpha: 0.78)
              : Colors.white.withValues(alpha: 0.48),
          platformViewFallbackColor: isPrimary
              ? AppTheme.primaryDark
              : const Color(0xE6E7ECE8),
          blur: 8,
          thickness: isPrimary ? 22 : 16,
          saturation: 1.15,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: isPrimary ? Colors.white : AppTheme.primaryDark,
                ),
                const SizedBox(width: 8),
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
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            color: isPrimary
                ? AppTheme.primaryDark
                : variant == GlassButtonVariant.quiet
                ? Colors.transparent
                : const Color(0xFFE7ECE8),
            border: Border.all(
              color: isPrimary
                  ? AppTheme.primaryDark
                  : variant == GlassButtonVariant.quiet
                  ? Colors.transparent
                  : const Color(0xFFDDE3DE),
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
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
                    Icon(
                      icon,
                      size: 20,
                      color: isPrimary ? Colors.white : AppTheme.primaryDark,
                    ),
                    const SizedBox(width: 8),
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
