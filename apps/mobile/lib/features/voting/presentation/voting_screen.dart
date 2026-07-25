import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/features/voting/data/mock_vote_pairs.dart';
import 'package:creative_gym_mobile/features/voting/domain/vote_pair.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
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
  late Future<GymRoom?> _roomFuture;
  int _currentIndex = 0;
  int _votesCount = 0;
  String? _selectedSide;
  bool _isAdvancing = false;

  bool get _isComplete => _currentIndex >= mockVotePairs.length;

  @override
  void initState() {
    super.initState();
    _roomFuture = appDependencies.rooms.getRoomById(widget.roomId);
  }

  void _reload() {
    setState(() {
      _roomFuture = appDependencies.rooms.getRoomById(widget.roomId);
    });
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
      body: FutureBuilder<GymRoom?>(
        future: _roomFuture,
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

          final room = snapshot.data;
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
          if (mockVotePairs.isEmpty) {
            return const _VotingState(
              title: 'Пока нечего сравнивать',
              message: 'В группе ещё недостаточно фотографий.',
            );
          }
          if (_isComplete) {
            return _VotingComplete(
              roomId: room.id,
              votesCount: _votesCount,
              demoMode: widget.demoMode,
            );
          }

          return _VotingContent(
            pair: mockVotePairs[_currentIndex],
            current: _currentIndex + 1,
            total: mockVotePairs.length,
            selectedSide: _selectedSide,
            isLocked: _isAdvancing,
            onVoteLeft: () => _vote('left'),
            onVoteRight: () => _vote('right'),
            onSkip: _skip,
          );
        },
      ),
    );
  }

  Future<void> _vote(String side) async {
    if (_isAdvancing) {
      return;
    }
    setState(() {
      _selectedSide = side;
      _isAdvancing = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) {
      return;
    }
    setState(() {
      _votesCount += 1;
      _currentIndex += 1;
      _selectedSide = null;
      _isAdvancing = false;
    });
  }

  void _skip() {
    if (_isAdvancing) {
      return;
    }
    setState(() {
      _currentIndex += 1;
      _selectedSide = null;
    });
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
    required this.palette,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final String semanticsLabel;
  final VotePhotoPalette palette;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(
                  color: selected ? AppTheme.primaryDark : Colors.transparent,
                  width: 4,
                ),
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
              child: selected
                  ? const Center(
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
                    )
                  : null,
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
              'Вы сделали $votesCount выбора.',
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
