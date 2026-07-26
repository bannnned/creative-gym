import 'package:creative_gym_mobile/features/results/domain/room_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('celebrates a prize place', () {
    expect(_resultWithRank(1).outcomeActionLabel, 'Ура!');
    expect(_resultWithRank(3).outcomeActionLabel, 'Ура!');
  });

  test('accepts a non-prize result calmly', () {
    expect(_resultWithRank(4).outcomeActionLabel, 'Ну штош');
    expect(_resultWithoutOwnWork().outcomeActionLabel, 'Ну штош');
  });
}

RoomResult _resultWithRank(int rank) {
  return RoomResult(
    roomId: 'room',
    participantsCount: 4,
    submissionsCount: 4,
    completionLabel: 'Завершено',
    encouragementLabel: 'Продолжаем.',
    currentUserSubmission: ResultSubmission(
      id: 'mine',
      rank: rank,
      title: 'Работа',
      authorLabel: 'Ваш кадр',
      wins: 1,
      comparisons: 3,
      paletteStart: 0xFFFFFFFF,
      paletteEnd: 0xFF000000,
      isCurrentUser: true,
    ),
    rankedSubmissions: const [],
  );
}

RoomResult _resultWithoutOwnWork() {
  return const RoomResult(
    roomId: 'room',
    participantsCount: 4,
    submissionsCount: 3,
    completionLabel: 'Завершено',
    encouragementLabel: 'Продолжаем.',
    currentUserSubmission: null,
    rankedSubmissions: [],
  );
}
