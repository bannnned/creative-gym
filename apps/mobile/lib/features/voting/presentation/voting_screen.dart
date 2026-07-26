import 'package:creative_gym_mobile/app/app_motion.dart';
import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/features/voting/domain/vote_pair.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/app_back_scope.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/authenticated_media.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key, required this.roomId, this.demoMode = false});

  final String roomId;
  final bool demoMode;

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  late Future<void> _loadFuture;
  GymRoom? _room;
  VotePair? _pair;
  int _votesCount = 0;
  String? _selectedSide;
  bool _isBusy = false;
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final room = await appDependencies.rooms.getRoomById(widget.roomId);
    VotePair? pair;
    if (room != null && (widget.demoMode || room.canVote)) {
      pair = await appDependencies.voting.getNextPair(widget.roomId);
      await _warmPairMedia(pair);
    }
    _room = room;
    _pair = pair;
    _votesCount = room?.votingCompleted ?? pair?.completed ?? 0;
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
        title: const Text('Голосование'),
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncContentTransition(
              stateKey: 'loading',
              child: AsyncLoadingPanel(
                message: 'Загружаем работы...',
                layout: AsyncLoadingLayout.voting,
              ),
            );
          }
          if (snapshot.hasError) {
            return AsyncContentTransition(
              stateKey: 'error',
              child: AsyncErrorPanel(
                message: userErrorMessage(snapshot.error),
                onRetry: _reload,
              ),
            );
          }

          final room = _room;
          if (room == null) {
            return const AsyncContentTransition(
              stateKey: 'missing',
              child: _VotingState(
                title: 'Задание не найдено',
                message: 'Вернитесь к текущему заданию.',
              ),
            );
          }
          if (!widget.demoMode && !room.canVote) {
            return AsyncContentTransition(
              stateKey: 'locked',
              child: _VotingState(
                title: 'Сравнение пока недоступно',
                message: room.deadlineLabel,
              ),
            );
          }
          final pair = _pair;
          if (pair == null) {
            return AsyncContentTransition(
              stateKey: 'complete',
              child: _VotingComplete(
                votesCount: _votesCount,
                alreadyVoted: room.hasCompletedVoting || _votesCount > 0,
              ),
            );
          }

          return AsyncContentTransition(
            stateKey: 'content',
            child: _VotingContent(
              pair: pair,
              current: pair.completed + 1,
              total: pair.target,
              selectedSide: _selectedSide,
              isLocked: _isBusy,
              isAdvancing: _isAdvancing,
              onSelectLeft: () => _select('left'),
              onSelectRight: () => _select('right'),
              onNext: _submitVote,
              onOpenFullscreen: (initialPage) =>
                  _openFullscreen(pair, initialPage),
            ),
          );
        },
      ),
    );
  }

  void _select(String side) {
    if (_isBusy || _pair == null) {
      return;
    }
    setState(() => _selectedSide = side);
  }

  Future<void> _submitVote() async {
    final pair = _pair;
    final selectedSide = _selectedSide;
    if (_isBusy || pair == null || selectedSide == null) {
      return;
    }
    final chosenSubmissionId = selectedSide == 'left'
        ? pair.leftSubmissionId
        : pair.rightSubmissionId;
    setState(() {
      _isBusy = true;
      _isAdvancing = true;
    });
    var voteSaved = false;
    try {
      await appDependencies.voting.castVote(
        widget.roomId,
        pair,
        chosenSubmissionId,
      );
      voteSaved = true;
      final nextPair = await appDependencies.voting.getNextPair(widget.roomId);
      await _warmPairMedia(nextPair);
      if (!mounted) {
        return;
      }
      setState(() {
        _votesCount++;
        _pair = nextPair;
        _selectedSide = null;
        _isBusy = false;
        _isAdvancing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (voteSaved) {
          _votesCount++;
          _selectedSide = null;
          _loadFuture = _load();
        }
        _isBusy = false;
        _isAdvancing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userErrorMessage(error))));
    }
  }

  Future<void> _warmPairMedia(VotePair? pair) async {
    if (pair == null) {
      return;
    }
    final urls = [
      pair.leftMediaUrl,
      pair.rightMediaUrl,
    ].where((url) => url.isNotEmpty).toSet();
    await Future.wait(
      urls.map((url) async {
        try {
          await appDependencies.media.load(url);
        } catch (_) {
          // The gradient remains usable if a private preview cannot be warmed.
        }
      }),
    );
  }

  Future<void> _openFullscreen(VotePair pair, int initialPage) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _VotePairViewer(pair: pair, initialPage: initialPage),
      ),
    );
  }
}

