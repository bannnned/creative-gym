import 'dart:typed_data';

import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/features/challenges/domain/weekly_workout.dart';
import 'package:creative_gym_mobile/shared/widgets/app_glass_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChallengeSelectionScreen extends StatefulWidget {
  const ChallengeSelectionScreen({super.key});

  @override
  State<ChallengeSelectionScreen> createState() =>
      _ChallengeSelectionScreenState();
}

class _ChallengeSelectionScreenState extends State<ChallengeSelectionScreen> {
  late Future<List<WeeklyWorkout>> _workoutsFuture;

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

  @override
  Widget build(BuildContext context) {
    return AppGlassScaffold(
      title: 'Челленджи',
      actions: [
        AppGlassHeaderAction(
          key: const ValueKey('profile-button'),
          icon: Icons.person_outline_rounded,
          semanticLabel: 'Профиль',
          onPressed: () => context.push(AppRoutes.profile),
        ),
      ],
      body: FutureBuilder<List<WeeklyWorkout>>(
        future: _workoutsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncLoadingPanel(message: 'Загружаем челленджи...');
          }

          if (snapshot.hasError) {
            return AsyncErrorPanel(
              message: userErrorMessage(snapshot.error),
              onRetry: _reload,
            );
          }

          final workouts = snapshot.data ?? const [];
          if (workouts.isEmpty) {
            return _EmptyChallenges(onRetry: _reload);
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _workoutsFuture;
            },
            child: ListView.separated(
              key: const ValueKey('challenge-list'),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: workouts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return _ChallengeCard(
                  workout: workout,
                  paletteIndex: index,
                  onTap: () => _openChallenge(workout),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ChallengeCard extends StatefulWidget {
  const _ChallengeCard({
    required this.workout,
    required this.paletteIndex,
    required this.onTap,
  });

  final WeeklyWorkout workout;
  final int paletteIndex;
  final VoidCallback onTap;

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
          '${widget.workout.submissionDeadlineLabel}',
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('challenge-card-${widget.workout.id}'),
          onTap: widget.onTap,
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FutureBuilder<Uint8List?>(
                  future: _coverFuture,
                  builder: (context, snapshot) {
                    final bytes = snapshot.data;
                    if (bytes != null && bytes.isNotEmpty) {
                      return Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      );
                    }

                    return _FallbackCover(paletteIndex: widget.paletteIndex);
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
                        widget.workout.submissionDeadlineLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xE6FFFFFF),
                          fontWeight: FontWeight.w600,
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
