import 'dart:typed_data';

import 'package:creative_gym_mobile/app/app_motion.dart';
import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/features/submissions/domain/photo_picker.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';
import 'package:creative_gym_mobile/features/submissions/domain/submission.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/app_back_scope.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
import 'package:creative_gym_mobile/shared/widgets/soft_memory_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class UploadSubmissionScreen extends StatefulWidget {
  const UploadSubmissionScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<UploadSubmissionScreen> createState() => _UploadSubmissionScreenState();
}

class _UploadSubmissionScreenState extends State<UploadSubmissionScreen> {
  late Future<void> _loadFuture;
  GymRoom? _room;
  Submission? _submission;
  SelectedPhoto? _selectedPhoto;
  Uint8List? _uploadedPhotoBytes;
  bool _mediaLoadFailed = false;
  bool _isBusy = false;
  double? _uploadProgress;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  Future<void> _loadData() async {
    final room = await appDependencies.rooms.getRoomById(widget.roomId);
    Submission? submission;
    Uint8List? photoBytes;
    var mediaLoadFailed = false;

    if (room != null) {
      submission = await appDependencies.submissions.getMine(widget.roomId);
      if (submission != null) {
        try {
          photoBytes = await appDependencies.submissions.loadMedia(submission);
        } catch (_) {
          mediaLoadFailed = true;
        }
      }
    }

    _room = room;
    _submission = submission;
    _selectedPhoto = null;
    _uploadedPhotoBytes = photoBytes;
    _mediaLoadFailed = mediaLoadFailed;
  }

