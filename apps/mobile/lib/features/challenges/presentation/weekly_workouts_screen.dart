import 'dart:async';
import 'dart:typed_data';

import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/features/challenges/domain/weekly_workout.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/features/submissions/domain/submission.dart';
import 'package:creative_gym_mobile/shared/widgets/app_glass_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/onboarding_coach_mark.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class WeeklyWorkoutsScreen extends StatefulWidget {
  const WeeklyWorkoutsScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  State<WeeklyWorkoutsScreen> createState() => _WeeklyWorkoutsScreenState();
}

class _WeeklyWorkoutsScreenState extends State<WeeklyWorkoutsScreen> {
  late Future<_HomeData> _homeFuture;
  bool _isJoining = false;
  bool _isUploadingCover = false;
  final _statusTargetKey = GlobalKey();
  final _primaryActionTargetKey = GlobalKey();
  bool _onboardingScheduled = false;
  bool _onboardingTargetsActive = true;

  @override
  void initState() {
    super.initState();
    _homeFuture = _loadHome();
  }

  Future<_HomeData> _loadHome() async {
    final workout = await appDependencies.challenges.getWorkoutById(
      widget.challengeId,
    );
    if (workout == null) {
      return const _HomeData();
    }

    GymRoom? room;
    Submission? submission;
    Uint8List? photoBytes;

    if (workout.isJoined && workout.roomId.isNotEmpty) {
      room = await appDependencies.rooms.getRoomById(workout.roomId);
      if (room != null && room.hasSubmission) {
        submission = await appDependencies.submissions.getMine(room.id);
        if (submission != null) {
          try {
            photoBytes = await appDependencies.submissions.loadMedia(
              submission,
            );
          } catch (_) {
            // A missing preview must not hide the next useful action.
          }
        }
      }
    }

    return _HomeData(
      workout: workout,
      room: room,
      submission: submission,
      photoBytes: photoBytes,
    );
  }

  void _reload() {
    setState(() {
      _homeFuture = _loadHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppGlassScaffold(
      showBackButton: true,
      body: FutureBuilder<_HomeData>(
        future: _homeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncContentTransition(
              stateKey: 'loading',
              child: AsyncLoadingPanel(
                message: 'Загружаем задание...',
                layout: AsyncLoadingLayout.detail,
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

          final data = snapshot.data ?? const _HomeData();
          if (data.workout == null) {
            return AsyncContentTransition(
              stateKey: 'empty',
              child: _EmptyHome(onRetry: _reload),
            );
          }

          _scheduleOnboarding(data);
          return AsyncContentTransition(
            stateKey: 'content',
            child: _HomeContent(
              data: data,
              isJoining: _isJoining,
              onPrimaryAction: () => _handlePrimaryAction(data),
              onShowRules: () => _showRules(data.workout!),
              onChangeCover: data.workout!.viewerCanEdit
                  ? () => _changeCover(data.workout!)
                  : null,
              isUploadingCover: _isUploadingCover,
              statusTargetKey: _onboardingTargetsActive
                  ? _statusTargetKey
                  : null,
              primaryActionTargetKey: _onboardingTargetsActive
                  ? _primaryActionTargetKey
                  : null,
            ),
          );
        },
      ),
    );
  }

  void _scheduleOnboarding(_HomeData data) {
    if (_onboardingScheduled) {
      return;
    }
    _onboardingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showOnboarding(data));
    });
  }

  Future<void> _showOnboarding(_HomeData data) async {
    if (!await appDependencies.onboarding.shouldShowDetails()) {
      _deactivateOnboardingTargets();
      return;
    }
    if (!mounted || _statusTargetKey.currentContext == null) {
      return;
    }

    final steps = <OnboardingCoachStep>[
      OnboardingCoachStep(
        id: 'challenge-timeline',
        targetKey: _statusTargetKey,
        title: 'Следи за этапом',
        body:
            'Здесь видно, когда закончится приём работ, начнётся голосование '
            'и появятся результаты.',
        align: ContentAlign.top,
      ),
      if (_canUploadPhoto(data) &&
          _primaryActionTargetKey.currentContext != null)
        OnboardingCoachStep(
          id: 'challenge-upload',
          targetKey: _primaryActionTargetKey,
          title: 'Добавь свой кадр',
          body: 'Нажми сюда, чтобы загрузить одну фотографию.',
          align: ContentAlign.top,
        ),
    ];

    final tutorial = createOnboardingCoachMark(
      context: context,
      steps: steps,
      onFinish: () => unawaited(_completeOnboarding()),
      onSkip: () => unawaited(_skipOnboarding()),
    );
    tutorial.show(context: context, rootOverlay: true);
  }

