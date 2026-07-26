import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/features/profile/domain/profile_data.dart';
import 'package:creative_gym_mobile/features/profile/presentation/widgets/crown_icon.dart';
import 'package:creative_gym_mobile/features/profile/presentation/widgets/profile_work_artwork.dart';
import 'package:creative_gym_mobile/shared/widgets/app_glass_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
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
  late Future<bool> _adminStatusFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = appDependencies.profile.getProfile(userId: widget.userId);
    _adminStatusFuture = appDependencies.admin.isAdmin();
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
          context.push(AppRoutes.admin);
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
        setState(() => _adminStatusFuture = Future.value(true));
        context.push(AppRoutes.admin);
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

  @override
  Widget build(BuildContext context) {
    return AppGlassScaffold(
      title: 'Профиль',
      showBackButton: true,
      actions: widget.userId == null
          ? [
              FutureBuilder<bool>(
                future: _adminStatusFuture,
                builder: (context, snapshot) {
                  final isAdmin = snapshot.data == true;
                  return AppGlassHeaderAction(
                    key: const ValueKey('admin-menu-button'),
                    icon: isAdmin
                        ? Icons.tune_rounded
                        : Icons.lock_outline_rounded,
                    semanticLabel: isAdmin
                        ? 'Управление'
                        : 'Ввести секретный код',
                    onPressed: _openAdmin,
                  );
                },
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
