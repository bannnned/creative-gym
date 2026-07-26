import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/features/results/domain/room_result.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/authenticated_media.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.roomId, this.demoMode = false});

  final String roomId;
  final bool demoMode;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late Future<void> _loadFuture;
  GymRoom? _room;
  RoomResult? _result;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final room = await appDependencies.rooms.getRoomById(widget.roomId);
    RoomResult? result;
    if (room != null && (widget.demoMode || room.canViewResults)) {
      result = await appDependencies.results.getRoomResult(widget.roomId);
    }
    _room = room;
    _result = result;
  }

  void _reload() {
    setState(() => _loadFuture = _load());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () => context.go(AppRoutes.challenges),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Итог'),
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncLoadingPanel();
          }
          if (snapshot.hasError) {
            return AsyncErrorPanel(
              message: userErrorMessage(snapshot.error),
              onRetry: _reload,
            );
          }

          final room = _room;
          if (room == null) {
            return const _ResultsState(
              title: 'Итог не найден',
              message: 'Вернитесь к текущему заданию.',
            );
          }
          if (!widget.demoMode && !room.canViewResults) {
            return _ResultsState(
              title: 'Итог пока недоступен',
              message: room.deadlineLabel,
            );
          }
          final result = _result;
          if (result == null) {
            return const _ResultsState(
              title: 'Работ пока нет',
              message: 'В этой комнате ещё нечего показывать.',
            );
          }

          return _ResultsContent(
            room: room,
            result: result,
            showAll: _showAll,
            onToggleAll: () => setState(() => _showAll = !_showAll),
          );
        },
      ),
    );
  }
}

class _ResultsContent extends StatelessWidget {
  const _ResultsContent({
    required this.room,
    required this.result,
    required this.showAll,
    required this.onToggleAll,
  });

  final GymRoom room;
  final RoomResult result;
  final bool showAll;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final own = result.currentUserSubmission;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppTheme.primaryDark,
          size: 38,
        ),
        const SizedBox(height: 16),
        Text(
          'Тренировка завершена',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          room.challengeTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppTheme.mutedInk),
        ),
        const SizedBox(height: 28),
        if (own != null) ...[
          Text(
            'Ваш кадр',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _ResultPreview(submission: own, aspectRatio: 4 / 5),
          const SizedBox(height: 14),
          Text(
            '${own.rank} место · ${own.scoreLabel}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ] else
          Text(
            'Вы смотрите итоги без своей работы.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
          ),
        const SizedBox(height: 8),
        Text(
          result.encouragementLabel,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.mutedInk,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: onToggleAll,
          child: Text(showAll ? 'Скрыть работы' : 'Посмотреть все работы'),
        ),
        if (showAll) ...[
          const SizedBox(height: 8),
          for (final submission in result.rankedSubmissions) ...[
            _ResultRow(submission: submission),
            const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 18),
        GlassButton(
          label: 'Готово',
          onPressed: () => context.go(AppRoutes.challenges),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.submission});

  final ResultSubmission submission;

  @override
  Widget build(BuildContext context) {
    final canOpenProfile =
        submission.isCurrentUser || submission.authorUserId.isNotEmpty;
    return Semantics(
      button: canOpenProfile,
      label: canOpenProfile ? 'Открыть профиль автора' : null,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: InkWell(
          onTap: canOpenProfile
              ? () {
                  final location = submission.isCurrentUser
                      ? AppRoutes.profile
                      : AppRoutes.publicProfile(submission.authorUserId);
                  context.push(location);
                }
              : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  child: _ResultPreview(submission: submission, aspectRatio: 1),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${submission.rank}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submission.isCurrentUser
                            ? 'Ваш кадр'
                            : submission.authorLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        submission.scoreLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultPreview extends StatelessWidget {
  const _ResultPreview({required this.submission, required this.aspectRatio});

  final ResultSubmission submission;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(submission.paletteStart),
            Color(submission.paletteEnd),
          ],
        ),
      ),
    );
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: AuthenticatedMedia(
          mediaUrl: submission.mediaUrl,
          fallback: fallback,
        ),
      ),
    );
  }
}

class _ResultsState extends StatelessWidget {
  const _ResultsState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context.go(AppRoutes.challenges),
              child: const Text('К заданию'),
            ),
          ],
        ),
      ),
    );
  }
}
