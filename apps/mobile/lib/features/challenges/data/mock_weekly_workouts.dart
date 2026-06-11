import 'package:creative_gym_mobile/features/challenges/domain/weekly_workout.dart';

const mockWeeklyWorkouts = [
  WeeklyWorkout(
    id: 'morning-light',
    title: 'Утренний свет',
    theme: 'Свет и тень',
    description: 'Найдите мягкий утренний свет и соберите кадр без постановки.',
    phase: 'Прием работ',
    submissionDeadlineLabel: 'Осталось 3 дня',
    submissionWindowLabel: '5 дней на одну фотографию',
    votingWindowLabel: '2 дня анонимного сравнения',
    participantsLabel: '12 участников',
    roomSizeLabel: '8-16 участников в Gym Room',
    roomId: 'room-morning-light',
    rules: [
      'Сделайте одну фотографию на тему света и тени.',
      'Не используйте постановочную съемку или коллаж.',
      'Фото можно заменить до закрытия приема работ.',
    ],
    isJoined: false,
  ),
  WeeklyWorkout(
    id: 'quiet-motion',
    title: 'Тихое движение',
    theme: 'Ритм в городе',
    description: 'Покажите движение без суеты: жест, шаг, отражение или паузу.',
    phase: 'Голосование',
    submissionDeadlineLabel: 'Голосование 2 дня',
    submissionWindowLabel: '5 дней на одну фотографию',
    votingWindowLabel: '2 дня анонимного сравнения',
    participantsLabel: '8 участников',
    roomSizeLabel: '8-16 участников в Gym Room',
    roomId: 'room-quiet-motion',
    rules: [
      'Покажите движение через городскую деталь.',
      'Избегайте очевидных спортивных сюжетов.',
      'Авторство скрыто до завершения голосования.',
    ],
    isJoined: true,
  ),
  WeeklyWorkout(
    id: 'evening-shapes',
    title: 'Вечерние контуры',
    theme: 'Форма и силуэт',
    description:
        'Разберите вечерний свет на простые формы и найдите сильный силуэт.',
    phase: 'Результаты',
    submissionDeadlineLabel: 'Завершено',
    submissionWindowLabel: '5 дней на одну фотографию',
    votingWindowLabel: '2 дня анонимного сравнения',
    participantsLabel: '14 участников',
    roomSizeLabel: '8-16 участников в Gym Room',
    roomId: 'room-evening-shapes',
    rules: [
      'Ищите силуэт, который читается без подписи.',
      'Не используйте коллаж или тяжелую обработку.',
      'Результаты показывают наблюдения комнаты, а не публичный рейтинг.',
    ],
    isJoined: true,
  ),
  WeeklyWorkout(
    id: 'small-rituals',
    title: 'Маленькие ритуалы',
    theme: 'Повседневность',
    description:
        'Снимите привычное действие так, чтобы оно стало внимательным.',
    phase: 'Скоро старт',
    submissionDeadlineLabel: 'Старт завтра',
    submissionWindowLabel: '5 дней на одну фотографию',
    votingWindowLabel: '2 дня анонимного сравнения',
    participantsLabel: 'Ожидает комнату',
    roomSizeLabel: '8-16 участников в Gym Room',
    roomId: 'room-small-rituals',
    rules: [
      'Выберите один повторяющийся бытовой ритуал.',
      'Кадр должен работать без подписи и объяснения.',
      'Не публикуйте чужие лица без согласия.',
    ],
    isJoined: false,
  ),
];

WeeklyWorkout? findMockWeeklyWorkoutById(String id) {
  for (final workout in mockWeeklyWorkouts) {
    if (workout.id == id) {
      return workout;
    }
  }

  return null;
}
