import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/shared/widgets/app_glass_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<bool> _accessFuture;
  bool _onboardingEnabled = false;
  bool _savingOnboarding = false;

  @override
  void initState() {
    super.initState();
    _accessFuture = _load();
  }

  Future<bool> _load() async {
    if (!await appDependencies.admin.isAdmin()) {
      throw const ApiException(
        code: 'admin_required',
        statusCode: 403,
        message: 'Admin access is required.',
      );
    }
    _onboardingEnabled = await appDependencies.onboarding.isEnabled();
    return true;
  }

  Future<void> _setOnboardingEnabled(bool value) async {
    if (_savingOnboarding) {
      return;
    }
    setState(() {
      _savingOnboarding = true;
      _onboardingEnabled = value;
    });
    try {
      await appDependencies.onboarding.setEnabled(value);
      if (mounted && value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Онбординг появится после возвращения к челленджам.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _onboardingEnabled = !value);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userErrorMessage(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _savingOnboarding = false);
      }
    }
  }

  void _reload() {
    setState(() => _accessFuture = _load());
  }

  @override
  Widget build(BuildContext context) {
    return AppGlassScaffold(
      title: 'Управление',
      showBackButton: true,
      body: FutureBuilder<bool>(
        future: _accessFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncLoadingPanel(
              message: 'Открываем управление...',
              layout: AsyncLoadingLayout.detail,
            );
          }
          if (snapshot.hasError) {
            return AsyncErrorPanel(
              message: userErrorMessage(snapshot.error),
              onRetry: _reload,
            );
          }
          return ListView(
            key: const ValueKey('admin-home-screen'),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              GlassPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _AdminNavigationRow(
                      key: const ValueKey('admin-challenges-section'),
                      icon: Icons.view_agenda_outlined,
                      title: 'Челленджи',
                      subtitle: 'Создать, изменить или убрать',
                      onTap: () => context.push(AppRoutes.adminChallenges),
                    ),
                    const Divider(height: 1),
                    _AdminNavigationRow(
                      key: const ValueKey('admin-test-accounts-section'),
                      icon: Icons.group_outlined,
                      title: 'Тестовые аккаунты',
                      subtitle: 'Переключить, создать или удалить',
                      onTap: () => context.push(AppRoutes.adminTestAccounts),
                    ),
                    const Divider(height: 1),
                    _OnboardingSwitchRow(
                      value: _onboardingEnabled,
                      enabled: !_savingOnboarding,
                      onChanged: _setOnboardingEnabled,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminNavigationRow extends StatelessWidget {
  const _AdminNavigationRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: Icon(icon, color: AppTheme.primaryDark),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _OnboardingSwitchRow extends StatelessWidget {
  const _OnboardingSwitchRow({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Онбординг',
      toggled: value,
      child: ListTile(
        key: const ValueKey('admin-onboarding-toggle'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: const Icon(
          Icons.auto_awesome_outlined,
          color: AppTheme.primaryDark,
        ),
        title: const Text(
          'Онбординг',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          value ? 'Будет показан при возвращении' : 'Уже пройден или отключён',
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
        onTap: enabled ? () => onChanged(!value) : null,
      ),
    );
  }
}
