import 'package:creative_gym_mobile/features/challenges/domain/weekly_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WeeklyWorkout workout({
    required WeeklyWorkoutStage stage,
    bool joined = false,
    bool hasSubmission = false,
    bool hasVotingOptions = false,
    bool hasCompletedVoting = false,
  }) {
    return WeeklyWorkout(
      id: 'challenge-1',
      title: 'Тени города',
      theme: 'Тени',
      description: 'Описание',
      phase: 'Этап',
      stage: stage,
      submissionDeadlineLabel: 'Осталось 2 дня',
      submissionWindowLabel: '5 дней',
      votingWindowLabel: '2 дня',
      participantsLabel: '8 участников',
      roomSizeLabel: 'до 16 участников',
      roomId: joined ? 'room-1' : '',
      rules: const [],
      isJoined: joined,
      viewerHasSubmission: hasSubmission,
      viewerHasVotingOptions: hasVotingOptions,
      viewerHasCompletedVoting: hasCompletedVoting,
      coverUrl: null,
      viewerCanEdit: false,
    );
  }

  test('turns every viewer state into one clear next action', () {
    expect(
      workout(stage: WeeklyWorkoutStage.submission).nextAction,
      ChallengeNextAction.start,
    );
    expect(
      workout(stage: WeeklyWorkoutStage.submission, joined: true).nextAction,
      ChallengeNextAction.upload,
    );
    expect(
      workout(
        stage: WeeklyWorkoutStage.submission,
        joined: true,
        hasSubmission: true,
      ).nextAction,
      ChallengeNextAction.waitForVoting,
    );
    expect(
      workout(
        stage: WeeklyWorkoutStage.voting,
        joined: true,
        hasVotingOptions: true,
      ).nextAction,
      ChallengeNextAction.vote,
    );
    expect(
      workout(
        stage: WeeklyWorkoutStage.voting,
        joined: true,
        hasVotingOptions: true,
        hasCompletedVoting: true,
      ).nextAction,
      ChallengeNextAction.waitForResults,
    );
    expect(
      workout(stage: WeeklyWorkoutStage.results, joined: true).nextAction,
      ChallengeNextAction.viewResults,
    );
  });

  test('uses short action copy instead of phase names', () {
    final upload = workout(stage: WeeklyWorkoutStage.submission, joined: true);
    final vote = workout(
      stage: WeeklyWorkoutStage.voting,
      joined: true,
      hasVotingOptions: true,
    );

    expect(upload.guidanceLabel, 'Ждём твою фотографию');
    expect(upload.actionLabel, 'Загрузить фото');
    expect(vote.guidanceLabel, 'Работы собраны');
    expect(vote.actionLabel, 'Голосовать');
  });
}
