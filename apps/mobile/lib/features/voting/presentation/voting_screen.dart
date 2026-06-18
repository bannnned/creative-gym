import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/features/voting/data/mock_vote_pairs.dart';
import 'package:creative_gym_mobile/features/voting/domain/vote_pair.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_panel.dart';
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
    _loadRoom();
  }

  void _loadRoom() {
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
          onPressed: () => context.go(AppRoutes.room(widget.roomId)),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Voting'),
      ),
      body: FutureBuilder<GymRoom?>(
        future: _roomFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncLoadingPanel(message: 'Загрузка комнаты...');
          }

          if (snapshot.hasError) {
            return AsyncErrorPanel(
              message: snapshot.error.toString(),
              onRetry: _loadRoom,
            );
          }

          final room = snapshot.data;
          if (room == null) {
            return const _MissingVotingRoom();
          }

          if (!widget.demoMode && !room.canVote) {
            return _VotingUnavailable(room: room);
          }

          if (mockVotePairs.isEmpty) {
            return _VotingEmpty(room: room);
          }

          if (_isComplete) {
            return _VotingComplete(room: room, votesCount: _votesCount);
          }

          return _VotingContent(
            room: room,
            pair: mockVotePairs[_currentIndex],
            currentIndex: _currentIndex,
            total: mockVotePairs.length,
            votesCount: _votesCount,
            selectedSide: _selectedSide,
            isLocked: _isAdvancing,
            onVoteLeft: () => _vote('left'),
            onVoteRight: () => _vote('right'),
            onSkip: _skipPair,
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

    final sideLabel = side == 'left' ? 'левый' : 'правый';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Вы выбрали $sideLabel кадр.')));

    await Future<void>.delayed(const Duration(milliseconds: 360));
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

  void _skipPair() {
    if (_isAdvancing) {
      return;
    }

    setState(() {
      _currentIndex += 1;
      _selectedSide = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Пара пропущена в демо-режиме.')),
    );
  }
}

class _VotingContent extends StatelessWidget {
  const _VotingContent({
    required this.room,
    required this.pair,
    required this.currentIndex,
    required this.total,
    required this.votesCount,
    required this.selectedSide,
    required this.isLocked,
    required this.onVoteLeft,
    required this.onVoteRight,
    required this.onSkip,
  });

  final GymRoom room;
  final VotePair pair;
  final int currentIndex;
  final int total;
  final int votesCount;
  final String? selectedSide;
  final bool isLocked;
  final VoidCallback onVoteLeft;
  final VoidCallback onVoteRight;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final progress = (currentIndex + 1) / total;

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
          'Выберите более сильный анонимный кадр',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 22),
        GlassPanel(
          tint: const Color(0x99E7F0EA),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Пара ${currentIndex + 1} из $total',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '$votesCount выбрано',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.mutedInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: selectedSide == null
                    ? Text(
                        'Тапните по карточке или кнопке выбора.',
                        key: const ValueKey('vote-help'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mutedInk,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : Text(
                        'Выбор принят, загружаем следующую пару...',
                        key: const ValueKey('vote-selected'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _VotePhotoCard(
                label: pair.leftLabel,
                palette: pair.leftPalette,
                onVote: onVoteLeft,
                buttonLabel: 'Выбрать левый',
                isSelected: selectedSide == 'left',
                isDimmed: selectedSide == 'right',
                isLocked: isLocked,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _VotePhotoCard(
                label: pair.rightLabel,
                palette: pair.rightPalette,
                onVote: onVoteRight,
                buttonLabel: 'Выбрать правый',
                isSelected: selectedSide == 'right',
                isDimmed: selectedSide == 'left',
                isLocked: isLocked,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AbsorbPointer(
          absorbing: isLocked,
          child: GlassButton(
            onPressed: onSkip,
            icon: Icons.skip_next_outlined,
            label: 'Пропустить пару',
            variant: GlassButtonVariant.quiet,
            minHeight: 46,
          ),
        ),
      ],
    );
  }
}

class _VotePhotoCard extends StatelessWidget {
  const _VotePhotoCard({
    required this.label,
    required this.palette,
    required this.onVote,
    required this.buttonLabel,
    required this.isSelected,
    required this.isDimmed,
    required this.isLocked,
  });

  final String label;
  final VotePhotoPalette palette;
  final VoidCallback onVote;
  final String buttonLabel;
  final bool isSelected;
  final bool isDimmed;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isDimmed ? 0.58 : 1,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: isSelected ? 1.02 : 1,
        child: GlassPanel(
          onTap: isLocked ? null : onVote,
          tint: isSelected ? const Color(0xCCFFFFFF) : const Color(0xB3FFFFFF),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0),
                      width: 3,
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        right: -30,
                        top: 18,
                        child: _VoteRing(
                          size: 112,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.check,
                                color: AppTheme.primaryDark,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      Center(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AbsorbPointer(
                absorbing: isLocked,
                child: GlassButton(
                  onPressed: onVote,
                  icon: isSelected ? Icons.check_circle_outline : Icons.check,
                  label: isSelected ? 'Выбрано' : buttonLabel,
                  variant: isSelected
                      ? GlassButtonVariant.primary
                      : GlassButtonVariant.tonal,
                  minHeight: 46,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoteRing extends StatelessWidget {
  const _VoteRing({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 20),
      ),
    );
  }
}

class _VotingComplete extends StatelessWidget {
  const _VotingComplete({required this.room, required this.votesCount});

  final GymRoom room;
  final int votesCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassPanel(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppTheme.primaryDark,
                size: 44,
              ),
              const SizedBox(height: 14),
              Text(
                'Голосование завершено',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Вы сравнили $votesCount пары в комнате «${room.challengeTitle}».',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedInk,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              GlassButton(
                onPressed: () =>
                    context.go(AppRoutes.roomResults(room.id, demo: true)),
                icon: Icons.emoji_events_outlined,
                label: 'Посмотреть результаты',
              ),
              const SizedBox(height: 12),
              GlassButton(
                onPressed: () => context.go(AppRoutes.room(room.id)),
                icon: Icons.meeting_room_outlined,
                label: 'Вернуться в Gym Room',
                variant: GlassButtonVariant.tonal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VotingUnavailable extends StatelessWidget {
  const _VotingUnavailable({required this.room});

  final GymRoom room;

  @override
  Widget build(BuildContext context) {
    return _VotingStatePanel(
      icon: Icons.lock_clock_outlined,
      title: 'Голосование пока недоступно',
      message: room.phaseHelpLabel,
      buttonLabel: 'Вернуться в Gym Room',
      onPressed: () => context.go(AppRoutes.room(room.id)),
    );
  }
}

class _VotingEmpty extends StatelessWidget {
  const _VotingEmpty({required this.room});

  final GymRoom room;

  @override
  Widget build(BuildContext context) {
    return _VotingStatePanel(
      icon: Icons.compare_arrows,
      title: 'Нет пар для сравнения',
      message:
          'В этой демо-комнате пока не хватает работ для анонимного голосования.',
      buttonLabel: 'Вернуться в Gym Room',
      onPressed: () => context.go(AppRoutes.room(room.id)),
    );
  }
}

class _MissingVotingRoom extends StatelessWidget {
  const _MissingVotingRoom();

  @override
  Widget build(BuildContext context) {
    return _VotingStatePanel(
      icon: Icons.search_off_outlined,
      title: 'Комната не найдена',
      message: 'Проверьте ссылку или вернитесь к списку Weekly Workouts.',
      buttonLabel: 'Вернуться к Weekly Workouts',
      onPressed: () => context.go(AppRoutes.challenges),
    );
  }
}

class _VotingStatePanel extends StatelessWidget {
  const _VotingStatePanel({
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
