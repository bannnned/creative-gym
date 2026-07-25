class SubmissionDto {
  const SubmissionDto({
    required this.id,
    required this.roomId,
    required this.mediaUrl,
    required this.contentType,
    required this.byteSize,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String roomId;
  final String mediaUrl;
  final String contentType;
  final int byteSize;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SubmissionDto.fromJson(Map<String, dynamic> json) {
    return SubmissionDto(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      mediaUrl: json['media_url'] as String,
      contentType: json['content_type'] as String,
      byteSize: json['byte_size'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class SubmissionEnvelopeDto {
  const SubmissionEnvelopeDto({required this.submission});

  final SubmissionDto? submission;

  factory SubmissionEnvelopeDto.fromJson(Map<String, dynamic> json) {
    final submissionJson = json['submission'];
    return SubmissionEnvelopeDto(
      submission: submissionJson is Map<String, dynamic>
          ? SubmissionDto.fromJson(submissionJson)
          : null,
    );
  }
}
