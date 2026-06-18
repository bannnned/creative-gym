import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/features/challenges/domain/weekly_workout.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WeeklyWorkoutsScreen extends StatefulWidget {
  const WeeklyWorkoutsScreen({super.key});

  @override
  State<WeeklyWorkoutsScreen> createState() => _WeeklyWorkoutsScreenState();
}

class _WeeklyWorkoutsScreenState extends State<WeeklyWorkoutsScreen> {
  late Future<List<WeeklyWorkout>> _workoutsFuture;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  void _loadWorkouts() {
    setState(() {
      _workoutsFuture = appDependencies.challenges.getActiveWorkouts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () => context.go(AppRoutes.login),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Weekly Workouts'),
      ),
      body: FutureBuilder<List<WeeklyWorkout>>(
        future: _workoutsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncLoadingPanel(
              message: 'Загрузка Weekly Workouts...',
            );
          }

          if (snapshot.hasError) {
            return AsyncErrorPanel(
              message: snapshot.error.toString(),
              onRetry: _loadWorkouts,
            );
          }

          final workouts = snapshot.data ?? const <WeeklyWorkout>[];
          final sections = _WorkoutSectionData.sections(workouts);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              const _WeeklyWorkoutsHeader(),
              const SizedBox(height: 18),
              for (final section in sections)
                if (section.workouts.isNotEmpty) ...[
                  _WeeklyWorkoutSection(section: section),
                  const SizedBox(height: 22),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _WorkoutSectionData {
  const _WorkoutSectionData({
    required this.title,
    required this.description,
    required this.icon,
    required this.workouts,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<WeeklyWorkout> workouts;

  static List<_WorkoutSectionData> sections(List<WeeklyWorkout> workouts) {
    return [
      _WorkoutSectionData(
        title: 'Прием работ',
        description: 'Можно присоединиться и загрузить одну фотографию.',
        icon: Icons.add_photo_alternate_outlined,
        workouts: _byPhase(workouts, 'Прием работ'),
      ),
      _WorkoutSectionData(
        title: 'Голосование сейчас',
        description: 'Анонимные пары открыты для joined Gym Rooms.',
        icon: Icons.compare_arrows,
        workouts: _byPhase(workouts, 'Голосование'),
      ),
      _WorkoutSectionData(
        title: 'Завершенные',
        description: 'Результаты комнаты уже можно посмотреть.',
        icon: Icons.emoji_events_outlined,
        workouts: _byPhase(workouts, 'Результаты'),
      ),
      _WorkoutSectionData(
        title: 'Скоро',
        description: 'Тренировки, которые появятся следующими.',
        icon: Icons.schedule,
        workouts: _byPhase(workouts, 'Скоро старт'),
      ),
    ];
  }

  static List<WeeklyWorkout> _byPhase(
    List<WeeklyWorkout> workouts,
    String phase,
  ) {
    return workouts
        .where((workout) => workout.phase == phase)
        .toList(growable: false);
  }
}

class _WeeklyWorkoutsHeader extends StatelessWidget {
  const _WeeklyWorkoutsHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Активные фото-тренировки',
            style: textTheme.headlineSmall?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Выберите Weekly Workout, чтобы попасть в небольшую Gym Room и выполнить одно фото-задание за неделю.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedInk,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyWorkoutSection extends StatelessWidget {
  const _WeeklyWorkoutSection({required this.section});

  final _WorkoutSectionData section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.44),
                border: Border.all(color: Colors.white.withValues(alpha: 0.56)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Icon(
                  section.icon,
                  color: AppTheme.primaryDark,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    section.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedInk,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SoftChip(
              icon: Icons.layers_outlined,
              label: '${section.workouts.length}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final workout in section.workouts) ...[
          _WeeklyWorkoutCard(workout: workout),
          if (workout != section.workouts.last) const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _WeeklyWorkoutCard extends StatelessWidget {
  const _WeeklyWorkoutCard({required this.workout});

  final WeeklyWorkout workout;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      key: ValueKey('weekly-workout-${workout.id}'),
      onTap: () => context.go(AppRoutes.challengeDetails(workout.id)),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WorkoutVisual(workout: workout),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedInk,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _MetaCapsule(
                      icon: Icons.schedule,
                      label: workout.submissionDeadlineLabel,
                    ),
                    _MetaCapsule(
                      icon: Icons.groups_outlined,
                      label: workout.participantsLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    onPressed: () =>
                        context.go(AppRoutes.challengeDetails(workout.id)),
                    icon: workout.isJoined
                        ? Icons.meeting_room_outlined
                        : Icons.arrow_forward,
                    label: workout.isJoined ? 'Открыть Gym Room' : 'Подробнее',
                    variant: workout.isJoined
                        ? GlassButtonVariant.primary
                        : GlassButtonVariant.tonal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutVisual extends StatelessWidget {
  const _WorkoutVisual({required this.workout});

  final WeeklyWorkout workout;

  @override
  Widget build(BuildContext context) {
    final palette = _PhotoPalette.forWorkout(workout.id);
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 204,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.colors,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.72, -0.68),
                  radius: 0.86,
                  colors: [
                    Colors.white.withValues(alpha: 0.5),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: 26,
            child: _PhotoBlob(
              size: 116,
              color: palette.highlight.withValues(alpha: 0.34),
            ),
          ),
          Positioned(
            right: -26,
            top: -18,
            child: _SoftRing(color: Colors.white.withValues(alpha: 0.28)),
          ),
          Positioned(
            right: 24,
            bottom: -28,
            child: _SoftRing(color: Colors.white.withValues(alpha: 0.14)),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: _PhotoStatusBadge(label: workout.phase),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.56),
                    Colors.white.withValues(alpha: 0.88),
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
              child: const SizedBox(height: 74),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  workout.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.32),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  workout.theme,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPalette {
  const _PhotoPalette({required this.colors, required this.highlight});

  final List<Color> colors;
  final Color highlight;

  static _PhotoPalette forWorkout(String id) {
    return switch (id) {
      'morning-light' => const _PhotoPalette(
        colors: [Color(0xFFE8B96E), Color(0xFF8ABBAA), Color(0xFF173F35)],
        highlight: Color(0xFFFFE1A6),
      ),
      'quiet-motion' => const _PhotoPalette(
        colors: [Color(0xFFAFCDF4), Color(0xFF87A89B), Color(0xFF24334D)],
        highlight: Color(0xFFDBEAFF),
      ),
      'evening-shapes' => const _PhotoPalette(
        colors: [Color(0xFFDDBB8D), Color(0xFFC66A4A), Color(0xFF17211C)],
        highlight: Color(0xFFFFD4A8),
      ),
      _ => const _PhotoPalette(
        colors: [Color(0xFFE9B9A6), Color(0xFFA9CEB0), Color(0xFF6E4654)],
        highlight: Color(0xFFF2D6C8),
      ),
    };
  }
}

class _PhotoBlob extends StatelessWidget {
  const _PhotoBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.42),
      ),
    );
  }
}

class _SoftRing extends StatelessWidget {
  const _SoftRing({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 20),
      ),
    );
  }
}

class _PhotoStatusBadge extends StatelessWidget {
  const _PhotoStatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MetaCapsule extends StatelessWidget {
  const _MetaCapsule({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.mutedInk),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
