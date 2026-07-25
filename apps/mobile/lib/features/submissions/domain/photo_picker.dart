import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';

abstract interface class PhotoPicker {
  Future<SelectedPhoto?> pickFromGallery();
}

class PhotoPickerException implements Exception {
  const PhotoPickerException(this.message);

  final String message;

  @override
  String toString() => message;
}
