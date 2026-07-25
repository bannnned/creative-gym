import 'package:creative_gym_mobile/features/submissions/data/dto/submission_dto.dart';
import 'package:creative_gym_mobile/features/submissions/data/mappers/submission_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps submission API envelope into domain model', () {
    final envelope = SubmissionEnvelopeDto.fromJson({
      'submission': {
        'id': 'submission-1',
        'room_id': 'room-1',
        'media_url': '/api/v1/submissions/submission-1/media',
        'content_type': 'image/jpeg',
        'byte_size': 2048,
        'created_at': '2026-07-24T20:22:46Z',
        'updated_at': '2026-07-24T20:23:46Z',
      },
    });

    final submission = SubmissionMapper.toDomain(envelope.submission!);

    expect(submission.id, 'submission-1');
    expect(submission.roomId, 'room-1');
    expect(submission.mediaUrl, '/api/v1/submissions/submission-1/media');
    expect(submission.contentType, 'image/jpeg');
    expect(submission.byteSize, 2048);
    expect(submission.updatedAt.toUtc().year, 2026);
  });

  test('accepts an empty submission envelope', () {
    final envelope = SubmissionEnvelopeDto.fromJson({'submission': null});

    expect(envelope.submission, isNull);
  });
}
