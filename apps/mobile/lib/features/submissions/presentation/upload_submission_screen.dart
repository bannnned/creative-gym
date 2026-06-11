import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/features/rooms/data/mock_gym_rooms.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UploadSubmissionScreen extends StatefulWidget {
  const UploadSubmissionScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<UploadSubmissionScreen> createState() => _UploadSubmissionScreenState();
}

class _UploadSubmissionScreenState extends State<UploadSubmissionScreen> {
  late final GymRoom? _room = findMockGymRoomById(widget.roomId);
  late bool _hasSelectedPhoto = _room?.hasSubmission ?? false;
  late bool _isSaved = _room?.hasSubmission ?? false;

  @override
  Widget build(BuildContext context) {
    final room = _room;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () => context.go(AppRoutes.room(widget.roomId)),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Upload Photo'),
      ),
      body: room == null
          ? const _MissingUploadRoom()
          : !room.canUpload
          ? _UploadUnavailable(room: room)
          : _UploadContent(
              room: room,
              hasSelectedPhoto: _hasSelectedPhoto,
              isSaved: _isSaved,
              onPickPhoto: _pickMockPhoto,
              onSave: _saveMockPhoto,
              onDelete: _deleteMockPhoto,
            ),
    );
  }

  void _pickMockPhoto() {
    setState(() {
      _hasSelectedPhoto = true;
      _isSaved = false;
    });
  }

  void _saveMockPhoto() {
    setState(() {
      _hasSelectedPhoto = true;
      _isSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Фото сохранено в демо-режиме.')),
    );
  }

  void _deleteMockPhoto() {
    setState(() {
      _hasSelectedPhoto = false;
      _isSaved = false;
    });
  }
}

class _UploadContent extends StatelessWidget {
  const _UploadContent({
    required this.room,
    required this.hasSelectedPhoto,
    required this.isSaved,
    required this.onPickPhoto,
    required this.onSave,
    required this.onDelete,
  });

  final GymRoom room;
  final bool hasSelectedPhoto;
  final bool isSaved;
  final VoidCallback onPickPhoto;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusLabel = isSaved
        ? 'Фото загружено'
        : hasSelectedPhoto
        ? 'Фото выбрано'
        : 'Фото не выбрано';

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
          'Одна фотография для этой Gym Room',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 24),
        GlassPanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _UploadPreview(
                hasSelectedPhoto: hasSelectedPhoto,
                isSaved: isSaved,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(
                    isSaved
                        ? Icons.check_circle_outline
                        : hasSelectedPhoto
                        ? Icons.image_outlined
                        : Icons.add_photo_alternate_outlined,
                    color: AppTheme.primaryDark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'В демо-режиме мы показываем локальную заглушку. Позже этот экран подключится к S3 upload flow.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedInk,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              if (!hasSelectedPhoto)
                GlassButton(
                  onPressed: onPickPhoto,
                  icon: Icons.photo_library_outlined,
                  label: 'Выбрать фото',
                )
              else ...[
                GlassButton(
                  onPressed: onSave,
                  icon: Icons.check,
                  label: isSaved ? 'Сохранить снова' : 'Сохранить',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        onPressed: onPickPhoto,
                        icon: Icons.swap_horiz,
                        label: 'Заменить',
                        variant: GlassButtonVariant.tonal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassButton(
                        onPressed: onDelete,
                        icon: Icons.delete_outline,
                        label: 'Удалить',
                        variant: GlassButtonVariant.quiet,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadPreview extends StatelessWidget {
  const _UploadPreview({required this.hasSelectedPhoto, required this.isSaved});

  final bool hasSelectedPhoto;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          gradient: hasSelectedPhoto
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFDDBB8D),
                    Color(0xFF8FBFAA),
                    Color(0xFF24493F),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.42),
                    Colors.white.withValues(alpha: 0.2),
                  ],
                ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasSelectedPhoto) ...[
              Positioned(
                right: -28,
                top: 28,
                child: _PreviewRing(
                  size: 156,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
              Positioned(
                left: -38,
                bottom: 64,
                child: _PreviewBlob(
                  size: 148,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
            ],
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasSelectedPhoto
                        ? Icons.photo_camera_outlined
                        : Icons.add_photo_alternate_outlined,
                    size: 44,
                    color: hasSelectedPhoto ? Colors.white : AppTheme.mutedInk,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hasSelectedPhoto
                        ? isSaved
                              ? 'Demo photo saved'
                              : 'Demo photo selected'
                        : 'Preview area',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: hasSelectedPhoto ? Colors.white : AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRing extends StatelessWidget {
  const _PreviewRing({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 24),
      ),
    );
  }
}

class _PreviewBlob extends StatelessWidget {
  const _PreviewBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.4),
      ),
    );
  }
}

class _UploadUnavailable extends StatelessWidget {
  const _UploadUnavailable({required this.room});

  final GymRoom room;

  @override
  Widget build(BuildContext context) {
    return _UploadStatePanel(
      icon: Icons.lock_clock_outlined,
      title: 'Загрузка сейчас закрыта',
      message: room.phaseHelpLabel,
      buttonLabel: 'Вернуться в Gym Room',
      onPressed: () => context.go(AppRoutes.room(room.id)),
    );
  }
}

class _MissingUploadRoom extends StatelessWidget {
  const _MissingUploadRoom();

  @override
  Widget build(BuildContext context) {
    return _UploadStatePanel(
      icon: Icons.search_off_outlined,
      title: 'Комната не найдена',
      message: 'Проверьте ссылку или вернитесь к списку Weekly Workouts.',
      buttonLabel: 'Вернуться к Weekly Workouts',
      onPressed: () => context.go(AppRoutes.challenges),
    );
  }
}

class _UploadStatePanel extends StatelessWidget {
  const _UploadStatePanel({
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
