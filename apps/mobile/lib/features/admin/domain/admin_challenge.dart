enum AdminChallengePhase { upcoming, submission, voting, finished }

class AdminChallenge {
  const AdminChallenge({
    required this.id,
    required this.title,
    required this.theme,
    required this.description,
    required this.rules,
    required this.phase,
    required this.submissionStartsAt,
    required this.submissionEndsAt,
    required this.votingStartsAt,
    required this.votingEndsAt,
  });

  final String id;
  final String title;
  final String theme;
  final String description;
  final List<String> rules;
  final AdminChallengePhase phase;
  final DateTime submissionStartsAt;
  final DateTime submissionEndsAt;
  final DateTime votingStartsAt;
  final DateTime votingEndsAt;

  factory AdminChallenge.fromJson(Map<String, dynamic> json) {
    return AdminChallenge(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      theme: json['theme'] as String? ?? '',
      description: json['description'] as String? ?? '',
      rules: (json['rules'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      phase: adminPhaseFromApi(json['phase'] as String? ?? 'upcoming'),
      submissionStartsAt: DateTime.parse(
        json['submission_starts_at'] as String,
      ),
      submissionEndsAt: DateTime.parse(json['submission_ends_at'] as String),
      votingStartsAt: DateTime.parse(json['voting_starts_at'] as String),
      votingEndsAt: DateTime.parse(json['voting_ends_at'] as String),
    );
  }
}

class AdminChallengeDraft {
  const AdminChallengeDraft({
    required this.title,
    required this.theme,
    required this.description,
    required this.rules,
    required this.phase,
    this.original,
  });

  final String title;
  final String theme;
  final String description;
  final List<String> rules;
  final AdminChallengePhase phase;
  final AdminChallenge? original;

  Map<String, dynamic> toJson() {
    final dates = original != null && original!.phase == phase
        ? (
            submissionStartsAt: original!.submissionStartsAt,
            submissionEndsAt: original!.submissionEndsAt,
            votingStartsAt: original!.votingStartsAt,
            votingEndsAt: original!.votingEndsAt,
          )
        : datesForAdminPhase(phase);

    return {
      'title': title.trim(),
      'theme': theme.trim(),
      'description': description.trim(),
      'rules': rules
          .map((rule) => rule.trim())
          .where((rule) => rule.isNotEmpty)
          .toList(growable: false),
      'submission_starts_at': dates.submissionStartsAt
          .toUtc()
          .toIso8601String(),
      'submission_ends_at': dates.submissionEndsAt.toUtc().toIso8601String(),
      'voting_starts_at': dates.votingStartsAt.toUtc().toIso8601String(),
      'voting_ends_at': dates.votingEndsAt.toUtc().toIso8601String(),
    };
  }
}

AdminChallengePhase adminPhaseFromApi(String phase) {
  return switch (phase) {
    'submission' => AdminChallengePhase.submission,
    'voting' => AdminChallengePhase.voting,
    'results' || 'finished' => AdminChallengePhase.finished,
    _ => AdminChallengePhase.upcoming,
  };
}

String adminPhaseLabel(AdminChallengePhase phase) {
  return switch (phase) {
    AdminChallengePhase.upcoming => 'Скоро',
    AdminChallengePhase.submission => 'Приём работ',
    AdminChallengePhase.voting => 'Голосование',
    AdminChallengePhase.finished => 'Завершён',
  };
}

({
  DateTime submissionStartsAt,
  DateTime submissionEndsAt,
  DateTime votingStartsAt,
  DateTime votingEndsAt,
})
datesForAdminPhase(AdminChallengePhase phase) {
  final now = DateTime.now().toUtc();
  return switch (phase) {
    AdminChallengePhase.upcoming => (
      submissionStartsAt: now.add(const Duration(days: 1)),
      submissionEndsAt: now.add(const Duration(days: 6)),
      votingStartsAt: now.add(const Duration(days: 6)),
      votingEndsAt: now.add(const Duration(days: 8)),
    ),
    AdminChallengePhase.submission => (
      submissionStartsAt: now.subtract(const Duration(hours: 1)),
      submissionEndsAt: now.add(const Duration(days: 5)),
      votingStartsAt: now.add(const Duration(days: 5)),
      votingEndsAt: now.add(const Duration(days: 7)),
    ),
    AdminChallengePhase.voting => (
      submissionStartsAt: now.subtract(const Duration(days: 6)),
      submissionEndsAt: now.subtract(const Duration(minutes: 1)),
      votingStartsAt: now.subtract(const Duration(minutes: 1)),
      votingEndsAt: now.add(const Duration(days: 2)),
    ),
    AdminChallengePhase.finished => (
      submissionStartsAt: now.subtract(const Duration(days: 8)),
      submissionEndsAt: now.subtract(const Duration(days: 3)),
      votingStartsAt: now.subtract(const Duration(days: 3)),
      votingEndsAt: now.subtract(const Duration(minutes: 1)),
    ),
  };
}
