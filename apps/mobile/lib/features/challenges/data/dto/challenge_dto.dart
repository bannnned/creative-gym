class ChallengeDto {
  const ChallengeDto({
    required this.id,
    required this.kind,
    required this.title,
    required this.theme,
    required this.description,
    required this.rules,
    required this.status,
    required this.phase,
    required this.submissionStartsAt,
    required this.submissionEndsAt,
    required this.votingStartsAt,
    required this.votingEndsAt,
    required this.participantCount,
    required this.roomCapacity,
    required this.viewerRoomId,
    required this.viewerHasJoined,
  });

  final String id;
  final String kind;
  final String title;
  final String theme;
  final String description;
  final List<String> rules;
  final String status;
  final String phase;
  final DateTime submissionStartsAt;
  final DateTime submissionEndsAt;
  final DateTime votingStartsAt;
  final DateTime votingEndsAt;
  final int participantCount;
  final int roomCapacity;
  final String? viewerRoomId;
  final bool viewerHasJoined;

  factory ChallengeDto.fromJson(Map<String, dynamic> json) {
    return ChallengeDto(
      id: json['id'] as String,
      kind: json['kind'] as String? ?? 'photo',
      title: json['title'] as String,
      theme: json['theme'] as String,
      description: json['description'] as String? ?? '',
      rules: (json['rules'] as List<dynamic>? ?? const [])
          .map((rule) => rule as String)
          .toList(growable: false),
      status: json['status'] as String? ?? 'submitting',
      phase: json['phase'] as String? ?? 'submission',
      submissionStartsAt: DateTime.parse(
        json['submission_starts_at'] as String,
      ),
      submissionEndsAt: DateTime.parse(json['submission_ends_at'] as String),
      votingStartsAt: DateTime.parse(json['voting_starts_at'] as String),
      votingEndsAt: DateTime.parse(json['voting_ends_at'] as String),
      participantCount: json['participant_count'] as int? ?? 0,
      roomCapacity: json['room_capacity'] as int? ?? 16,
      viewerRoomId: json['viewer_room_id'] as String?,
      viewerHasJoined: json['viewer_has_joined'] as bool? ?? false,
    );
  }
}

class ActiveChallengesResponse {
  const ActiveChallengesResponse({required this.challenges});

  final List<ChallengeDto> challenges;

  factory ActiveChallengesResponse.fromJson(Map<String, dynamic> json) {
    final items = json['challenges'] as List<dynamic>? ?? const [];
    return ActiveChallengesResponse(
      challenges: items
          .map((item) => ChallengeDto.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class ChallengeDetailResponse {
  const ChallengeDetailResponse({required this.challenge});

  final ChallengeDto challenge;

  factory ChallengeDetailResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeDetailResponse(
      challenge: ChallengeDto.fromJson(
        json['challenge'] as Map<String, dynamic>,
      ),
    );
  }
}
