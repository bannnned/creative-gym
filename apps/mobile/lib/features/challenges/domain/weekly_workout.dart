enum WeeklyWorkoutStage { upcoming, submission, voting, results }

enum ChallengeNextAction {
  start,
  upload,
  waitForVoting,
  vote,
  waitForResults,
  viewResults,
  upcoming,
  unavailable,
}

class WeeklyWorkout {
  const WeeklyWorkout({
    required this.id,
    required this.title,
    required this.theme,
    required this.description,
    required this.phase,
    this.stage = WeeklyWorkoutStage.submission,
    required this.submissionDeadlineLabel,
    required this.submissionWindowLabel,
    required this.votingWindowLabel,
    required this.participantsLabel,
    required this.roomSizeLabel,
    required this.roomId,
    required this.rules,
    required this.isJoined,
    this.viewerHasSubmission = false,
    this.viewerHasVotingOptions = false,
    this.viewerHasCompletedVoting = false,
    required this.coverUrl,
    required this.viewerCanEdit,
  });

  final String id;
  final String title;
  final String theme;
  final String description;
  final String phase;
  final WeeklyWorkoutStage stage;
  final String submissionDeadlineLabel;
  final String submissionWindowLabel;
  final String votingWindowLabel;
  final String participantsLabel;
  final String roomSizeLabel;
  final String roomId;
  final List<String> rules;
  final bool isJoined;
  final bool viewerHasSubmission;
  final bool viewerHasVotingOptions;
  final bool viewerHasCompletedVoting;
  final String? coverUrl;
  final bool viewerCanEdit;

  ChallengeNextAction get nextAction {
    return switch (stage) {
      WeeklyWorkoutStage.upcoming => ChallengeNextAction.upcoming,
      WeeklyWorkoutStage.submission =>
        !isJoined
            ? ChallengeNextAction.start
            : viewerHasSubmission
            ? ChallengeNextAction.waitForVoting
            : ChallengeNextAction.upload,
      WeeklyWorkoutStage.voting =>
        !isJoined
            ? ChallengeNextAction.unavailable
            : !viewerHasVotingOptions || viewerHasCompletedVoting
            ? ChallengeNextAction.waitForResults
            : ChallengeNextAction.vote,
      WeeklyWorkoutStage.results =>
        isJoined
            ? ChallengeNextAction.viewResults
            : ChallengeNextAction.unavailable,
    };
  }

  String get guidanceLabel {
    return switch (nextAction) {
      ChallengeNextAction.start => 'Сними одну фотографию на тему',
      ChallengeNextAction.upload => 'Ждём твою фотографию',
      ChallengeNextAction.waitForVoting => 'Фото принято · дальше голосование',
      ChallengeNextAction.vote => 'Работы собраны',
      ChallengeNextAction.waitForResults =>
        viewerHasCompletedVoting
            ? 'Ты проголосовал · ждём результат'
            : 'Ждём результат',
      ChallengeNextAction.viewResults => 'Итог готов',
      ChallengeNextAction.upcoming => 'Скоро можно будет начать',
      ChallengeNextAction.unavailable => 'Участие уже закрыто',
    };
  }

  String get actionLabel {
    return switch (nextAction) {
      ChallengeNextAction.start => 'Начать',
      ChallengeNextAction.upload => 'Загрузить фото',
      ChallengeNextAction.vote => 'Голосовать',
      ChallengeNextAction.viewResults => 'Посмотреть итог',
      ChallengeNextAction.waitForVoting ||
      ChallengeNextAction.waitForResults => 'Открыть',
      ChallengeNextAction.upcoming ||
      ChallengeNextAction.unavailable => 'Подробнее',
    };
  }

  int get homePriority {
    return switch (nextAction) {
      ChallengeNextAction.upload => 0,
      ChallengeNextAction.vote => 1,
      ChallengeNextAction.waitForVoting => 2,
      ChallengeNextAction.waitForResults => 3,
      ChallengeNextAction.start => 4,
      ChallengeNextAction.upcoming => 5,
      ChallengeNextAction.viewResults => 6,
      ChallengeNextAction.unavailable => 7,
    };
  }
}
