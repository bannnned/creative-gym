import 'package:creative_gym_mobile/app/app_theme.dart';
import 'package:creative_gym_mobile/features/profile/domain/avatar_editor.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageCropperAvatarEditor implements AvatarEditor {
  ImageCropperAvatarEditor({ImageCropper? cropper})
    : _cropper = cropper ?? ImageCropper();

  final ImageCropper _cropper;

  @override
  Future<SelectedPhoto?> edit(BuildContext context, SelectedPhoto photo) async {
    final sourcePath = photo.sourcePath;
    if (sourcePath == null || sourcePath.isEmpty) {
      return photo;
    }

    final cropped = await _cropper.cropImage(
      sourcePath: sourcePath,
      maxWidth: 1024,
      maxHeight: 1024,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Настройте фото',
          toolbarColor: const Color(0xFFF8F6F0),
          toolbarWidgetColor: AppTheme.ink,
          activeControlsWidgetColor: AppTheme.primaryDark,
          backgroundColor: AppTheme.ink,
          dimmedLayerColor: const Color(0xB3000000),
          cropFrameColor: Colors.white,
          cropGridColor: const Color(0x99FFFFFF),
          cropStyle: CropStyle.circle,
          lockAspectRatio: true,
          showCropGrid: false,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: 'Настройте фото',
          doneButtonTitle: 'Готово',
          cancelButtonTitle: 'Отмена',
          cropStyle: CropStyle.circle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          rotateButtonsHidden: false,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
      ],
    );
    if (cropped == null) {
      return null;
    }
    final bytes = await cropped.readAsBytes();
    return SelectedPhoto(
      fileName: 'avatar.jpg',
      bytes: bytes,
      sourcePath: cropped.path,
    );
  }
}
