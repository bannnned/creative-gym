import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/features/rooms/data/mock_gym_rooms.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GymRoomScreen extends StatelessWidget {
  const GymRoomScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    final room = findMockGymRoomById(roomId);

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () {
            if (room == null) {
              context.go(AppRoutes.challenges);
              return;
            }

            context.go(AppRoutes.challengeDetails(room.challengeId));
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Gym Room'),
      ),
      body: room == null ? const _MissingRoom() : _GymRoomContent(room: room),
    );
  }
}

class _GymRoomContent extends StatelessWidget {
  const _GymRoomContent({required this.room});

  final GymRoom room;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text(
          room.challengeTitle,
          style: textTheme.headlineMedium?.copyWith(
            color: AppTheme.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          room.challengeTheme,
          style: textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _RoomChip(icon: Icons.flag_outlined, label: room.phaseLabel),
            _RoomChip(icon: Icons.schedule, label: room.deadlineLabel),
            _RoomChip(
              icon: Icons.groups_outlined,
              label: room.participantsLabel,
            ),
          ],
        ),
        const SizedBox(height: 26),
        _SubmissionPanel(room: room),
        const SizedBox(height: 18),
        _RoomProgressPanel(room: room),
      ],
    );
  }
}

class _SubmissionPanel extends StatelessWidget {
  const _SubmissionPanel({required this.room});

  final GymRoom room;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                room.hasSubmission
                    ? Icons.check_circle_outline
                    : Icons.add_photo_alternate_outlined,
                color: const Color(0xFF2F6F5E),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.submissionStatusLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      room.nextStepLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF516158),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (room.canUpload)
            GlassButton(
              onPressed: () => context.go(AppRoutes.roomUpload(room.id)),
              icon: room.hasSubmission ? Icons.swap_horiz : Icons.upload,
              label: room.hasSubmission ? 'Заменить фото' : 'Добавить фото',
              variant: room.hasSubmission
                  ? GlassButtonVariant.tonal
                  : GlassButtonVariant.primary,
              minHeight: 48,
            )
          else
            _LockedActionNote(
              icon: room.hasSubmission
                  ? Icons.lock_clock_outlined
                  : Icons.hourglass_empty,
              label: room.phase == GymRoomPhase.upcoming
                  ? 'Загрузка откроется после старта.'
                  : 'Загрузка фото сейчас закрыта.',
            ),
        ],
      ),
    );
  }
}

class _RoomProgressPanel extends StatelessWidget {
  const _RoomProgressPanel({required this.room});

  final GymRoom room;

  @override
  Widget build(BuildContext context) {
    final progress = room.participantCount / room.maxParticipants;

    return GlassPanel(
      tint: const Color(0x99E7F0EA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Состав комнаты',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.white,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${room.participantsLabel} участников. ${room.phaseHelpLabel}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF516158),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          _PhasePrimaryAction(room: room),
          const SizedBox(height: 14),
          _DemoShortcuts(room: room),
        ],
      ),
    );
  }
}

class _PhasePrimaryAction extends StatelessWidget {
  const _PhasePrimaryAction({required this.room});

  final GymRoom room;

  @override
  Widget build(BuildContext context) {
    return switch (room.phase) {
      GymRoomPhase.upcoming => const _LockedActionNote(
        icon: Icons.notifications_active_outlined,
        label: 'Мы покажем CTA, когда Weekly Workout начнется.',
      ),
      GymRoomPhase.submission => const _LockedActionNote(
        icon: Icons.compare_arrows,
        label: 'Голосование откроется после дедлайна приема работ.',
      ),
      GymRoomPhase.voting => GlassButton(
        onPressed: () => context.go(AppRoutes.roomVote(room.id)),
        icon: Icons.compare_arrows,
        label: 'Начать голосование',
        minHeight: 48,
      ),
      GymRoomPhase.results => GlassButton(
        onPressed: () => context.go(AppRoutes.roomResults(room.id)),
        icon: Icons.emoji_events_outlined,
        label: 'Посмотреть результаты',
        minHeight: 48,
      ),
    };
  }
}

class _DemoShortcuts extends StatelessWidget {
  const _DemoShortcuts({required this.room});

  final GymRoom room;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(12),
      tint: Colors.white.withValues(alpha: 0.26),
      radius: AppTheme.radiusM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Demo shortcuts',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.mutedInk,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  onPressed: () =>
                      context.go(AppRoutes.roomVote(room.id, demo: true)),
                  icon: Icons.compare_arrows,
                  label: 'Voting',
                  variant: GlassButtonVariant.quiet,
                  minHeight: 44,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassButton(
                  onPressed: () =>
                      context.go(AppRoutes.roomResults(room.id, demo: true)),
                  icon: Icons.emoji_events_outlined,
                  label: 'Results',
                  variant: GlassButtonVariant.quiet,
                  minHeight: 44,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LockedActionNote extends StatelessWidget {
  const _LockedActionNote({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.mutedInk),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomChip extends StatelessWidget {
  const _RoomChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SoftChip(icon: icon, label: label);
  }
}

class _MissingRoom extends StatelessWidget {
  const _MissingRoom();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.meeting_room_outlined,
              size: 44,
              color: Color(0xFF6A746D),
            ),
            const SizedBox(height: 12),
            Text(
              'Комната не найдена',
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
