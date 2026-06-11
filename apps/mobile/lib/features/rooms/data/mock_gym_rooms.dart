import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';

const mockGymRooms = [
  GymRoom(
    id: 'room-morning-light',
    challengeId: 'morning-light',
    challengeTitle: 'Утренний свет',
    challengeTheme: 'Свет и тень',
    phase: GymRoomPhase.submission,
    deadlineLabel: 'Осталось 3 дня',
    participantCount: 12,
    maxParticipants: 16,
    hasSubmission: false,
    submissionStatusLabel: 'Фото еще не добавлено',
    nextStepLabel: 'Добавьте одну фотографию до закрытия приема работ.',
  ),
  GymRoom(
    id: 'room-quiet-motion',
    challengeId: 'quiet-motion',
    challengeTitle: 'Тихое движение',
    challengeTheme: 'Ритм в городе',
    phase: GymRoomPhase.voting,
    deadlineLabel: 'Голосование 2 дня',
    participantCount: 8,
    maxParticipants: 16,
    hasSubmission: true,
    submissionStatusLabel: 'Фото добавлено',
    nextStepLabel: 'Прием работ закрыт. Переходите к анонимному сравнению.',
  ),
  GymRoom(
    id: 'room-evening-shapes',
    challengeId: 'evening-shapes',
    challengeTitle: 'Вечерние контуры',
    challengeTheme: 'Форма и силуэт',
    phase: GymRoomPhase.results,
    deadlineLabel: 'Завершено',
    participantCount: 14,
    maxParticipants: 16,
    hasSubmission: true,
    submissionStatusLabel: 'Фото участвовало',
    nextStepLabel: 'Голосование закрыто. Результаты комнаты доступны.',
  ),
  GymRoom(
    id: 'room-small-rituals',
    challengeId: 'small-rituals',
    challengeTitle: 'Маленькие ритуалы',
    challengeTheme: 'Повседневность',
    phase: GymRoomPhase.upcoming,
    deadlineLabel: 'Старт завтра',
    participantCount: 1,
    maxParticipants: 16,
    hasSubmission: false,
    submissionStatusLabel: 'Прием работ еще не открыт',
    nextStepLabel: 'Комната откроется после старта Weekly Workout.',
  ),
];

GymRoom? findMockGymRoomById(String id) {
  for (final room in mockGymRooms) {
    if (room.id == id) {
      return room;
    }
  }

  return null;
}
