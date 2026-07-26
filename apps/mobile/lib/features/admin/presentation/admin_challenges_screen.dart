import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/features/admin/domain/admin_challenge.dart';
import 'package:creative_gym_mobile/features/challenges/domain/weekly_workout.dart';
import 'package:creative_gym_mobile/shared/widgets/app_glass_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:flutter/material.dart';

class AdminChallengesScreen extends StatefulWidget {
  const AdminChallengesScreen({super.key});

  @override
  State<AdminChallengesScreen> createState() => _AdminChallengesScreenState();
}

class _AdminChallengesScreenState extends State<AdminChallengesScreen> {
  late Future<List<WeeklyWorkout>> _challengesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _challengesFuture = appDependencies.challenges.getActiveWorkouts();
  }

  Future<void> _createChallenge() async {
    final draft = await showModalBottomSheet<AdminChallengeDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChallengeEditor(),
    );
    if (draft == null || !mounted) {
      return;
    }

    await _runMutation(
      () => appDependencies.admin.createChallenge(draft),
      successMessage: 'Челлендж создан',
    );
  }

  Future<void> _editChallenge(WeeklyWorkout workout) async {
    try {
      final challenge = await appDependencies.admin.getChallenge(workout.id);
      if (!mounted) {
        return;
      }
      final draft = await showModalBottomSheet<AdminChallengeDraft>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ChallengeEditor(challenge: challenge),
      );
      if (draft == null || !mounted) {
        return;
      }

      await _runMutation(
        () => appDependencies.admin.updateChallenge(workout.id, draft),
        successMessage: 'Изменения сохранены',
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _archiveChallenge(WeeklyWorkout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Убрать челлендж?'),
        content: Text(
          '«${workout.title}» исчезнет из приложения. Работы и результаты сохранятся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Убрать'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    await _runMutation(
      () => appDependencies.admin.archiveChallenge(workout.id),
      successMessage: 'Челлендж убран',
    );
  }

  Future<void> _runMutation(
    Future<Object?> Function() mutation, {
    required String successMessage,
  }) async {
    try {
      await mutation();
      if (!mounted) {
        return;
      }
      setState(_reload);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(userErrorMessage(error))));
  }

  @override
  Widget build(BuildContext context) {
    return AppGlassScaffold(
      title: 'Управление',
      showBackButton: true,
      actions: [
        AppGlassHeaderAction(
          key: const ValueKey('create-challenge-button'),
          icon: Icons.add_rounded,
          semanticLabel: 'Создать челлендж',
          onPressed: _createChallenge,
        ),
      ],
      body: FutureBuilder<List<WeeklyWorkout>>(
        future: _challengesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncLoadingPanel(
              message: 'Загружаем челленджи...',
              layout: AsyncLoadingLayout.list,
            );
          }
          if (snapshot.hasError) {
            return AsyncErrorPanel(
              message: userErrorMessage(snapshot.error),
              onRetry: () => setState(_reload),
            );
          }

          final challenges = snapshot.data ?? const [];
          return ListView.separated(
            key: const ValueKey('admin-challenge-list'),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
            itemCount: challenges.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              return _ChallengeTile(
                challenge: challenge,
                onEdit: () => _editChallenge(challenge),
                onArchive: () => _archiveChallenge(challenge),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({
    required this.challenge,
    required this.onEdit,
    required this.onArchive,
  });

  final WeeklyWorkout challenge;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    challenge.phase,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedInk),
                  ),
                ],
              ),
            ),
            IconButton(
              key: ValueKey('edit-challenge-${challenge.id}'),
              tooltip: 'Изменить',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            PopupMenuButton<String>(
              tooltip: 'Ещё',
              onSelected: (value) {
                if (value == 'archive') {
                  onArchive();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'archive', child: Text('Убрать')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeEditor extends StatefulWidget {
  const _ChallengeEditor({this.challenge});

  final AdminChallenge? challenge;

  @override
  State<_ChallengeEditor> createState() => _ChallengeEditorState();
}

class _ChallengeEditorState extends State<_ChallengeEditor> {
  late final TextEditingController _title;
  late final TextEditingController _theme;
  late final TextEditingController _description;
  late final TextEditingController _rules;
  late AdminChallengePhase _phase;

  @override
  void initState() {
    super.initState();
    final challenge = widget.challenge;
    _title = TextEditingController(text: challenge?.title ?? '');
    _theme = TextEditingController(text: challenge?.theme ?? '');
    _description = TextEditingController(text: challenge?.description ?? '');
    _rules = TextEditingController(text: challenge?.rules.join('\n') ?? '');
    _phase = challenge?.phase ?? AdminChallengePhase.submission;
  }

  @override
  void dispose() {
    _title.dispose();
    _theme.dispose();
    _description.dispose();
    _rules.dispose();
    super.dispose();
  }

  void _save() {
    if (_title.text.trim().isEmpty ||
        _theme.text.trim().isEmpty ||
        _description.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните название, тему и описание')),
      );
      return;
    }

    Navigator.pop(
      context,
      AdminChallengeDraft(
        title: _title.text,
        theme: _theme.text,
        description: _description.text,
        rules: _rules.text.split('\n'),
        phase: _phase,
        original: widget.challenge,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.challenge == null
                    ? 'Новый челлендж'
                    : 'Изменить челлендж',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                key: const ValueKey('admin-title-field'),
                controller: _title,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _theme,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Тема',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _rules,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Правила — по одному в строке',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AdminChallengePhase>(
                initialValue: _phase,
                decoration: const InputDecoration(
                  labelText: 'Состояние',
                  border: OutlineInputBorder(),
                ),
                items: AdminChallengePhase.values
                    .map(
                      (phase) => DropdownMenuItem(
                        value: phase,
                        child: Text(adminPhaseLabel(phase)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _phase = value);
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Смена состояния автоматически выставит удобные тестовые сроки.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedInk),
              ),
              const SizedBox(height: 20),
              GlassButton(
                label: 'Сохранить',
                icon: Icons.check_rounded,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
