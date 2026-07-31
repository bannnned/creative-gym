import 'dart:async';
import 'dart:typed_data';

import 'package:creative_gym_mobile/app/app_motion.dart';
import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/features/challenges/domain/weekly_workout.dart';
import 'package:creative_gym_mobile/shared/widgets/app_glass_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/onboarding_coach_mark.dart';
import 'package:creative_gym_mobile/shared/widgets/soft_memory_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class ChallengeSelectionScreen extends StatefulWidget {
  const ChallengeSelectionScreen({super.key});

  @override
  State<ChallengeSelectionScreen> createState() =>
      _ChallengeSelectionScreenState();
}

class _ChallengeSelectionScreenState extends State<ChallengeSelectionScreen> {
  late Future<List<WeeklyWorkout>> _workoutsFuture;
  final _challengeTargetKey = GlobalKey();
  bool _onboardingScheduled = false;
  bool _onboardingTargetActive = true;
  int _onboardingTargetAttempts = 0;

  @override
  void initState() {
    super.initState();
    _workoutsFuture = appDependencies.challenges.getActiveWorkouts();
  }

  void _reload() {
    setState(() {
      _workoutsFuture = appDependencies.challenges.getActiveWorkouts();
    });
  }

  Future<void> _openChallenge(WeeklyWorkout workout) async {
    await context.push(AppRoutes.challengeDetails(workout.id));
    if (mounted) {
      _reload();
    }
  }

  Future<void> _performAction(WeeklyWorkout workout) async {
    final location = switch (workout.nextAction) {
      ChallengeNextAction.upload when workout.roomId.isNotEmpty =>
        AppRoutes.roomUpload(workout.roomId),
      ChallengeNextAction.vote when workout.roomId.isNotEmpty =>
        AppRoutes.roomVote(workout.roomId),
      ChallengeNextAction.viewResults when workout.roomId.isNotEmpty =>
        AppRoutes.roomResults(workout.roomId),
      _ => AppRoutes.challengeDetails(workout.id),
    };

    await context.push(location);
    if (mounted) {
      _reload();
    }
  }

