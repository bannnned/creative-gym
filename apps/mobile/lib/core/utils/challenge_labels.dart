import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';

String weeklyWorkoutPhaseLabel(String apiPhase) {
  return switch (apiPhase) {
    'submission' => 'Прием работ',
    'voting' => 'Голосование',
    'finished' => 'Результаты',
    'scheduled' => 'Скоро старт',
    _ => apiPhase,
  };
}

GymRoomPhase gymRoomPhaseFromApi(String apiPhase) {
  return switch (apiPhase) {
    'submission' => GymRoomPhase.submission,
    'voting' => GymRoomPhase.voting,
    'finished' => GymRoomPhase.results,
    'scheduled' => GymRoomPhase.upcoming,
    _ => GymRoomPhase.upcoming,
  };
}

String deadlineLabelForPhase({
  required String apiPhase,
  DateTime? submissionEndsAt,
  DateTime? votingEndsAt,
}) {
  return switch (apiPhase) {
    'finished' => 'Завершено',
    'voting' => _relativeDeadlineLabel(votingEndsAt, fallback: 'Голосование'),
    'scheduled' => 'Старт скоро',
    _ => _relativeDeadlineLabel(
      submissionEndsAt,
      fallback: 'Прием работ открыт',
    ),
  };
}

String _relativeDeadlineLabel(DateTime? endsAt, {required String fallback}) {
  if (endsAt == null) {
    return fallback;
  }

  final remaining = endsAt.difference(DateTime.now().toUtc());
  if (remaining.isNegative) {
    return 'Завершено';
  }

  if (remaining.inDays >= 1) {
    return 'Осталось ${remaining.inDays} дн.';
  }

  if (remaining.inHours >= 1) {
    return 'Осталось ${remaining.inHours} ч.';
  }

  return 'Завершается скоро';
}

String participantsLabel(int count) {
  return '$count участников';
}

String roomSizeLabel(int capacity) {
  return 'до $capacity участников в Gym Room';
}

String submissionWindowLabel(DateTime startsAt, DateTime endsAt) {
  final days = endsAt.difference(startsAt).inDays;
  if (days <= 0) {
    return 'Одна фотография на Weekly Workout';
  }

  return '$days дн. на одну фотографию';
}

String votingWindowLabel(DateTime startsAt, DateTime endsAt) {
  final days = endsAt.difference(startsAt).inDays;
  if (days <= 0) {
    return 'Анонимное сравнение';
  }

  return '$days дн. анонимного сравнения';
}

String submissionStatusLabel({
  required GymRoomPhase phase,
  required bool hasSubmission,
}) {
  return switch (phase) {
    GymRoomPhase.upcoming => 'Прием работ еще не открыт',
    GymRoomPhase.submission =>
      hasSubmission ? 'Фото добавлено' : 'Фото еще не добавлено',
    GymRoomPhase.voting =>
      hasSubmission ? 'Фото добавлено' : 'Фото не было добавлено',
    GymRoomPhase.results =>
      hasSubmission ? 'Фото участвовало' : 'Фото не участвовало',
  };
}

String roomNextStepLabel({
  required GymRoomPhase phase,
  required bool hasSubmission,
}) {
  return switch (phase) {
    GymRoomPhase.upcoming => 'Комната откроется после старта Weekly Workout.',
    GymRoomPhase.submission =>
      hasSubmission
          ? 'Можно заменить фото до закрытия приема работ.'
          : 'Добавьте одну фотографию до закрытия приема работ.',
    GymRoomPhase.voting =>
      'Прием работ закрыт. Переходите к анонимному сравнению.',
    GymRoomPhase.results => 'Голосование закрыто. Результаты комнаты доступны.',
  };
}
