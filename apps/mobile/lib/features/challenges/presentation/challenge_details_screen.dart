import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/features/challenges/data/mock_weekly_workouts.dart';
import 'package:creative_gym_mobile/features/challenges/domain/weekly_workout.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChallengeDetailsScreen extends StatelessWidget {
  const ChallengeDetailsScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context) {
    final workout = findMockWeeklyWorkoutById(challengeId);

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () => context.go(AppRoutes.challenges),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Challenge Details'),
      ),
      body: workout == null
          ? const _MissingChallenge()
          : _ChallengeDetailsContent(workout: workout),
    );
  }
}

class _ChallengeDetailsContent extends StatelessWidget {
  const _ChallengeDetailsContent({required this.workout});

  final WeeklyWorkout workout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text(
          workout.title,
          style: textTheme.headlineMedium?.copyWith(
            color: AppTheme.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          workout.theme,
          style: textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          workout.description,
          style: textTheme.bodyLarge?.copyWith(
            color: AppTheme.mutedInk,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _DetailChip(icon: Icons.flag_outlined, label: workout.phase),
            _DetailChip(
              icon: Icons.schedule,
              label: workout.submissionDeadlineLabel,
            ),
            _DetailChip(
              icon: Icons.groups_outlined,
              label: workout.roomSizeLabel,
            ),
          ],
        ),
        const SizedBox(height: 26),
        _InfoSection(
          title: 'Формат',
          children: [
            _InfoLine(
              icon: Icons.camera_alt_outlined,
              text: workout.submissionWindowLabel,
            ),
            _InfoLine(
              icon: Icons.compare_arrows,
              text: workout.votingWindowLabel,
            ),
            const _InfoLine(
              icon: Icons.person_off_outlined,
              text: 'Голосование без имен авторов',
            ),
          ],
        ),
        const SizedBox(height: 18),
        _RulesSection(rules: workout.rules),
        const SizedBox(height: 26),
        GlassButton(
          onPressed: () => context.go(AppRoutes.room(workout.roomId)),
          icon: workout.isJoined ? Icons.meeting_room : Icons.add,
          label: workout.isJoined ? 'Открыть Gym Room' : 'Join Gym Room',
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _RulesSection extends StatelessWidget {
  const _RulesSection({required this.rules});

  final List<String> rules;

  @override
  Widget build(BuildContext context) {
    return _InfoSection(
      title: 'Правила',
      children: [
        for (final rule in rules)
          _InfoLine(icon: Icons.check_circle_outline, text: rule),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF516158),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SoftChip(icon: icon, label: label);
  }
}

class _MissingChallenge extends StatelessWidget {
  const _MissingChallenge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_outlined,
              size: 44,
              color: Color(0xFF6A746D),
            ),
            const SizedBox(height: 12),
            Text(
              'Тренировка не найдена',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            GlassButton(
              onPressed: () => context.go(AppRoutes.challenges),
              icon: Icons.arrow_back,
              label: 'Вернуться к Weekly Workouts',
              variant: GlassButtonVariant.tonal,
            ),
          ],
        ),
      ),
    );
  }
}