class _VotingContent extends StatelessWidget {
  const _VotingContent({
    required this.pair,
    required this.current,
    required this.total,
    required this.selectedSide,
    required this.isLocked,
    required this.isAdvancing,
    required this.onSelectLeft,
    required this.onSelectRight,
    required this.onNext,
    required this.onOpenFullscreen,
  });

  final VotePair pair;
  final int current;
  final int total;
  final String? selectedSide;
  final bool isLocked;
  final bool isAdvancing;
  final VoidCallback onSelectLeft;
  final VoidCallback onSelectRight;
  final VoidCallback onNext;
  final ValueChanged<int> onOpenFullscreen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Какой кадр сильнее?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$current из $total',
            key: const ValueKey('vote-progress'),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final scale = Tween<double>(
                    begin: 0.985,
                    end: 1,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: scale, child: child),
                  );
                },
                child: isAdvancing
                    ? const _AdvancingVotePair(
                        key: ValueKey('advancing-vote-pair'),
                      )
                    : Row(
                        key: ValueKey('vote-pair-${pair.id}'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 4 / 5,
                              child: _PhotoChoice(
                                semanticsLabel: pair.leftLabel,
                                mediaUrl: pair.leftMediaUrl,
                                palette: pair.leftPalette,
                                selected: selectedSide == 'left',
                                dimmed: selectedSide == 'right',
                                onTap: isLocked ? null : onSelectLeft,
                                onOpenFullscreen: () => onOpenFullscreen(0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 4 / 5,
                              child: _PhotoChoice(
                                semanticsLabel: pair.rightLabel,
                                mediaUrl: pair.rightMediaUrl,
                                palette: pair.rightPalette,
                                selected: selectedSide == 'right',
                                dimmed: selectedSide == 'left',
                                onTap: isLocked ? null : onSelectRight,
                                onOpenFullscreen: () => onOpenFullscreen(1),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isAdvancing
                ? 'Готовим следующую пару'
                : selectedSide == null
                ? 'Выберите одну фотографию'
                : 'Выбор сделан',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: selectedSide == null
                  ? AppTheme.mutedInk
                  : AppTheme.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          IgnorePointer(
            ignoring: isLocked || selectedSide == null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              opacity: isLocked || selectedSide == null ? 0.42 : 1,
              child: GlassButton(
                key: const ValueKey('submit-vote-button'),
                label: isAdvancing ? 'Следующая пара…' : 'Далее',
                onPressed: onNext,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancingVotePair extends StatelessWidget {
  const _AdvancingVotePair({super.key});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE3E8E3);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < 2; index++) ...[
          if (index > 0) const SizedBox(width: 12),
          Expanded(
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  border: Border.all(color: AppTheme.surfaceStroke),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoChoice extends StatelessWidget {
  const _PhotoChoice({
    required this.semanticsLabel,
    required this.mediaUrl,
    required this.palette,
    required this.selected,
    required this.dimmed,
    required this.onTap,
    required this.onOpenFullscreen,
  });

  final String semanticsLabel;
  final String mediaUrl;
  final VotePhotoPalette palette;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;
  final VoidCallback onOpenFullscreen;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(palette.start),
            Color(palette.middle),
            Color(palette.end),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
        opacity: dimmed ? 0.45 : 1,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('vote-$semanticsLabel'),
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AuthenticatedMedia(mediaUrl: mediaUrl, fallback: fallback),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    key: ValueKey('fullscreen-$semanticsLabel'),
                    tooltip: 'Открыть полностью',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x99000000),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onOpenFullscreen,
                    icon: const Icon(Icons.fullscreen_rounded),
                  ),
                ),
                IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primaryDark
                            : Colors.transparent,
                        width: 4,
                      ),
                    ),
                  ),
                ),
                if (selected)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: IgnorePointer(
                      child:
                          const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.check,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                              )
                              .animate(
                                key: ValueKey('vote-check-$semanticsLabel'),
                              )
                              .fadeIn(
                                duration: AppMotion.duration(
                                  context,
                                  AppMotion.quick,
                                ),
                              )
                              .scaleXY(
                                begin: AppMotion.isReduced(context) ? 1 : 0.72,
                                end: 1,
                                duration: AppMotion.duration(
                                  context,
                                  AppMotion.standard,
                                ),
                                curve: Curves.easeOutBack,
                              ),
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

class _VotePairViewer extends StatefulWidget {
  const _VotePairViewer({required this.pair, required this.initialPage});

  final VotePair pair;
  final int initialPage;

  @override
  State<_VotePairViewer> createState() => _VotePairViewerState();
}

class _VotePairViewerState extends State<_VotePairViewer> {
  late final PageController _controller;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(0, 1);
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
          PageView(
            key: const ValueKey('vote-fullscreen-viewer'),
            controller: _controller,
            onPageChanged: (value) => setState(() => _page = value),
            children: [
              _FullscreenVotePhoto(
                mediaUrl: widget.pair.leftMediaUrl,
                palette: widget.pair.leftPalette,
                label: widget.pair.leftLabel,
              ),
              _FullscreenVotePhoto(
                mediaUrl: widget.pair.rightMediaUrl,
                palette: widget.pair.rightPalette,
                label: widget.pair.rightLabel,
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 0,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton.filled(
                    key: const ValueKey('close-vote-fullscreen'),
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
                        '${_page + 1} из 2',
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
        ],
      ),
    );
  }
}

class _FullscreenVotePhoto extends StatelessWidget {
  const _FullscreenVotePhoto({
    required this.mediaUrl,
    required this.palette,
    required this.label,
  });

  final String mediaUrl;
  final VotePhotoPalette palette;
  final String label;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(palette.start),
            Color(palette.middle),
            Color(palette.end),
          ],
        ),
      ),
    );
    return Semantics(
      image: true,
      label: label,
      child: Center(
        child: SizedBox.expand(
          child: AuthenticatedMedia(
            mediaUrl: mediaUrl,
            fallback: fallback,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _VotingComplete extends StatelessWidget {
  const _VotingComplete({required this.votesCount, required this.alreadyVoted});

  final int votesCount;
  final bool alreadyVoted;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
                  Icons.check_circle_outline,
                  size: 44,
                  color: AppTheme.primaryDark,
                )
                .animate(key: const ValueKey('voting-complete-check'))
                .fadeIn(
                  duration: AppMotion.duration(context, AppMotion.standard),
                )
                .scaleXY(
                  begin: AppMotion.isReduced(context) ? 1 : 0.78,
                  end: 1,
                  duration: AppMotion.duration(context, AppMotion.expressive),
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 16),
            Text(
              alreadyVoted ? 'Вы уже проголосовали' : 'Пар для голосования нет',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              votesCount == 0
                  ? 'Здесь появятся пары, когда будет достаточно работ.'
                  : 'Ваши выборы сохранены: $votesCount.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: GlassButton(
                label: 'К челленджам',
                onPressed: () => context.go(AppRoutes.challenges),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VotingState extends StatelessWidget {
  const _VotingState({required this.title, required this.message});

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
