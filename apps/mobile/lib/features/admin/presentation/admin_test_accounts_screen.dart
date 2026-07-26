import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/features/auth/data/auth_repository.dart';
import 'package:creative_gym_mobile/features/auth/domain/test_account.dart';
import 'package:creative_gym_mobile/shared/widgets/app_glass_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminTestAccountsScreen extends StatefulWidget {
  const AdminTestAccountsScreen({super.key});

  @override
  State<AdminTestAccountsScreen> createState() =>
      _AdminTestAccountsScreenState();
}

class _AdminTestAccountsScreenState extends State<AdminTestAccountsScreen> {
  late Future<List<TestAccount>> _accountsFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _accountsFuture = _load();
  }

  Future<List<TestAccount>> _load() async {
    if (!await appDependencies.admin.isAdmin()) {
      throw const ApiException(
        code: 'admin_required',
        statusCode: 403,
        message: 'Admin access is required.',
      );
    }
    return appDependencies.auth.getTestAccounts(currentIsAdmin: true);
  }

  void _reload() {
    setState(() => _accountsFuture = _load());
  }

  Future<void> _create() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await appDependencies.auth.createTestAccount();
      if (mounted) {
        context.go(AppRoutes.challenges);
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _switchTo(TestAccount account) async {
    if (_busy || account.isCurrent) {
      return;
    }
    setState(() => _busy = true);
    try {
      await appDependencies.auth.switchTestAccount(account.userId);
      if (mounted) {
        context.go(AppRoutes.challenges);
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _remove(TestAccount account) async {
    if (_busy || account.isCurrent || account.isAdmin) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить ${account.label}?'),
        content: const Text(
          'Аккаунт исчезнет из переключателя. Его работы останутся на сервере.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await appDependencies.auth.removeTestAccount(account.userId);
      if (mounted) {
        _reload();
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showError(Object error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(userErrorMessage(error))));
  }

  @override
  Widget build(BuildContext context) {
    return AppGlassScaffold(
      title: 'Тестовые аккаунты',
      showBackButton: true,
      body: FutureBuilder<List<TestAccount>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncLoadingPanel(
              message: 'Загружаем аккаунты...',
              layout: AsyncLoadingLayout.list,
            );
          }
          if (snapshot.hasError) {
            return AsyncErrorPanel(
              message: userErrorMessage(snapshot.error),
              onRetry: _reload,
            );
          }

          final accounts = snapshot.data ?? const [];
          final testAccountCount = accounts
              .where((account) => !account.isAdmin)
              .length;
          final atLimit = testAccountCount >= AuthRepository.maxTestAccounts;

          return ListView(
            key: const ValueKey('admin-test-account-list'),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              Row(
                children: [
                  Text(
                    'Участники',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$testAccountCount/${AuthRepository.maxTestAccounts}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GlassPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var index = 0; index < accounts.length; index++) ...[
                      _AccountRow(
                        account: accounts[index],
                        enabled: !_busy,
                        onTap: () => _switchTo(accounts[index]),
                        onRemove: () => _remove(accounts[index]),
                      ),
                      if (index != accounts.length - 1)
                        const Divider(height: 1),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (!atLimit)
                GlassButton(
                  key: const ValueKey('create-test-account-button'),
                  label: _busy ? 'Подождите...' : 'Создать участника',
                  onPressed: _create,
                  variant: GlassButtonVariant.tonal,
                )
              else
                Text(
                  'Достигнут лимит тестовых аккаунтов.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.enabled,
    required this.onTap,
    required this.onRemove,
  });

  final TestAccount account;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final canRemove = !account.isAdmin && !account.isCurrent;
    return ListTile(
      key: ValueKey('test-account-${account.userId}'),
      contentPadding: const EdgeInsets.only(left: 18, right: 8),
      enabled: enabled,
      onTap: account.isCurrent ? null : onTap,
      leading: Icon(
        account.isAdmin ? Icons.shield_outlined : Icons.person_outline_rounded,
        color: account.isCurrent ? AppTheme.primaryDark : AppTheme.mutedInk,
      ),
      title: Text(
        account.label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: account.isCurrent ? const Text('Сейчас используется') : null,
      trailing: canRemove
          ? IconButton(
              tooltip: 'Удалить',
              onPressed: enabled ? onRemove : null,
              icon: const Icon(Icons.delete_outline_rounded),
            )
          : account.isCurrent
          ? const Icon(Icons.check_rounded, color: AppTheme.primaryDark)
          : null,
    );
  }
}
