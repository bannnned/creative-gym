import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/features/auth/data/auth_repository.dart';
import 'package:creative_gym_mobile/features/auth/domain/test_account.dart';
import 'package:creative_gym_mobile/features/profile/domain/profile_data.dart';
import 'package:creative_gym_mobile/features/profile/presentation/widgets/crown_icon.dart';
import 'package:creative_gym_mobile/features/profile/presentation/widgets/profile_work_artwork.dart';
import 'package:creative_gym_mobile/shared/widgets/app_glass_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userId});

  final String? userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _winnersOnly = false;
  late Future<ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = appDependencies.profile.getProfile(userId: widget.userId);
  }

  void _reload() {
    setState(
      () => _profileFuture = appDependencies.profile.getProfile(
        userId: widget.userId,
      ),
    );
  }

  Future<void> _openAdmin() async {
    try {
      if (await appDependencies.admin.isAdmin()) {
        if (mounted) {
          context.push(AppRoutes.adminChallenges);
        }
        return;
      }

      if (!mounted) {
        return;
      }
      final code = await _askForAdminCode();
      if (code == null || code.isEmpty || !mounted) {
        return;
      }

      await appDependencies.admin.unlock(code);
      if (mounted) {
        context.push(AppRoutes.adminChallenges);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message =
          error is ApiException && error.code == 'invalid_admin_code'
          ? 'Неверный код'
          : userErrorMessage(error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<String?> _askForAdminCode() {
    var code = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Режим автора'),
        content: TextField(
          key: const ValueKey('admin-code-field'),
          autofocus: true,
          obscureText: true,
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
          onChanged: (value) => code = value.trim(),
          decoration: const InputDecoration(
            labelText: 'Код',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, code),
            child: const Text('Открыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _openTestAccounts() async {
    try {
      final isAdmin = await appDependencies.admin.isAdmin();
      final accounts = await appDependencies.auth.getTestAccounts(
        currentIsAdmin: isAdmin,
      );
      if (!mounted) {
        return;
      }
      final sessionChanged = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            _TestAccountSwitcher(initialAccounts: accounts, canCreate: isAdmin),
      );
      if (sessionChanged == true && mounted) {
        context.go(AppRoutes.challenges);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userErrorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppGlassScaffold(
      title: 'Профиль',
      showBackButton: true,
      actions: widget.userId == null
          ? [
              if (kDebugMode)
                AppGlassHeaderAction(
                  key: const ValueKey('test-account-switcher-button'),
                  icon: Icons.group_outlined,
                  semanticLabel: 'Тестовые аккаунты',
                  onPressed: _openTestAccounts,
                ),
              AppGlassHeaderAction(
                key: const ValueKey('admin-menu-button'),
                icon: Icons.more_horiz_rounded,
                semanticLabel: 'Режим автора',
                onPressed: _openAdmin,
              ),
            ]
          : const [],
      body: FutureBuilder<ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncLoadingPanel(
              message: 'Загружаем профиль...',
              layout: AsyncLoadingLayout.profile,
            );
          }
          if (snapshot.hasError) {
            return AsyncErrorPanel(
              message: userErrorMessage(snapshot.error),
              onRetry: _reload,
            );
          }
          final data =
              snapshot.data ??
              const ProfileData(
                isCurrentUser: false,
                points: 0,
                firstPlaces: 0,
                secondPlaces: 0,
                thirdPlaces: 0,
                works: [],
              );
          return _ProfileContent(
            data: data,
            winnersOnly: _winnersOnly,
            onWinnersChanged: (value) => setState(() => _winnersOnly = value),
          );
        },
      ),
    );
  }
}

class _TestAccountSwitcher extends StatefulWidget {
  const _TestAccountSwitcher({
    required this.initialAccounts,
    required this.canCreate,
  });

  final List<TestAccount> initialAccounts;
  final bool canCreate;

  @override
  State<_TestAccountSwitcher> createState() => _TestAccountSwitcherState();
}

class _TestAccountSwitcherState extends State<_TestAccountSwitcher> {
  late List<TestAccount> _accounts;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _accounts = widget.initialAccounts;
  }

  Future<void> _create() async {
    if (_busy ||
        !widget.canCreate ||
        _accounts.where((account) => !account.isAdmin).length >=
            AuthRepository.maxTestAccounts) {
      return;
    }
    setState(() => _busy = true);
    try {
      await appDependencies.auth.createTestAccount();
      if (mounted) {
        Navigator.pop(context, true);
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
        Navigator.pop(context, true);
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
      final accounts = await appDependencies.auth.removeTestAccount(
        account.userId,
      );
      if (mounted) {
        setState(() => _accounts = accounts);
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
    final testAccountCount = _accounts
        .where((account) => !account.isAdmin)
        .length;
    final atLimit = testAccountCount >= AuthRepository.maxTestAccounts;
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F6F1),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceStroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'Тестовые аккаунты',
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
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _accounts.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final account = _accounts[index];
                  return ListTile(
                    key: ValueKey('test-account-${account.userId}'),
                    contentPadding: EdgeInsets.zero,
                    enabled: !_busy,
                    onTap: account.isCurrent ? null : () => _switchTo(account),
                    leading: Icon(
                      account.isAdmin
                          ? Icons.shield_outlined
                          : Icons.person_outline_rounded,
                      color: account.isCurrent
                          ? AppTheme.primaryDark
                          : AppTheme.mutedInk,
                    ),
                    title: Text(
                      account.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      account.isCurrent
                          ? 'Текущий аккаунт'
                          : account.isAdmin
                          ? 'Администратор'
                          : 'Нажмите, чтобы переключиться',
                    ),
                    trailing: account.isCurrent
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppTheme.primaryDark,
                          )
                        : account.isAdmin
                        ? null
                        : IconButton(
                            key: ValueKey(
                              'remove-test-account-${account.userId}',
                            ),
                            tooltip: 'Удалить из переключателя',
                            onPressed: _busy ? null : () => _remove(account),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (widget.canCreate)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('create-test-account-button'),
                  onPressed: _busy || atLimit ? null : _create,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(atLimit ? 'Достигнут лимит 8' : 'Новый участник'),
                ),
              )
            else
              Text(
                'Новых участников может создавать только администратор. '
                'Переключитесь на него.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedInk),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.data,
    required this.winnersOnly,
    required this.onWinnersChanged,
  });

  final ProfileData data;
  final bool winnersOnly;
  final ValueChanged<bool> onWinnersChanged;

  @override
  Widget build(BuildContext context) {
    final works = winnersOnly
        ? data.works.where((work) => work.isWinner).toList(growable: false)
        : data.works;
    return ListView(
      key: const ValueKey('profile-screen'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        const _ProfileAvatar(),
        const SizedBox(height: 12),
        Text(
          data.displayName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 24),
        _StatsBlock(data: data),
        const SizedBox(height: 30),
        Row(
          children: [
            Text(
              'Работы',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              'Победители',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedInk,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 46,
              height: 36,
              child: FittedBox(
                child: Switch.adaptive(
                  key: const ValueKey('winners-toggle'),
                  value: winnersOnly,
                  onChanged: onWinnersChanged,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (works.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Text(
              winnersOnly
                  ? 'Призовых работ пока нет.'
                  : 'Здесь появятся ваши фотографии.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
            ),
          )
        else
          GridView.builder(
            key: const ValueKey('profile-work-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemCount: works.length,
            itemBuilder: (context, index) {
              final work = works[index];
              return _WorkTile(
                work: work,
                onTap: () => context.push(
                  AppRoutes.profileWorks(index, winnersOnly: winnersOnly),
                  extra: works,
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 104,
        height: 104,
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: const DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF91B7A8), Color(0xFF244D42)],
            ),
          ),
          child: Icon(Icons.person_rounded, color: Color(0xE6FFFFFF), size: 54),
        ),
      ),
    );
  }
}

class _StatsBlock extends StatelessWidget {
  const _StatsBlock({required this.data});

  final ProfileData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.points}',
                    key: const ValueKey('profile-points'),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'очков',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 92, color: AppTheme.surfaceStroke),
            const SizedBox(width: 24),
            SizedBox(
              width: 82,
              child: Column(
                children: [
                  _PlaceRow(place: 1, count: data.firstPlaces),
                  const SizedBox(height: 10),
                  _PlaceRow(place: 2, count: data.secondPlaces),
                  const SizedBox(height: 10),
                  _PlaceRow(place: 3, count: data.thirdPlaces),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place, required this.count});

  final int place;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CrownIcon(color: PlaceColors.forPlace(place), size: 24),
        const Spacer(),
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _WorkTile extends StatelessWidget {
  const _WorkTile({required this.work, required this.onTap});

  final ProfileWork work;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: work.isWinner ? '${work.title}, ${work.place} место' : work.title,
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('profile-work-${work.id}'),
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProfileWorkArtwork(work: work),
              if (work.isWinner)
                Positioned(
                  right: 7,
                  bottom: 7,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xB8000000),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CrownIcon(
                      color: PlaceColors.forPlace(work.place!),
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
