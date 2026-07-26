import 'dart:typed_data';

import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/media/domain/media_repository.dart';
import 'package:creative_gym_mobile/features/submissions/data/dto/submission_dto.dart';
import 'package:creative_gym_mobile/features/submissions/data/mappers/submission_mapper.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';
import 'package:creative_gym_mobile/features/submissions/domain/submission.dart';
import 'package:creative_gym_mobile/features/submissions/domain/submissions_repository.dart';
import 'package:dio/dio.dart';

class ApiSubmissionsRepository implements SubmissionsRepository {
  const ApiSubmissionsRepository(this._client, [this._media]);

  final ApiClient _client;
  final MediaRepository? _media;

  @override
  Future<Submission?> getMine(String roomId) async {
    try {
      final json = await _client.getJson(
        '/api/v1/rooms/$roomId/submissions/me',
      );
      final dto = SubmissionEnvelopeDto.fromJson(json).submission;
      return dto == null ? null : SubmissionMapper.toDomain(dto);
    } on DioException catch (error) {
      throw _unwrap(error);
    }
  }

  @override
  Future<Submission> upload(
    String roomId,
    SelectedPhoto photo, {
    UploadProgress? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(photo.bytes, filename: photo.fileName),
      });
      final json = await _client.postMultipart(
        '/api/v1/rooms/$roomId/submissions',
        formData: formData,
        onSendProgress: onProgress,
      );
      final dto = SubmissionEnvelopeDto.fromJson(json).submission;
      if (dto == null) {
        throw const ApiException(
          message: 'Сервер не вернул сохраненную работу.',
        );
      }
      final submission = SubmissionMapper.toDomain(dto);
      _media?.prime(submission.mediaUrl, photo.bytes);
      return submission;
    } on DioException catch (error) {
      throw _unwrap(error);
    }
  }

  @override
  Future<Uint8List> loadMedia(Submission submission) async {
    try {
      final media = _media;
      if (media != null) {
        return await media.load(submission.mediaUrl);
      }
      return await _client.getBytes(submission.mediaUrl);
    } on DioException catch (error) {
      throw _unwrap(error);
    }
  }

  @override
  Future<void> delete(String submissionId) async {
    try {
      await _client.delete('/api/v1/submissions/$submissionId');
      _media?.evict('/api/v1/submissions/$submissionId/media');
    } on DioException catch (error) {
      throw _unwrap(error);
    }
  }

  ApiException _unwrap(DioException error) {
    final wrapped = error.error;
    if (wrapped is ApiException) {
      return wrapped;
    }
    return ApiException(message: error.message ?? 'Запрос не выполнен.');
  }
}
