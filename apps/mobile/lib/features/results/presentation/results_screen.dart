import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/features/results/data/mock_room_results.dart';
import 'package:creative_gym_mobile/features/results/domain/room_result.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_panel.dart';
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
  late Future<GymRoom?> _roomFuture;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  void _loadRoom() {
    setState(() {
      _roomFuture = appDependencies.rooms.getRoomById(widget.roomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = findMockRoomResultByRoomId(widget.roomId);

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () => context.go(AppRoutes.room(widget.roomId)),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Results'),
      ),
      body: FutureBuilder<GymRoom?>(
        future: _roomFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncLoadingPanel(message: 'Загрузка результатов...');
          }

          if (snapshot.hasError) {
            return AsyncErrorPanel(
              message: snapshot.error.toString(),
              onRetry: _loadRoom,
            );
          }

          final room = snapshot.data;
          if (room == null || result == null) {
            return const _MissingResultsRoom();
          }

          if (!widget.demoMode && !room.canViewResults) {
            return _ResultsUnavailable(room: room);
          }

          return _ResultsContent(room: room, result: result);
        },
      ),
    );
  }
}

class _ResultsContent extends StatelessWidget {
  const _ResultsContent({required this.room, required this.result});

  final GymRoom room;
  final RoomResult result;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text(
          room.challengeTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.ink,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Итоги Gym Room',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        _CompletionPanel(room: room, result: result),
        const SizedBox(height: 18),
        _OwnResultPanel(submission: result.currentUserSubmission),
        const SizedBox(height: 18),
        _RankingPanel(submissions: result.rankedSubmissions),
        const SizedBox(height: 18),
        GlassButton(
          onPressed: () => context.go(AppRoutes.challenges),
          icon: Icons.calendar_month_outlined,
          label: 'К следующим Weekly Workouts',
          variant: GlassButtonVariant.tonal,
        ),
      ],
    );
  }
}

class _CompletionPanel extends StatelessWidget {
  const _CompletionPanel({required this.room, required this.result});

  final GymRoom room;
  final RoomResult result;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      tint: const Color(0x99E7F0EA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppTheme.primaryDark,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.completionLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      result.encouragementLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedInk,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SoftChip(icon: Icons.flag_outlined, label: room.phaseLabel),
              SoftChip(
                icon: Icons.groups_outlined,
                label: '${result.participantsCount} участников',
              ),
              SoftChip(
                icon: Icons.photo_library_outlined,
                label: '${result.submissionsCount} работ',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnResultPanel extends StatelessWidget {
  const _OwnResultPanel({required this.submission});

  final ResultSubmission submission;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ваш результат',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 108,
                child: _ResultPreview(submission: submission),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RankBadge(rank: submission.rank),
                    const SizedBox(height: 10),
                    Text(
                      submission.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      submission.scoreLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankingPanel extends StatelessWidget {
  const _RankingPanel({required this.submissions});

  final List<ResultSubmission> submissions;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сильнее всего считалось',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Демо-ранжирование по попарным выборам внутри комнаты.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedInk,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          for (final submission in submissions) ...[
            _RankedSubmissionTile(submission: submission),
            if (submission != submissions.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _RankedSubmissionTile extends StatelessWidget {
  const _RankedSubmissionTile({required this.submission});

  final ResultSubmission submission;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: submission.isCurrentUser ? 0.56 : 0.32,
        ),
        border: Border.all(
          color: submission.isCurrentUser
              ? AppTheme.primaryDark.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.58),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(width: 54, child: _ResultPreview(submission: submission)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${submission.rank} · ${submission.title}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    submission.isCurrentUser
                        ? 'Ваш кадр · ${submission.scoreLabel}'
                        : '${submission.authorLabel} · ${submission.scoreLabel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultPreview extends StatelessWidget {
  const _ResultPreview({required this.submission});

  final ResultSubmission submission;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(submission.paletteStart),
              Color(submission.paletteEnd),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
        ),
        child: Center(
          child: Icon(
            submission.isCurrentUser
                ? Icons.person_outline
                : Icons.photo_camera_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '#$rank в комнате',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MissingResultsRoom extends StatelessWidget {
  const _MissingResultsRoom();

  @override
  Widget build(BuildContext context) {
    return _ResultsStatePanel(
      icon: Icons.search_off_outlined,
      title: 'Результаты не найдены',
      message: 'Проверьте ссылку или вернитесь к списку Weekly Workouts.',
      buttonLabel: 'Вернуться к Weekly Workouts',
      onPressed: () => context.go(AppRoutes.challenges),
    );
  }
}

class _ResultsUnavailable extends StatelessWidget {
  const _ResultsUnavailable({required this.room});

  final GymRoom room;

  @override
  Widget build(BuildContext context) {
    return _ResultsStatePanel(
      icon: Icons.hourglass_bottom_outlined,
      title: 'Результаты еще не открыты',
      message: room.phaseHelpLabel,
      buttonLabel: 'Вернуться в Gym Room',
      onPressed: () => context.go(AppRoutes.room(room.id)),
    );
  }
}

class _ResultsStatePanel extends StatelessWidget {
  const _ResultsStatePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: AppTheme.mutedInk),
              const SizedBox(height: 12),
              Text(
                title,
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
                onPressed: onPressed,
                icon: Icons.arrow_back,
                label: buttonLabel,
                variant: GlassButtonVariant.tonal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
