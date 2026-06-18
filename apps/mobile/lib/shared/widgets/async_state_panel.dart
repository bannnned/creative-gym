import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_panel.dart';
import 'package:flutter/material.dart';

class AsyncLoadingPanel extends StatelessWidget {
  const AsyncLoadingPanel({super.key, this.message = 'Загрузка...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryDark),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AsyncErrorPanel extends StatelessWidget {
  const AsyncErrorPanel({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 44,
                color: AppTheme.mutedInk,
              ),
              const SizedBox(height: 12),
              Text(
                'Не удалось загрузить данные',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedInk,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              GlassButton(
                onPressed: onRetry,
                icon: Icons.refresh,
                label: 'Повторить',
                variant: GlassButtonVariant.tonal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
