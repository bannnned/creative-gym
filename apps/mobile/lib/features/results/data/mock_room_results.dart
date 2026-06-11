import 'package:creative_gym_mobile/features/results/domain/room_result.dart';

const mockRoomResults = [
  RoomResult(
    roomId: 'room-morning-light',
    participantsCount: 12,
    submissionsCount: 10,
    completionLabel: 'Workout завершен',
    encouragementLabel:
        'Сохраните наблюдение недели и возвращайтесь к следующей тренировке.',
    currentUserSubmission: ResultSubmission(
      id: 'morning-light-user',
      rank: 4,
      title: 'Теплая тень на кухне',
      authorLabel: 'Ваш кадр',
      wins: 5,
      comparisons: 8,
      paletteStart: 0xFFDDBB8D,
      paletteEnd: 0xFF24493F,
      isCurrentUser: true,
    ),
    rankedSubmissions: [
      ResultSubmission(
        id: 'morning-light-top-1',
        rank: 1,
        title: 'Окно после дождя',
        authorLabel: 'Анонимный участник',
        wins: 8,
        comparisons: 9,
        paletteStart: 0xFFF1C27D,
        paletteEnd: 0xFF416A5A,
      ),
      ResultSubmission(
        id: 'morning-light-top-2',
        rank: 2,
        title: 'Луч на лестнице',
        authorLabel: 'Анонимный участник',
        wins: 7,
        comparisons: 9,
        paletteStart: 0xFFE9A66F,
        paletteEnd: 0xFF8F5D42,
      ),
      ResultSubmission(
        id: 'morning-light-top-3',
        rank: 3,
        title: 'Силуэт растения',
        authorLabel: 'Анонимный участник',
        wins: 6,
        comparisons: 8,
        paletteStart: 0xFFA8C9B7,
        paletteEnd: 0xFF17483C,
      ),
      ResultSubmission(
        id: 'morning-light-user',
        rank: 4,
        title: 'Теплая тень на кухне',
        authorLabel: 'Ваш кадр',
        wins: 5,
        comparisons: 8,
        paletteStart: 0xFFDDBB8D,
        paletteEnd: 0xFF24493F,
        isCurrentUser: true,
      ),
    ],
  ),
  RoomResult(
    roomId: 'room-quiet-motion',
    participantsCount: 8,
    submissionsCount: 8,
    completionLabel: 'Голосование закрыто',
    encouragementLabel:
        'Результаты показывают, какие ритмы сильнее считывались в комнате.',
    currentUserSubmission: ResultSubmission(
      id: 'quiet-motion-user',
      rank: 2,
      title: 'Переход на зеленый',
      authorLabel: 'Ваш кадр',
      wins: 6,
      comparisons: 7,
      paletteStart: 0xFF8FBFAA,
      paletteEnd: 0xFF2F6F5E,
      isCurrentUser: true,
    ),
    rankedSubmissions: [
      ResultSubmission(
        id: 'quiet-motion-top-1',
        rank: 1,
        title: 'Трамвайная пауза',
        authorLabel: 'Анонимный участник',
        wins: 7,
        comparisons: 7,
        paletteStart: 0xFFC66A4A,
        paletteEnd: 0xFF17211C,
      ),
      ResultSubmission(
        id: 'quiet-motion-user',
        rank: 2,
        title: 'Переход на зеленый',
        authorLabel: 'Ваш кадр',
        wins: 6,
        comparisons: 7,
        paletteStart: 0xFF8FBFAA,
        paletteEnd: 0xFF2F6F5E,
        isCurrentUser: true,
      ),
      ResultSubmission(
        id: 'quiet-motion-top-3',
        rank: 3,
        title: 'Шаги у витрины',
        authorLabel: 'Анонимный участник',
        wins: 4,
        comparisons: 7,
        paletteStart: 0xFFDDBB8D,
        paletteEnd: 0xFF8F5D42,
      ),
    ],
  ),
  RoomResult(
    roomId: 'room-evening-shapes',
    participantsCount: 14,
    submissionsCount: 12,
    completionLabel: 'Комната завершена',
    encouragementLabel:
        'Силуэты недели собраны. Отметьте, какие решения хочется повторить в следующей тренировке.',
    currentUserSubmission: ResultSubmission(
      id: 'evening-shapes-user',
      rank: 3,
      title: 'Контур остановки',
      authorLabel: 'Ваш кадр',
      wins: 7,
      comparisons: 10,
      paletteStart: 0xFFDDBB8D,
      paletteEnd: 0xFF17211C,
      isCurrentUser: true,
    ),
    rankedSubmissions: [
      ResultSubmission(
        id: 'evening-shapes-top-1',
        rank: 1,
        title: 'Крыша на закате',
        authorLabel: 'Анонимный участник',
        wins: 10,
        comparisons: 10,
        paletteStart: 0xFFC66A4A,
        paletteEnd: 0xFF17211C,
      ),
      ResultSubmission(
        id: 'evening-shapes-top-2',
        rank: 2,
        title: 'Тонкая линия окна',
        authorLabel: 'Анонимный участник',
        wins: 8,
        comparisons: 10,
        paletteStart: 0xFFE9A66F,
        paletteEnd: 0xFF6E4654,
      ),
      ResultSubmission(
        id: 'evening-shapes-user',
        rank: 3,
        title: 'Контур остановки',
        authorLabel: 'Ваш кадр',
        wins: 7,
        comparisons: 10,
        paletteStart: 0xFFDDBB8D,
        paletteEnd: 0xFF17211C,
        isCurrentUser: true,
      ),
    ],
  ),
];

RoomResult? findMockRoomResultByRoomId(String roomId) {
  for (final result in mockRoomResults) {
    if (result.roomId == roomId) {
      return result;
    }
  }

  return null;
}
