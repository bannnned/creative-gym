import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/features/voting/domain/vote_pair.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/authenticated_media.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:flutter/material.dart';
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
    }
    _room = room;
    _pair = pair;
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
        title: const Text('Сравнение'),
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
            return const _VotingState(
              title: 'Задание не найдено',
              message: 'Вернитесь к текущему заданию.',
            );
          }
          if (!widget.demoMode && !room.canVote) {
            return _VotingState(
              title: 'Сравнение пока недоступно',
              message: room.deadlineLabel,
            );
          }
          final pair = _pair;
          if (pair == null) {
            return _VotingComplete(
              roomId: room.id,
              votesCount: _votesCount,
              demoMode: widget.demoMode,
            );
          }

          return _VotingContent(
            pair: pair,
            current: pair.completed + 1,
            total: pair.target,
            selectedSide: _selectedSide,
            isLocked: _isBusy,
            onVoteLeft: () => _vote('left', pair.leftSubmissionId),
            onVoteRight: () => _vote('right', pair.rightSubmissionId),
            onSkip: _skip,
          );
        },
      ),
    );
  }

  Future<void> _vote(String side, String chosenSubmissionId) async {
    final pair = _pair;
    if (_isBusy || pair == null) {
      return;
    }
    setState(() {
      _selectedSide = side;
      _isBusy = true;
    });
    try {
      await appDependencies.voting.castVote(
        widget.roomId,
        pair,
        chosenSubmissionId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 220));
      final nextPair = await appDependencies.voting.getNextPair(widget.roomId);
      if (!mounted) {
        return;
      }
      setState(() {
        _votesCount++;
        _pair = nextPair;
        _selectedSide = null;
        _isBusy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedSide = null;
        _isBusy = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userErrorMessage(error))));
    }
  }

  Future<void> _skip() async {
    final pair = _pair;
    if (_isBusy || pair == null) {
      return;
    }
    setState(() => _isBusy = true);
    try {
      await appDependencies.voting.skip(widget.roomId, pair);
      final nextPair = await appDependencies.voting.getNextPair(widget.roomId);
      if (!mounted) {
        return;
      }
      setState(() {
        _pair = nextPair;
        _selectedSide = null;
        _isBusy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userErrorMessage(error))));
    }
  }
}

class _VotingContent extends StatelessWidget {
  const _VotingContent({
    required this.pair,
    required this.current,
    required this.total,
    required this.selectedSide,
    required this.isLocked,
    required this.onVoteLeft,
    required this.onVoteRight,
    required this.onSkip,
  });

  final VotePair pair;
  final int current;
  final int total;
  final String? selectedSide;
  final bool isLocked;
  final VoidCallback onVoteLeft;
  final VoidCallback onVoteRight;
  final VoidCallback onSkip;

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
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _PhotoChoice(
                    semanticsLabel: pair.leftLabel,
                    mediaUrl: pair.leftMediaUrl,
                    palette: pair.leftPalette,
                    selected: selectedSide == 'left',
                    dimmed: selectedSide == 'right',
                    onTap: isLocked ? null : onVoteLeft,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PhotoChoice(
                    semanticsLabel: pair.rightLabel,
                    mediaUrl: pair.rightMediaUrl,
                    palette: pair.rightPalette,
                    selected: selectedSide == 'right',
                    dimmed: selectedSide == 'left',
                    onTap: isLocked ? null : onVoteRight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            selectedSide == null ? 'Нажмите на фотографию' : 'Выбор принят',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: selectedSide == null
                  ? AppTheme.mutedInk
                  : AppTheme.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: isLocked ? null : onSkip,
            child: const Text('Пропустить'),
          ),
        ],
      ),
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
  });

  final String semanticsLabel;
  final String mediaUrl;
  final VotePhotoPalette palette;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;

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
                AnimatedContainer(
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
                if (selected)
                  const Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.check, color: AppTheme.primaryDark),
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

class _VotingComplete extends StatelessWidget {
  const _VotingComplete({
    required this.roomId,
    required this.votesCount,
    required this.demoMode,
  });

  final String roomId;
  final int votesCount;
  final bool demoMode;

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
            ),
            const SizedBox(height: 16),
            Text(
              'Сравнение завершено',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              votesCount == 0
                  ? 'Новых пар пока нет.'
                  : 'Вы сделали $votesCount выборов.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: GlassButton(
                label: 'Посмотреть итог',
                onPressed: () =>
                    context.go(AppRoutes.roomResults(roomId, demo: demoMode)),
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
