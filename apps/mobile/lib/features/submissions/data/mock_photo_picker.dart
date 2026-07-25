import 'package:creative_gym_mobile/features/submissions/data/mock_photo_data.dart';
import 'package:creative_gym_mobile/features/submissions/domain/photo_picker.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';

class MockPhotoPicker implements PhotoPicker {
  const MockPhotoPicker();

  @override
  Future<SelectedPhoto?> pickFromGallery() async {
    return SelectedPhoto(fileName: 'demo-photo.png', bytes: mockPhotoBytes());
  }
}