  Future<void> _openCompletedChallenges(
    List<WeeklyWorkout> completed,
    List<WeeklyWorkout> allWorkouts,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _CompletedChallengesSheet(
        workouts: completed,
        paletteIndexFor: allWorkouts.indexOf,
        onOpen: (workout) {
          Navigator.pop(sheetContext);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              unawaited(_openChallenge(workout));
            }
          });
        },
      ),
    );
  }

  Future<void> _openProfile() async {
    await context.push(AppRoutes.profile);
    if (!mounted) {
      return;
    }
    _onboardingScheduled = false;
    _onboardingTargetActive = true;
    _onboardingTargetAttempts = 0;
    setState(() {});
  }

  void _scheduleOnboarding(WeeklyWorkout? workout) {
    if (_onboardingScheduled || workout == null) {
      return;
    }
    _onboardingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showOnboarding(workout));
    });
  }

  Future<void> _showOnboarding(WeeklyWorkout workout) async {
    if (!await appDependencies.onboarding.shouldShowSelection()) {
      _deactivateOnboardingTarget();
      return;
    }
    if (!mounted || _challengeTargetKey.currentContext == null) {
      _onboardingScheduled = false;
      if (mounted && _onboardingTargetAttempts < 3) {
        _onboardingTargetAttempts++;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scheduleOnboarding(workout);
          }
        });
      }
      return;
    }

    var openTargetAfterFinish = false;
    final tutorial = createOnboardingCoachMark(
      context: context,
      steps: [
        OnboardingCoachStep(
          id: 'challenge-selection',
          targetKey: _challengeTargetKey,
          title: 'Выбери челлендж',
          body: 'Внутри — тема, сроки и одна фотография.',
        ),
      ],
      onTargetTap: (_) {
        openTargetAfterFinish = true;
      },
      onFinish: () {
        unawaited(
          _finishSelectionOnboarding(
            openWorkout: openTargetAfterFinish ? workout : null,
          ),
        );
      },
      onSkip: () => unawaited(_skipOnboarding()),
    );
    tutorial.show(context: context, rootOverlay: true);
  }

  Future<void> _finishSelectionOnboarding({WeeklyWorkout? openWorkout}) async {
    await appDependencies.onboarding.markSelectionSeen();
    _deactivateOnboardingTarget();
    if (openWorkout != null && mounted) {
      await _openChallenge(openWorkout);
    }
  }

  Future<void> _skipOnboarding() async {
    await appDependencies.onboarding.skip();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deactivateOnboardingTarget();
    });
  }

  void _deactivateOnboardingTarget() {
    if (!mounted || !_onboardingTargetActive) {
      return;
    }
    setState(() => _onboardingTargetActive = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppGlassScaffold(
      title: 'Челленджи',
      actions: [
        AppGlassHeaderAction(
          key: const ValueKey('profile-button'),
          icon: Icons.person_outline_rounded,
          semanticLabel: 'Профиль',
          onPressed: _openProfile,
        ),
      ],
      body: FutureBuilder<List<WeeklyWorkout>>(
        future: _workoutsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const AsyncContentTransition(
              stateKey: 'loading',
              child: AsyncLoadingPanel(
                message: 'Загружаем челленджи...',
                layout: AsyncLoadingLayout.list,
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

          final workouts = snapshot.data ?? const [];
          if (workouts.isEmpty) {
            return AsyncContentTransition(
              stateKey: 'empty',
              child: _EmptyChallenges(onRetry: _reload),
            );
          }

          final primaryWorkout = _primaryWorkout(workouts);
          final otherWorkouts =
              workouts
                  .where(
                    (workout) =>
                        workout.id != primaryWorkout.id &&
                        workout.stage != WeeklyWorkoutStage.results,
                  )
                  .toList()
                ..sort(
                  (left, right) =>
                      left.homePriority.compareTo(right.homePriority),
                );
          final completedWorkouts = workouts
              .where(
                (workout) =>
                    workout.id != primaryWorkout.id &&
                    workout.stage == WeeklyWorkoutStage.results,
              )
              .toList(growable: false);
          _scheduleOnboarding(primaryWorkout);
          return AsyncContentTransition(
            stateKey: 'content',
            child: RefreshIndicator(
              onRefresh: () async {
                _reload();
                await _workoutsFuture;
              },
              child: ListView(
                key: const ValueKey('challenge-list'),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  const _SectionTitle(
                    key: ValueKey('current-challenge-section'),
                    title: 'Сейчас',
                  ),
                  _ChallengeCard(
                    key: _onboardingTargetActive ? _challengeTargetKey : null,
                    workout: primaryWorkout,
                    paletteIndex: workouts.indexOf(primaryWorkout),
                    featured: true,
                    onTap: () => _openChallenge(primaryWorkout),
                    onAction: () => _performAction(primaryWorkout),
                  ),
                  if (otherWorkouts.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      key: ValueKey('other-challenges-section'),
                      title: 'Другие челленджи',
                    ),
                    for (final workout in otherWorkouts) ...[
                      _ChallengeCard(
                        workout: workout,
                        paletteIndex: workouts.indexOf(workout),
                        onTap: () => _openChallenge(workout),
                        onAction: () => _performAction(workout),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                  if (completedWorkouts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _CompletedChallengesRow(
                      count: completedWorkouts.length,
                      onTap: () =>
                          _openCompletedChallenges(completedWorkouts, workouts),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  WeeklyWorkout _primaryWorkout(List<WeeklyWorkout> workouts) {
    final current = workouts
        .where((workout) => workout.stage != WeeklyWorkoutStage.results)
        .toList();
    final candidates = current.isNotEmpty ? current : workouts.toList();
    candidates.sort((left, right) {
      final priority = left.homePriority.compareTo(right.homePriority);
      if (priority != 0) {
        return priority;
      }
      return workouts.indexOf(left).compareTo(workouts.indexOf(right));
    });
    return candidates.first;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CompletedChallengesRow extends StatelessWidget {
  const _CompletedChallengesRow({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          key: const ValueKey('completed-challenges-button'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 2,
          ),
          title: const Text(
            'Завершённые',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text('$count ${count == 1 ? 'челлендж' : 'челленджа'}'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _CompletedChallengesSheet extends StatelessWidget {
  const _CompletedChallengesSheet({
    required this.workouts,
    required this.paletteIndexFor,
    required this.onOpen,
  });

  final List<WeeklyWorkout> workouts;
  final int Function(WeeklyWorkout workout) paletteIndexFor;
  final ValueChanged<WeeklyWorkout> onOpen;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: ListView(
        key: const ValueKey('completed-challenges-list'),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Text(
            'Завершённые',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          for (final workout in workouts) ...[
            _ChallengeCard(
              workout: workout,
              paletteIndex: paletteIndexFor(workout),
              onTap: () => onOpen(workout),
              onAction: () => onOpen(workout),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatefulWidget {
  const _ChallengeCard({
    super.key,
    required this.workout,
    required this.paletteIndex,
    required this.onTap,
    required this.onAction,
    this.featured = false,
  });

  final WeeklyWorkout workout;
  final int paletteIndex;
  final VoidCallback onTap;
  final VoidCallback onAction;
  final bool featured;

  @override
  State<_ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<_ChallengeCard> {
  late Future<Uint8List?> _coverFuture;

  @override
  void initState() {
    super.initState();
    _coverFuture = appDependencies.challenges.loadCover(widget.workout);
  }

  @override
  void didUpdateWidget(covariant _ChallengeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workout.coverUrl != widget.workout.coverUrl) {
      _coverFuture = appDependencies.challenges.loadCover(widget.workout);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);

    return Semantics(
          button: true,
          label:
              '${widget.workout.title}. '
              '${widget.workout.guidanceLabel}. '
              '${widget.workout.actionLabel}',
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey('challenge-card-${widget.workout.id}'),
              onTap: widget.onTap,
              child: AspectRatio(
                aspectRatio: widget.featured ? 16 / 11 : 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FutureBuilder<Uint8List?>(
                      future: _coverFuture,
                      builder: (context, snapshot) {
                        final bytes = snapshot.data;
                        if (bytes != null && bytes.isNotEmpty) {
                          return SoftMemoryImage(
                            bytes: bytes,
                            placeholder: _FallbackCover(
                              paletteIndex: widget.paletteIndex,
                            ),
                            revealKey:
                                'challenge-cover-${widget.workout.id}-${widget.workout.coverUrl}',
                            fit: BoxFit.cover,
                          );
                        }

                        return _FallbackCover(
                          paletteIndex: widget.paletteIndex,
                        );
                      },
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.25, 1],
                          colors: [Colors.transparent, Color(0xD9000000)],
                        ),
                      ),
                    ),
                    if (widget.featured)
                      Positioned(
                        left: 18,
                        top: 18,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xD9FFFFFF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            child: Text(
                              'ГЛАВНОЕ СЕЙЧАС',
                              style: TextStyle(
                                color: AppTheme.primaryDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.workout.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x66000000),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            widget.workout.guidanceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: const Color(0xE6FFFFFF),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.workout.submissionDeadlineLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: const Color(0xCCFFFFFF),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilledButton(
                                key: ValueKey(
                                  'challenge-action-${widget.workout.id}',
                                ),
                                onPressed: widget.onAction,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                  ),
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryDark,
                                  elevation: 0,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(widget.workout.actionLabel),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 17,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(
          delay: AppMotion.delay(
            context,
            Duration(milliseconds: widget.paletteIndex * 45),
          ),
        )
        .fadeIn(duration: AppMotion.duration(context, AppMotion.standard))
        .slideY(
          begin: 0.035,
          end: 0,
          duration: AppMotion.duration(context, AppMotion.standard),
          curve: Curves.easeOutCubic,
        );
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({required this.paletteIndex});

  final int paletteIndex;

  static const _palettes = [
    [Color(0xFF677C6C), Color(0xFF273C35)],
    [Color(0xFF9B725F), Color(0xFF49352F)],
    [Color(0xFF64778C), Color(0xFF2E3948)],
    [Color(0xFF8A8066), Color(0xFF3F3B31)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _palettes[paletteIndex % _palettes.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -34,
            right: -24,
            child: _SoftCircle(
              size: 170,
              color: Colors.white.withValues(alpha: 0.11),
            ),
          ),
          Positioned(
            left: 36,
            bottom: 24,
            child: _SoftCircle(
              size: 100,
              color: Colors.black.withValues(alpha: 0.09),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EmptyChallenges extends StatelessWidget {
  const _EmptyChallenges({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Челленджей пока нет',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Загляните немного позже.'),
            const SizedBox(height: 18),
            TextButton(onPressed: onRetry, child: const Text('Обновить')),
          ],
        ),
      ),
    );
  }
}