  Future<void> _completeOnboarding() async {
    await appDependencies.onboarding.completeDetails();
    _deactivateOnboardingTargets();
  }

  Future<void> _skipOnboarding() async {
    await appDependencies.onboarding.skip();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deactivateOnboardingTargets();
    });
  }

  void _deactivateOnboardingTargets() {
    if (!mounted || !_onboardingTargetsActive) {
      return;
    }
    setState(() => _onboardingTargetsActive = false);
  }

  bool _canUploadPhoto(_HomeData data) {
    final room = data.room;
    if (room != null) {
      return room.phase == GymRoomPhase.submission && !room.hasSubmission;
    }

    final phase = data.workout!.phase.toLowerCase();
    return !phase.contains('скоро') &&
        !phase.contains('голос') &&
        !phase.contains('результат') &&
        !phase.contains('заверш');
  }

  Future<void> _handlePrimaryAction(_HomeData data) async {
    final workout = data.workout!;
    final room = data.room;

    if (room == null) {
      if (_isJoining) {
        return;
      }
      setState(() {
        _isJoining = true;
      });
      try {
        final joinedRoom = await appDependencies.challenges.joinChallenge(
          workout.id,
        );
        if (!mounted) {
          return;
        }
        _openRoomAction(joinedRoom);
      } catch (error) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userErrorMessage(error))));
      } finally {
        if (mounted) {
          setState(() {
            _isJoining = false;
          });
        }
      }
      return;
    }

    _openRoomAction(room);
  }

  void _openRoomAction(GymRoom room) {
    switch (room.phase) {
      case GymRoomPhase.upcoming:
        return;
      case GymRoomPhase.submission:
        context.go(AppRoutes.roomUpload(room.id));
      case GymRoomPhase.voting:
        context.go(AppRoutes.roomVote(room.id));
      case GymRoomPhase.results:
        context.go(AppRoutes.roomResults(room.id));
    }
  }

  Future<void> _showRules(WeeklyWorkout workout) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints.tightFor(
        width: MediaQuery.sizeOf(context).width,
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            key: const ValueKey('rules-sheet'),
            width: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Условия',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final rule in workout.rules) ...[
                    Text('• $rule'),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _changeCover(WeeklyWorkout workout) async {
    if (_isUploadingCover) {
      return;
    }

    try {
      final photo = await appDependencies.photoPicker.pickFromGallery();
      if (photo == null || !mounted) {
        return;
      }
      if (photo.bytes.length > 5 * 1024 * 1024) {
        throw StateError('Обложка должна быть не больше 5 МБ.');
      }

      final shouldUpload = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Новая обложка',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.memory(photo.bytes, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Так обложка будет кадрироваться в списке.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedInk),
                  ),
                  const SizedBox(height: 20),
                  GlassButton(
                    label: 'Сохранить обложку',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (shouldUpload != true || !mounted) {
        return;
      }

      setState(() {
        _isUploadingCover = true;
      });
      await appDependencies.challenges.uploadCover(workout.id, photo);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Обложка сохранена')));
      _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingCover = false;
        });
      }
    }
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.data,
    required this.isJoining,
    required this.onPrimaryAction,
    required this.onShowRules,
    required this.onChangeCover,
    required this.isUploadingCover,
    required this.statusTargetKey,
    required this.primaryActionTargetKey,
  });

  final _HomeData data;
  final bool isJoining;
  final VoidCallback onPrimaryAction;
  final VoidCallback onShowRules;
  final VoidCallback? onChangeCover;
  final bool isUploadingCover;
  final GlobalKey? statusTargetKey;
  final GlobalKey? primaryActionTargetKey;

  @override
  Widget build(BuildContext context) {
    final workout = data.workout!;
    final room = data.room;
    final action = _HomeAction.from(room, workout: workout);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        Text(
          'Задание недели',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          workout.title,
          key: const ValueKey('current-workout-title'),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppTheme.ink,
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          workout.description,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.mutedInk,
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton(
              onPressed: onShowRules,
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
              ),
              child: const Text('Условия'),
            ),
            if (onChangeCover != null) ...[
              const Spacer(),
              TextButton.icon(
                key: const ValueKey('change-cover-button'),
                onPressed: isUploadingCover ? null : onChangeCover,
                icon: const Icon(Icons.photo_outlined, size: 18),
                label: Text(isUploadingCover ? 'Сохраняем...' : 'Обложка'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        if (data.photoBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Image.memory(data.photoBytes!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 18),
        ] else if (room?.hasSubmission == true) ...[
          const _AcceptedPhotoPlaceholder(),
          const SizedBox(height: 18),
        ],
        GlassPanel(
          key: statusTargetKey,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                action.status,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                action.detail ??
                    room?.deadlineLabel ??
                    workout.submissionDeadlineLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
              ),
              if (action.buttonLabel != null) ...[
                const SizedBox(height: 20),
                IgnorePointer(
                  ignoring: !action.isEnabled,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 140),
                    opacity: action.isEnabled ? 1 : 0.45,
                    child: KeyedSubtree(
                      key: primaryActionTargetKey,
                      child: GlassButton(
                        key: const ValueKey('primary-workout-action'),
                        label: isJoining ? 'Подождите...' : action.buttonLabel!,
                        onPressed: onPrimaryAction,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AcceptedPhotoPlaceholder extends StatelessWidget {
  const _AcceptedPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE7ECE8),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: const Center(
          child: Icon(
            Icons.check_circle_outline,
            color: AppTheme.primaryDark,
            size: 40,
          ),
        ),
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.onRetry});

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
              'Новых заданий пока нет',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('Загляните немного позже.'),
            const SizedBox(height: 20),
            TextButton(onPressed: onRetry, child: const Text('Обновить')),
          ],
        ),
      ),
    );
  }
}

