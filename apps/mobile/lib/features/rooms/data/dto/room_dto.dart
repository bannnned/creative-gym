class RoomDto {
  const RoomDto({
    required this.id,
    required this.challengeId,
    required this.challengeTitle,
    required this.challengeTheme,
    required this.phase,
    required this.participantCount,
    required this.capacity,
    required this.viewerHasSubmission,
    required this.submissionEndsAt,
    required this.votingEndsAt,
  });

  final String id;
  final String challengeId;
  final String challengeTitle;
  final String challengeTheme;
  final String phase;
  final int participantCount;
  final int capacity;
  final bool viewerHasSubmission;
  final DateTime submissionEndsAt;
  final DateTime votingEndsAt;

  factory RoomDto.fromJson(Map<String, dynamic> json) {
    return RoomDto(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      challengeTitle: json['challenge_title'] as String,
      challengeTheme: json['challenge_theme'] as String,
      phase: json['phase'] as String? ?? 'submission',
      participantCount: json['participant_count'] as int? ?? 0,
      capacity: json['capacity'] as int? ?? 16,
      viewerHasSubmission: json['viewer_has_submission'] as bool? ?? false,
      submissionEndsAt: DateTime.parse(json['submission_ends_at'] as String),
      votingEndsAt: DateTime.parse(json['voting_ends_at'] as String),
    );
  }
}

class RoomDetailResponse {
  const RoomDetailResponse({required this.room});

  final RoomDto room;

  factory RoomDetailResponse.fromJson(Map<String, dynamic> json) {
    return RoomDetailResponse(
      room: RoomDto.fromJson(json['room'] as Map<String, dynamic>),
    );
  }
}

class JoinChallengeResponse {
  const JoinChallengeResponse({required this.room});

  final RoomDto room;

  factory JoinChallengeResponse.fromJson(Map<String, dynamic> json) {
    return JoinChallengeResponse(
      room: RoomDto.fromJson(json['room'] as Map<String, dynamic>),
    );
  }
}
