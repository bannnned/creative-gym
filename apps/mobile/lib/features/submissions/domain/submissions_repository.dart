import 'dart:typed_data';

import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';
import 'package:creative_gym_mobile/features/submissions/domain/submission.dart';

typedef UploadProgress = void Function(int sentBytes, int totalBytes);

abstract interface class SubmissionsRepository {
  Future<Submission?> getMine(String roomId);

  Future<Submission> upload(
    String roomId,
    SelectedPhoto photo, {
    UploadProgress? onProgress,
  });

  Future<Uint8List> loadMedia(Submission submission);

  Future<void> delete(String submissionId);
}