class _HomeAction {
  const _HomeAction({
    required this.status,
    this.detail,
    this.buttonLabel,
    this.isEnabled = true,
  });

  final String status;
  final String? detail;
  final String? buttonLabel;
  final bool isEnabled;

  factory _HomeAction.from(GymRoom? room, {required WeeklyWorkout workout}) {
    if (room == null) {
      final phase = workout.phase.toLowerCase();
      if (phase.contains('скоро')) {
        return const _HomeAction(status: 'Задание скоро начнётся');
      }
      if (phase.contains('голос') || phase.contains('результат')) {
        return const _HomeAction(status: 'Участие уже закрыто');
      }
      return const _HomeAction(
        status: 'Можно начать сейчас',
        buttonLabel: 'Начать',
      );
    }

    return switch (room.phase) {
      GymRoomPhase.upcoming => const _HomeAction(
        status: 'Задание скоро начнётся',
      ),
      GymRoomPhase.submission =>
        room.hasSubmission
            ? const _HomeAction(
                status: 'Фото принято',
                buttonLabel: 'Открыть фото',
              )
            : const _HomeAction(
                status: 'Добавьте одну фотографию',
                buttonLabel: 'Добавить фото',
              ),
      GymRoomPhase.voting =>
        room.hasCompletedVoting
            ? const _HomeAction(
                status: 'Работы собраны',
                detail: 'Вы уже проголосовали',
                buttonLabel: 'Голосовать',
                isEnabled: false,
              )
            : !room.hasVotingOptions
            ? const _HomeAction(
                status: 'Работы собраны',
                detail: 'Недостаточно работ для голосования',
                buttonLabel: 'Голосовать',
                isEnabled: false,
              )
            : _HomeAction(
                status: 'Работы собраны',
                detail: _votingDeadline(room.deadlineLabel),
                buttonLabel: 'Голосовать',
              ),
      GymRoomPhase.results => const _HomeAction(
        status: 'Тренировка завершена',
        buttonLabel: 'Посмотреть итог',
      ),
    };
  }

  static String _votingDeadline(String deadline) {
    final normalized = deadline.endsWith('.')
        ? deadline.substring(0, deadline.length - 1)
        : deadline;
    return '$normalized голосования';
  }
}

class _HomeData {
  const _HomeData({this.workout, this.room, this.submission, this.photoBytes});

  final WeeklyWorkout? workout;
  final GymRoom? room;
  final Submission? submission;
  final Uint8List? photoBytes;
}
