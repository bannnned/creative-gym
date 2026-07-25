import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:flutter/material.dart';

class AsyncLoadingPanel extends StatelessWidget {
  const AsyncLoadingPanel({super.key, this.message = 'Загрузка...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: AppTheme.primaryDark,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
            ),
          ],
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 36,
              color: AppTheme.mutedInk,
            ),
            const SizedBox(height: 16),
            Text(
              'Не удалось загрузить данные',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedInk,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: GlassButton(
                onPressed: onRetry,
                label: 'Повторить',
                variant: GlassButtonVariant.tonal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
