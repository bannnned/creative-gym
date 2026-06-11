import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/features/auth/presentation/widgets/login_button.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: const IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderBlock(),
                      Spacer(),
                      _LoginPanel(),
                      SizedBox(height: 24),
                      _FooterNote(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.accent],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDark.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(
            Icons.camera_alt_outlined,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Creative Gym',
          style: textTheme.displaySmall?.copyWith(
            color: const Color(0xFF1F2A24),
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Еженедельные фото-тренировки для спокойной творческой практики.',
          style: textTheme.titleMedium?.copyWith(
            color: const Color(0xFF516158),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Войти в аккаунт',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите провайдера. Подключение OAuth добавим следующим шагом.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedInk,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          LoginButton(
            icon: Icons.g_mobiledata,
            label: 'Войти через Google',
            onPressed: () => _showComingSoon(context, 'Google'),
          ),
          const SizedBox(height: 14),
          LoginButton(
            icon: Icons.search,
            label: 'Войти через Yandex',
            onPressed: () => _showComingSoon(context, 'Yandex'),
          ),
          const SizedBox(height: 14),
          LoginButton(
            icon: Icons.code,
            label: 'Войти через GitHub',
            onPressed: () => _showComingSoon(context, 'GitHub'),
          ),
          const SizedBox(height: 18),
          GlassButton(
            onPressed: () => context.go(AppRoutes.challenges),
            icon: Icons.arrow_forward,
            label: 'Продолжить в демо',
          ),
        ],
      ),
    );
  }

  static void _showComingSoon(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'OAuth через $provider будет подключен в следующем шаге.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'MVP стартует с фото-челленджей: 5 дней на работу, 2 дня на анонимное сравнение.',
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedInk, height: 1.35),
    );
  }
}
