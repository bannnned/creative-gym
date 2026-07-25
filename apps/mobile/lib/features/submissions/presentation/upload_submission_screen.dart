import 'dart:typed_data';

import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/features/submissions/domain/photo_picker.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';
import 'package:creative_gym_mobile/features/submissions/domain/submission.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
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
  late Future<void> _loadFuture;
  GymRoom? _room;
  Submission? _submission;
  SelectedPhoto? _selectedPhoto;
  Uint8List? _uploadedPhotoBytes;
  Object? _mediaLoadError;
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
    Uint8List? uploadedPhotoBytes;
    Object? mediaLoadError;

    if (room != null) {
      submission = await appDependencies.submissions.getMine(widget.roomId);
      if (submission != null) {
        try {
          uploadedPhotoBytes = await appDependencies.submissions.loadMedia(
            submission,
          );
        } catch (error) {
          mediaLoadError = error;
        }
      }
    }

    _room = room;
    _submission = submission;
    _selectedPhoto = null;
    _uploadedPhotoBytes = uploadedPhotoBytes;
    _mediaLoadError = mediaLoadError;
  }

  void _reload() {
    setState(() {
      _loadFuture = _loadData();
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
        title: const Text('Загрузка фото'),
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncLoadingPanel(message: 'Загрузка вашей работы...');
          }

          if (snapshot.hasError) {
            return AsyncErrorPanel(
              message: _errorMessage(snapshot.error!),
              onRetry: _reload,
            );
          }

          final room = _room;
          if (room == null) {
            return const _MissingUploadRoom();
          }

          if (!room.canUpload) {
            return _UploadUnavailable(room: room);
          }

          return _UploadContent(
            room: room,
            submission: _submission,
            selectedPhoto: _selectedPhoto,
            uploadedPhotoBytes: _uploadedPhotoBytes,
            mediaLoadError: _mediaLoadError,
            isBusy: _isBusy,
            uploadProgress: _uploadProgress,
            onPickPhoto: _pickPhoto,
            onUpload: _uploadPhoto,
            onCancelSelection: _cancelSelection,
            onDelete: _confirmDelete,
            onReloadMedia: _reloadUploadedMedia,
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
      _showError(_errorMessage(error));
    }
  }

  void _cancelSelection() {
    setState(() {
      _selectedPhoto = null;
    });
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
          if (!mounted || total <= 0) {
            return;
          }
          setState(() {
            _uploadProgress = sent / total;
          });
        },
      );

      Uint8List? uploadedPhotoBytes;
      Object? mediaLoadError;
      try {
        uploadedPhotoBytes = await appDependencies.submissions.loadMedia(
          submission,
        );
      } catch (error) {
        mediaLoadError = error;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _submission = submission;
        _selectedPhoto = null;
        _uploadedPhotoBytes = uploadedPhotoBytes;
        _mediaLoadError = mediaLoadError;
        _isBusy = false;
        _uploadProgress = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mediaLoadError == null
                ? 'Фото загружено и сохранено.'
                : 'Фото сохранено, но превью пока не загрузилось.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _uploadProgress = null;
      });
      _showError(_errorMessage(error));
    }
  }

  Future<void> _reloadUploadedMedia() async {
    final submission = _submission;
    if (submission == null || _isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
    });
    try {
      final bytes = await appDependencies.submissions.loadMedia(submission);
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadedPhotoBytes = bytes;
        _mediaLoadError = null;
        _isBusy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _mediaLoadError = error;
        _isBusy = false;
      });
      _showError(_errorMessage(error));
    }
  }

  Future<void> _confirmDelete() async {
    final submission = _submission;
    if (submission == null || _isBusy) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить фото?'),
          content: const Text(
            'Работа будет удалена из Gym Room и из хранилища. '
            'До конца приема работ можно будет загрузить новую.',
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
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isBusy = true;
    });
    try {
      await appDependencies.submissions.delete(submission.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _submission = null;
        _selectedPhoto = null;
        _uploadedPhotoBytes = null;
        _mediaLoadError = null;
        _isBusy = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Фото удалено.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
      });
      _showError(_errorMessage(error));
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _UploadContent extends StatelessWidget {
  const _UploadContent({
    required this.room,
    required this.submission,
    required this.selectedPhoto,
    required this.uploadedPhotoBytes,
    required this.mediaLoadError,
    required this.isBusy,
    required this.uploadProgress,
    required this.onPickPhoto,
    required this.onUpload,
    required this.onCancelSelection,
    required this.onDelete,
    required this.onReloadMedia,
  });

  final GymRoom room;
  final Submission? submission;
  final SelectedPhoto? selectedPhoto;
  final Uint8List? uploadedPhotoBytes;
  final Object? mediaLoadError;
  final bool isBusy;
  final double? uploadProgress;
  final VoidCallback onPickPhoto;
  final VoidCallback onUpload;
  final VoidCallback onCancelSelection;
  final VoidCallback onDelete;
  final VoidCallback onReloadMedia;

  @override
  Widget build(BuildContext context) {
    final hasUploadedPhoto = submission != null;
    final hasSelection = selectedPhoto != null;
    final previewBytes = selectedPhoto?.bytes ?? uploadedPhotoBytes;
    final statusLabel = hasSelection
        ? hasUploadedPhoto
              ? 'Новое фото готово к замене'
              : 'Фото готово к загрузке'
        : hasUploadedPhoto
        ? 'Фото загружено'
        : 'Фото не выбрано';

    return AbsorbPointer(
      absorbing: isBusy,
      child: ListView(
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
          AnimatedOpacity(
            opacity: isBusy ? 0.72 : 1,
            duration: const Duration(milliseconds: 180),
            child: GlassPanel(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _UploadPreview(
                    photoBytes: previewBytes,
                    isUploaded: hasUploadedPhoto && !hasSelection,
                  ),
                  if (isBusy) ...[
                    const SizedBox(height: 14),
                    LinearProgressIndicator(value: uploadProgress),
                    const SizedBox(height: 8),
                    Text(
                      uploadProgress == null
                          ? 'Обновляем данные...'
                          : 'Загружаем ${(_safeProgress(uploadProgress!) * 100).round()}%',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(
                        hasUploadedPhoto && !hasSelection
                            ? Icons.check_circle_outline
                            : hasSelection
                            ? Icons.image_outlined
                            : Icons.add_photo_alternate_outlined,
                        color: AppTheme.primaryDark,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          statusLabel,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasUploadedPhoto
                        ? '${_formatBytes(submission!.byteSize)} · '
                              '${submission!.contentType}'
                        : 'JPEG, PNG или WebP, не больше 10 МБ.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mutedInk,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (mediaLoadError != null && !hasSelection) ...[
                    const SizedBox(height: 12),
                    _MediaLoadWarning(onRetry: onReloadMedia),
                  ],
                  const SizedBox(height: 18),
                  if (!hasSelection && !hasUploadedPhoto)
                    GlassButton(
                      onPressed: onPickPhoto,
                      icon: Icons.photo_library_outlined,
                      label: 'Выбрать фото',
                    )
                  else if (hasSelection) ...[
                    GlassButton(
                      onPressed: onUpload,
                      icon: Icons.cloud_upload_outlined,
                      label: hasUploadedPhoto
                          ? 'Загрузить вместо текущего'
                          : 'Загрузить фото',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GlassButton(
                            onPressed: onPickPhoto,
                            icon: Icons.swap_horiz,
                            label: 'Выбрать другое',
                            variant: GlassButtonVariant.tonal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassButton(
                            onPressed: onCancelSelection,
                            icon: Icons.close,
                            label: 'Отмена',
                            variant: GlassButtonVariant.quiet,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    GlassButton(
                      onPressed: onPickPhoto,
                      icon: Icons.swap_horiz,
                      label: 'Заменить фото',
                      variant: GlassButtonVariant.tonal,
                    ),
                    const SizedBox(height: 12),
                    GlassButton(
                      onPressed: onDelete,
                      icon: Icons.delete_outline,
                      label: 'Удалить фото',
                      variant: GlassButtonVariant.quiet,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadPreview extends StatelessWidget {
  const _UploadPreview({required this.photoBytes, required this.isUploaded});

  final Uint8List? photoBytes;
  final bool isUploaded;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.42),
                Colors.white.withValues(alpha: 0.2),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
          ),
          child: photoBytes == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 44,
                        color: AppTheme.mutedInk,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Здесь появится превью',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      photoBytes!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: AppTheme.mutedInk,
                          ),
                        );
                      },
                    ),
                    if (isUploaded)
                      Positioned(
                        right: 12,
                        top: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryDark.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_done_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Загружено',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MediaLoadWarning extends StatelessWidget {
  const _MediaLoadWarning({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D8).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppTheme.mutedInk),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Работа сохранена, но превью не удалось получить из хранилища.',
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
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

String _errorMessage(Object error) {
  if (error is ApiException) {
    return error.message;
  }
  if (error is PhotoPickerException) {
    return error.message;
  }
  return error.toString();
}

double _safeProgress(double value) => value.clamp(0, 1).toDouble();

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} КБ';
  }
  return '$bytes Б';
}
