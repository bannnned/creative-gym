import 'package:creative_gym_mobile/features/submissions/domain/photo_picker.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  static const maxPhotoBytes = 10 * 1024 * 1024;

  final ImagePicker _picker;

  @override
  Future<SelectedPhoto?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 4096,
      maxHeight: 4096,
      imageQuality: 92,
    );
    if (file == null) {
      return null;
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const PhotoPickerException('Выбранный файл пуст.');
    }
    if (bytes.length > maxPhotoBytes) {
      throw const PhotoPickerException('Фото должно быть не больше 10 МБ.');
    }

    return SelectedPhoto(
      fileName: file.name,
      bytes: bytes,
      sourcePath: file.path,
    );
  }
}
