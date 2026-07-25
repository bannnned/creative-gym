import 'dart:typed_data';

import 'package:creative_gym_mobile/features/submissions/data/mock_photo_data.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';
import 'package:creative_gym_mobile/features/submissions/domain/submission.dart';
import 'package:creative_gym_mobile/features/submissions/domain/submissions_repository.dart';

class MockSubmissionsRepository implements SubmissionsRepository {
  final Map<String, Submission> _byRoom = {};
  final Map<String, Uint8List> _mediaBySubmission = {};

  @override
  Future<Submission?> getMine(String roomId) async => _byRoom[roomId];

  @override
  Future<Submission> upload(
    String roomId,
    SelectedPhoto photo, {
    UploadProgress? onProgress,
  }) async {
    onProgress?.call(photo.bytes.length, photo.bytes.length);
    final now = DateTime.now().toUtc();
    final submission = Submission(
      id: 'demo-submission-$roomId',
      roomId: roomId,
      mediaUrl: '/demo/submissions/$roomId/media',
      contentType: 'image/png',
      byteSize: photo.bytes.length,
      createdAt: now,
      updatedAt: now,
    );
    _byRoom[roomId] = submission;
    _mediaBySubmission[submission.id] = Uint8List.fromList(photo.bytes);
    return submission;
  }

  @override
  Future<Uint8List> loadMedia(Submission submission) async {
    return _mediaBySubmission[submission.id] ?? mockPhotoBytes();
  }

  @override
  Future<void> delete(String submissionId) async {
    _mediaBySubmission.remove(submissionId);
    _byRoom.removeWhere((_, submission) => submission.id == submissionId);
  }
}
