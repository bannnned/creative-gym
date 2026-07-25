import 'dart:typed_data';

import 'package:creative_gym_mobile/app/app_router.dart';
import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/features/submissions/domain/photo_picker.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';
import 'package:creative_gym_mobile/features/submissions/domain/submission.dart';
import 'package:creative_gym_mobile/shared/widgets/app_scaffold.dart';
import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:creative_gym_mobile/shared/widgets/glass_button.dart';
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
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () => context.go(AppRoutes.challenges),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Фото'),
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AsyncLoadingPanel(message: 'Загружаем фото...');
          }
          if (snapshot.hasError) {
            return AsyncErrorPanel(
              message: userErrorMessage(snapshot.error),
              onRetry: _reload,
            );
          }

          final room = _room;
          if (room == null) {
            return const _SimpleState(
              title: 'Задание не найдено',
              message: 'Вернитесь к текущему заданию.',
            );
          }
          if (!room.canUpload) {
            return _SimpleState(
              title: 'Приём фотографий завершён',
              message: room.deadlineLabel,
            );
          }

          return _PhotoContent(
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

      Uint8List? bytes;
      var mediaLoadFailed = false;
      try {
        bytes = await appDependencies.submissions.loadMedia(submission);
      } catch (_) {
        mediaLoadFailed = true;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _submission = submission;
        _selectedPhoto = null;
        _uploadedPhotoBytes = bytes;
        _mediaLoadFailed = mediaLoadFailed;
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
          _PhotoPreview(bytes: previewBytes),
          if (isBusy) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: uploadProgress),
            const SizedBox(height: 8),
            Text(
              uploadProgress == null
                  ? 'Обновляем...'
                  : 'Загружаем ${(uploadProgress! * 100).clamp(0, 100).round()}%',
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasSelection
                      ? 'Фото выбрано'
                      : hasUploadedPhoto
                      ? 'Фото принято'
                      : 'Добавьте одну фотографию',
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
  const _PhotoPreview({required this.bytes});

  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: bytes == null
            ? ColoredBox(
                color: const Color(0xFFE7ECE8),
                child: const Center(
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 42,
                    color: AppTheme.mutedInk,
                  ),
                ),
              )
            : Image.memory(
                bytes!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Color(0xFFE7ECE8),
                  child: Center(child: Text('Не удалось показать фото')),
                ),
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
