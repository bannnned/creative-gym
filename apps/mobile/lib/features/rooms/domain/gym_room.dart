enum GymRoomPhase { upcoming, submission, voting, results }

class GymRoom {
  const GymRoom({
    required this.id,
    required this.challengeId,
    required this.challengeTitle,
    required this.challengeTheme,
    required this.phase,
    required this.deadlineLabel,
    required this.participantCount,
    required this.maxParticipants,
    required this.hasSubmission,
    required this.submissionStatusLabel,
    required this.nextStepLabel,
  });

  final String id;
  final String challengeId;
  final String challengeTitle;
  final String challengeTheme;
  final GymRoomPhase phase;
  final String deadlineLabel;
  final int participantCount;
  final int maxParticipants;
  final bool hasSubmission;
  final String submissionStatusLabel;
  final String nextStepLabel;

  String get participantsLabel => '$participantCount из $maxParticipants';

  String get phaseLabel {
    return switch (phase) {
      GymRoomPhase.upcoming => 'Скоро старт',
      GymRoomPhase.submission => 'Прием работ',
      GymRoomPhase.voting => 'Голосование',
      GymRoomPhase.results => 'Результаты',
    };
  }

  bool get canUpload => phase == GymRoomPhase.submission;
  bool get canVote => phase == GymRoomPhase.voting;
  bool get canViewResults => phase == GymRoomPhase.results;

  String get phaseHelpLabel {
    return switch (phase) {
      GymRoomPhase.upcoming => 'Комната откроется после старта Weekly Workout.',
      GymRoomPhase.submission =>
        hasSubmission
            ? 'Фото можно заменить до закрытия приема работ.'
            : 'Добавьте одну фотографию до закрытия приема работ.',
      GymRoomPhase.voting =>
        'Прием работ закрыт. Теперь сравните анонимные пары.',
      GymRoomPhase.results =>
        'Голосование закрыто. Посмотрите итоги этой Gym Room.',
    };
  }
}
