import 'package:creative_gym_mobile/features/submissions/data/dto/submission_dto.dart';
import 'package:creative_gym_mobile/features/submissions/domain/submission.dart';

abstract final class SubmissionMapper {
  static Submission toDomain(SubmissionDto dto) {
    return Submission(
      id: dto.id,
      roomId: dto.roomId,
      mediaUrl: dto.mediaUrl,
      contentType: dto.contentType,
      byteSize: dto.byteSize,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }
}
