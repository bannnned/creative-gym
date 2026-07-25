import 'package:creative_gym_mobile/features/submissions/data/mock_photo_data.dart';
import 'package:creative_gym_mobile/features/submissions/data/mock_submissions_repository.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uploads, reads, and deletes a submission', () async {
    final repository = MockSubmissionsRepository();
    final photo = SelectedPhoto(fileName: 'photo.png', bytes: mockPhotoBytes());

    final submission = await repository.upload('room-1', photo);

    expect((await repository.getMine('room-1'))?.id, submission.id);
    expect(await repository.loadMedia(submission), photo.bytes);

    await repository.delete(submission.id);

    expect(await repository.getMine('room-1'), isNull);
  });
}
