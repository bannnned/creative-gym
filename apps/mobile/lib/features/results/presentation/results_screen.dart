import 'package:creative_gym_mobile/app/app_motion.dart';
import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/features/results/domain/room_result.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/app_back_scope.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/authenticated_media.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  bool _resultsPending = false;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final room = await appDependencies.rooms.getRoomById(widget.roomId);
    RoomResult? result;
    var resultsPending = false;
    if (room != null && (widget.demoMode || room.canViewResults)) {
      try {
        result = await appDependencies.results.getRoomResult(widget.roomId);
      } on ApiException catch (error) {
        if (error.code != 'results_pending') {
          rethrow;
        }
        resultsPending = true;
      }
    }
    _room = room;
    _result = result;
    _resultsPending = resultsPending;
  }

  void _reload() {
    setState(() => _loadFuture = _load());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backFallbackLocation: AppRoutes.challenges,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () =>
              popOrGoBack(context, fallbackLocation: AppRoutes.challenges),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Итог'),
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncLoadingPanel(
              message: 'Загружаем итог...',
              layout: AsyncLoadingLayout.photo,
            );
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
          if (_resultsPending) {
            return _ResultsState(
              title: 'Итоги ещё не готовы',
              message: 'Они появятся после завершения голосования.',
              actionLabel: 'Обновить',
              onAction: _reload,
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
    final viewerSubmissions = <ResultSubmission>[
      ...result.rankedSubmissions,
      if (own != null &&
          !result.rankedSubmissions.any(
            (submission) => submission.id == own.id,
          ))
        own,
    ];

    void openPhoto(ResultSubmission submission) {
      final initialIndex = viewerSubmissions.indexWhere(
        (item) => item.id == submission.id,
      );
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => _ResultPhotoViewer(
            submissions: viewerSubmissions,
            initialIndex: initialIndex < 0 ? 0 : initialIndex,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      children: [
        Text(
              'Тренировка завершена',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w800,
              ),
            )
            .animate(
              key: const ValueKey('results-complete-title'),
              delay: AppMotion.delay(context, const Duration(milliseconds: 70)),
            )
            .fadeIn(duration: AppMotion.duration(context, AppMotion.standard))
            .slideY(
              begin: 0.12,
              end: 0,
              duration: AppMotion.duration(context, AppMotion.standard),
              curve: Curves.easeOutCubic,
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
          _ResultPhotoButton(
                key: ValueKey('open-own-result-photo-${own.id}'),
                submission: own,
                onTap: () => openPhoto(own),
                child: _ResultPreview(submission: own, aspectRatio: 4 / 5),
              )
              .animate(
                key: ValueKey('own-result-${own.id}'),
                delay: AppMotion.delay(
                  context,
                  const Duration(milliseconds: 130),
                ),
              )
              .fadeIn(
                duration: AppMotion.duration(context, AppMotion.expressive),
              )
              .scaleXY(
                begin: AppMotion.isReduced(context) ? 1 : 0.985,
                end: 1,
                duration: AppMotion.duration(context, AppMotion.expressive),
                curve: Curves.easeOutCubic,
              ),
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
            _ResultRow(
              submission: submission,
              onOpenPhoto: () => openPhoto(submission),
            ),
            const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 18),
        GlassButton(
          key: const ValueKey('results-finish-button'),
          label: result.outcomeActionLabel,
          onPressed: () => context.go(AppRoutes.challenges),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.submission, required this.onOpenPhoto});

  final ResultSubmission submission;
  final VoidCallback onOpenPhoto;

  @override
  Widget build(BuildContext context) {
    final canOpenProfile =
        submission.isCurrentUser || submission.authorUserId.isNotEmpty;
    final authorLabel = submission.isCurrentUser
        ? 'Ваш кадр'
        : submission.authorLabel;
    final authorText = Text(
      authorLabel,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: _ResultPhotoButton(
              key: ValueKey('open-result-photo-${submission.id}'),
              submission: submission,
              onTap: onOpenPhoto,
              child: _ResultPreview(submission: submission, aspectRatio: 1),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 28,
            child: Text(
              '${submission.rank}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canOpenProfile)
                  Semantics(
                    button: true,
                    label: 'Открыть профиль $authorLabel',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('open-result-profile-${submission.id}'),
                        onTap: () {
                          final location = submission.isCurrentUser
                              ? AppRoutes.profile
                              : AppRoutes.publicProfile(
                                  submission.authorUserId,
                                );
                          context.push(location);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: authorText,
                        ),
                      ),
                    ),
                  )
                else
                  authorText,
                const SizedBox(height: 3),
                Text(
                  submission.scoreLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPhotoButton extends StatelessWidget {
  const _ResultPhotoButton({
    super.key,
    required this.submission,
    required this.onTap,
    required this.child,
  });

  final ResultSubmission submission;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Открыть работу «${submission.title}»',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: child),
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

class _ResultPhotoViewer extends StatefulWidget {
  const _ResultPhotoViewer({
    required this.submissions,
    required this.initialIndex,
  });

  final List<ResultSubmission> submissions;
  final int initialIndex;

  @override
  State<_ResultPhotoViewer> createState() => _ResultPhotoViewerState();
}

class _ResultPhotoViewerState extends State<_ResultPhotoViewer> {
  late final PageController _controller;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.submissions.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.submissions.length - 1);
    _controller = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            key: const ValueKey('result-photo-viewer'),
            controller: _controller,
            itemCount: widget.submissions.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) {
              final submission = widget.submissions[index];
              return _FullscreenResultPhoto(submission: submission);
            },
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 0,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton.filled(
                    key: const ValueKey('close-result-photo-viewer'),
                    tooltip: 'Закрыть',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x99000000),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        '${_page + 1} из ${widget.submissions.length}',
                        key: const ValueKey('result-photo-counter'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.submissions.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: _ResultPhotoCaption(
                  submission: widget.submissions[_page],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FullscreenResultPhoto extends StatelessWidget {
  const _FullscreenResultPhoto({required this.submission});

  final ResultSubmission submission;

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

    return Semantics(
      image: true,
      label: submission.title,
      child: SizedBox.expand(
        child: AuthenticatedMedia(
          mediaUrl: submission.mediaUrl,
          fallback: fallback,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _ResultPhotoCaption extends StatelessWidget {
  const _ResultPhotoCaption({required this.submission});

  final ResultSubmission submission;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    submission.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    submission.isCurrentUser
                        ? 'Ваш кадр'
                        : submission.authorLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xCCFFFFFF)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${submission.rank} место',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsState extends StatelessWidget {
  const _ResultsState({
    required this.title,
    required this.message,
    this.actionLabel = 'К заданию',
    this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

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
              onPressed: onAction ?? () => context.go(AppRoutes.challenges),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