  void _reload() {
    setState(() {
      _loadFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backFallbackLocation: AppRoutes.challenges,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () =>
              popOrGoBack(context, fallbackLocation: AppRoutes.challenges),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Фото'),
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncContentTransition(
              stateKey: 'loading',
              child: AsyncLoadingPanel(
                message: 'Загружаем фото...',
                layout: AsyncLoadingLayout.photo,
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

          final room = _room;
          if (room == null) {
            return const AsyncContentTransition(
              stateKey: 'missing',
              child: _SimpleState(
                title: 'Задание не найдено',
                message: 'Вернитесь к текущему заданию.',
              ),
            );
          }
          if (!room.canUpload) {
            return AsyncContentTransition(
              stateKey: 'locked',
              child: _SimpleState(
                title: 'Приём фотографий завершён',
                message: room.deadlineLabel,
              ),
            );
          }

          return AsyncContentTransition(
            stateKey: 'content',
            child: _PhotoContent(
              room: room,
              submission: _submission,
              selectedPhoto: _selectedPhoto,
              uploadedPhotoBytes: _uploadedPhotoBytes,
              mediaLoadFailed: _mediaLoadFailed,
              isBusy: _isBusy,
              uploadProgress: _uploadProgress,
              onPick: _pickPhoto,
              onUpload: _uploadPhoto,
              onCancel: () => setState(() => _selectedPhoto = null),
              onDelete: _confirmDelete,
              onReloadMedia: _reloadUploadedMedia,
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickPhoto() async {
    try {
      final photo = await appDependencies.photoPicker.pickFromGallery();
      if (!mounted || photo == null) {
        return;
      }
      setState(() {
        _selectedPhoto = photo;
      });
    } on PhotoPickerException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError(userErrorMessage(error));
    }
  }

  Future<void> _uploadPhoto() async {
    final photo = _selectedPhoto;
    if (photo == null || _isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
      _uploadProgress = 0;
    });

    try {
      final submission = await appDependencies.submissions.upload(
        widget.roomId,
        photo,
        onProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(() => _uploadProgress = sent / total);
          }
        },
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _submission = submission;
        _selectedPhoto = null;
        _uploadedPhotoBytes = photo.bytes;
        _mediaLoadFailed = false;
        _isBusy = false;
        _uploadProgress = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Фото сохранено')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _uploadProgress = null;
      });
      _showError(userErrorMessage(error));
    }
  }

  Future<void> _reloadUploadedMedia() async {
    final submission = _submission;
    if (submission == null || _isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    try {
      final bytes = await appDependencies.submissions.loadMedia(submission);
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadedPhotoBytes = bytes;
        _mediaLoadFailed = false;
        _isBusy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isBusy = false);
      _showError(userErrorMessage(error));
    }
  }

  Future<void> _confirmDelete() async {
    final submission = _submission;
    if (submission == null || _isBusy) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить фото?'),
        content: const Text(
          'До окончания приёма работ можно будет загрузить другое.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      await appDependencies.submissions.delete(submission.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _submission = null;
        _selectedPhoto = null;
        _uploadedPhotoBytes = null;
        _mediaLoadFailed = false;
        _isBusy = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Фото удалено')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isBusy = false);
      _showError(userErrorMessage(error));
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _PhotoContent extends StatelessWidget {
  const _PhotoContent({
    required this.room,
    required this.submission,
    required this.selectedPhoto,
    required this.uploadedPhotoBytes,
    required this.mediaLoadFailed,
    required this.isBusy,
    required this.uploadProgress,
    required this.onPick,
    required this.onUpload,
    required this.onCancel,
    required this.onDelete,
    required this.onReloadMedia,
  });

  final GymRoom room;
  final Submission? submission;
  final SelectedPhoto? selectedPhoto;
  final Uint8List? uploadedPhotoBytes;
  final bool mediaLoadFailed;
  final bool isBusy;
  final double? uploadProgress;
  final VoidCallback onPick;
  final VoidCallback onUpload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onReloadMedia;

  @override
  Widget build(BuildContext context) {
    final previewBytes = selectedPhoto?.bytes ?? uploadedPhotoBytes;
    final hasUploadedPhoto = submission != null;
    final hasSelection = selectedPhoto != null;
    final statusLabel = hasSelection
        ? 'Фото выбрано'
        : hasUploadedPhoto
        ? 'Фото принято'
        : 'Добавьте одну фотографию';

    return AbsorbPointer(
      absorbing: isBusy,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Text(
            room.challengeTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            room.deadlineLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
          ),
          const SizedBox(height: 24),
          _PhotoPreview(
            bytes: previewBytes,
            isBusy: isBusy,
            uploadProgress: uploadProgress,
          ),
          const SizedBox(height: 20),
          Row(
                key: ValueKey('photo-status-$statusLabel'),
                children: [
                  if (hasUploadedPhoto && !hasSelection) ...[
                    const Icon(
                          Icons.check_circle_rounded,
                          size: 22,
                          color: AppTheme.primaryDark,
                        )
                        .animate(key: const ValueKey('accepted-photo-check'))
                        .fadeIn(
                          duration: AppMotion.duration(
                            context,
                            AppMotion.standard,
                          ),
                        )
                        .scaleXY(
                          begin: 0.72,
                          end: 1,
                          duration: AppMotion.duration(
                            context,
                            AppMotion.expressive,
                          ),
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (hasUploadedPhoto && !hasSelection)
                    PopupMenuButton<String>(
                      tooltip: 'Ещё',
                      onSelected: (value) {
                        if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'delete', child: Text('Удалить')),
                      ],
                    ),
                ],
              )
              .animate(key: ValueKey('photo-status-motion-$statusLabel'))
              .fadeIn(duration: AppMotion.duration(context, AppMotion.standard))
              .slideY(
                begin: 0.12,
                end: 0,
                duration: AppMotion.duration(context, AppMotion.standard),
                curve: Curves.easeOutCubic,
              ),
          if (mediaLoadFailed && !hasSelection) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onReloadMedia,
              child: const Text('Повторить загрузку превью'),
            ),
          ],
          const SizedBox(height: 18),
          if (hasSelection) ...[
            GlassButton(
              key: const ValueKey('upload-photo-button'),
              label: hasUploadedPhoto ? 'Заменить фото' : 'Загрузить фото',
              onPressed: onUpload,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onCancel, child: const Text('Отмена')),
          ] else if (hasUploadedPhoto)
            TextButton(onPressed: onPick, child: const Text('Заменить'))
          else
            GlassButton(
              key: const ValueKey('pick-photo-button'),
              label: 'Выбрать фото',
              onPressed: onPick,
            ),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.bytes,
    required this.isBusy,
    required this.uploadProgress,
  });

  final Uint8List? bytes;
  final bool isBusy;
  final double? uploadProgress;

  @override
  Widget build(BuildContext context) {
    final imageBytes = bytes;
    const emptyPreview = ColoredBox(
      key: ValueKey('empty-photo-preview'),
      color: Color(0xFFE7ECE8),
      child: Center(
        child: Icon(
          Icons.add_photo_alternate_outlined,
          size: 42,
          color: AppTheme.mutedInk,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageBytes == null)
              emptyPreview
            else
              SoftMemoryImage(
                key: ObjectKey(imageBytes),
                bytes: imageBytes,
                placeholder: emptyPreview,
                revealKey: imageBytes,
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.quick),
                child: isBusy
                    ? DecoratedBox(
                        key: const ValueKey('photo-progress-overlay'),
                        decoration: BoxDecoration(
                          color: const Color(0xCCFFFFFF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LinearProgressIndicator(value: uploadProgress),
                              const SizedBox(height: 6),
                              Text(
                                uploadProgress == null
                                    ? 'Обновляем…'
                                    : 'Загружаем ${(uploadProgress! * 100).clamp(0, 100).round()}%',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('photo-progress-idle'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleState extends StatelessWidget {
  const _SimpleState({required this.title, required this.message});

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
