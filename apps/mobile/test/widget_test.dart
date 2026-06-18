import 'dart:math' as math;

import 'package:creative_gym_mobile/app/creative_gym_app.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    bootstrapApp();
  });
  Future<void> openWeeklyWorkouts(WidgetTester tester) async {
    await tester.pumpWidget(const CreativeGymApp());

    await tester.scrollUntilVisible(
      find.text('Продолжить в демо'),
      120,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Продолжить в демо'));
    await tester.pumpAndSettle();
  }

  Future<void> openGymRoom(
    WidgetTester tester, {
    String challengeId = 'morning-light',
    String roomButtonLabel = 'Join Gym Room',
  }) async {
    await openWeeklyWorkouts(tester);

    final cardFinder = find.byKey(ValueKey('weekly-workout-$challengeId'));
    await tester.scrollUntilVisible(
      cardFinder,
      260,
      scrollable: find.byType(Scrollable),
    );
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    for (var index = 0; index < 6; index += 1) {
      final top = tester.getTopLeft(cardFinder).dy;
      final bottom = tester.getBottomRight(cardFinder).dy;
      if (top > screenHeight - 120) {
        await tester.drag(find.byType(Scrollable), const Offset(0, -260));
        await tester.pumpAndSettle();
      } else if (bottom < 120) {
        await tester.drag(find.byType(Scrollable), const Offset(0, 260));
        await tester.pumpAndSettle();
      } else {
        break;
      }
    }
    final topLeft = tester.getTopLeft(cardFinder);
    final bottomRight = tester.getBottomRight(cardFinder);
    final tapY =
        (math.max(topLeft.dy, 120) +
            math.min(bottomRight.dy, screenHeight - 120)) /
        2;
    await tester.tapAt(Offset((topLeft.dx + bottomRight.dx) / 2, tapY));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(roomButtonLabel),
      200,
      scrollable: find.byType(Scrollable),
    );
    final roomButtonFinder = find.text(roomButtonLabel);
    final roomButtonCenter = tester.getCenter(roomButtonFinder);
    if (roomButtonCenter.dy > screenHeight - 60) {
      await tester.drag(find.byType(Scrollable), const Offset(0, -100));
      await tester.pumpAndSettle();
    }
    await tester.tap(roomButtonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> openVoting(WidgetTester tester) async {
    await openGymRoom(
      tester,
      challengeId: 'quiet-motion',
      roomButtonLabel: 'Открыть Gym Room',
    );

    await tester.scrollUntilVisible(
      find.text('Начать голосование'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Начать голосование'));
    await tester.pumpAndSettle();
  }

  Future<void> voteLeftAndSettle(WidgetTester tester) async {
    await tester.tap(find.text('Выбрать левый'));
    await tester.pump(const Duration(milliseconds: 420));
    await tester.pumpAndSettle();
  }

  testWidgets('shows login providers', (tester) async {
    await tester.pumpWidget(const CreativeGymApp());

    expect(find.text('Creative Gym'), findsOneWidget);
    expect(find.text('Войти через Google'), findsOneWidget);
    expect(find.text('Войти через Yandex'), findsOneWidget);
    expect(find.text('Войти через GitHub'), findsOneWidget);
    expect(find.text('Продолжить в демо'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
  });

  testWidgets('opens weekly workouts demo screen', (tester) async {
    await openWeeklyWorkouts(tester);

    expect(find.text('Weekly Workouts'), findsOneWidget);
    expect(find.text('Активные фото-тренировки'), findsOneWidget);
    expect(find.text('Прием работ'), findsWidgets);
    expect(find.text('Утренний свет'), findsOneWidget);
    expect(find.text('Подробнее'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Голосование сейчас'),
      260,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Голосование сейчас'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Завершенные'),
      260,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Завершенные'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Скоро'),
      260,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Скоро'), findsOneWidget);
  });

  testWidgets('opens challenge details from weekly workouts', (tester) async {
    await openWeeklyWorkouts(tester);

    await tester.tap(find.text('Утренний свет'));
    await tester.pumpAndSettle();

    expect(find.text('Challenge Details'), findsOneWidget);
    expect(find.text('Свет и тень'), findsOneWidget);
    expect(find.text('Правила'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Join Gym Room'),
      200,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Join Gym Room'), findsOneWidget);
  });

  testWidgets('opens gym room from challenge details', (tester) async {
    await openGymRoom(tester);

    expect(find.text('Gym Room'), findsOneWidget);
    expect(find.text('Фото еще не добавлено'), findsOneWidget);
    expect(find.text('Добавить фото'), findsOneWidget);
    expect(find.text('Состав комнаты'), findsOneWidget);
    expect(find.text('Demo shortcuts'), findsOneWidget);
  });

  testWidgets('opens upload flow and saves demo photo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await openGymRoom(tester);

    await tester.tap(find.text('Добавить фото'));
    await tester.pumpAndSettle();

    expect(find.text('Upload Photo'), findsOneWidget);
    expect(find.text('Фото не выбрано'), findsOneWidget);

    await tester.tap(find.text('Выбрать фото'));
    await tester.pumpAndSettle();

    expect(find.text('Фото выбрано'), findsOneWidget);
    expect(find.text('Сохранить'), findsOneWidget);

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Фото загружено'), findsOneWidget);
    expect(find.text('Фото сохранено в демо-режиме.'), findsOneWidget);
  });

  testWidgets('opens voting flow and records a demo vote', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await openVoting(tester);

    expect(find.text('Voting'), findsOneWidget);
    expect(find.text('Пара 1 из 3'), findsOneWidget);
    expect(find.text('Выбрать левый'), findsOneWidget);
    expect(find.text('Выбрать правый'), findsOneWidget);
    expect(find.text('Пропустить пару'), findsOneWidget);

    await tester.tap(find.text('Выбрать левый'));
    await tester.pump(const Duration(milliseconds: 120));

    expect(
      find.text('Выбор принят, загружаем следующую пару...'),
      findsOneWidget,
    );
    expect(find.text('Выбрано'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 420));
    await tester.pumpAndSettle();

    expect(find.text('Пара 2 из 3'), findsOneWidget);
    expect(find.text('1 выбрано'), findsOneWidget);

    await tester.tap(find.text('Пропустить пару'));
    await tester.pumpAndSettle();

    expect(find.text('Пара 3 из 3'), findsOneWidget);
    expect(find.text('1 выбрано'), findsOneWidget);
  });

  testWidgets('opens results from completed gym room', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await openGymRoom(
      tester,
      challengeId: 'evening-shapes',
      roomButtonLabel: 'Открыть Gym Room',
    );

    await tester.scrollUntilVisible(
      find.text('Посмотреть результаты'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.drag(find.byType(Scrollable), const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Посмотреть результаты'));
    await tester.pumpAndSettle();

    expect(find.text('Results'), findsOneWidget);
    expect(find.text('Итоги Gym Room'), findsOneWidget);
    expect(find.text('Ваш результат'), findsOneWidget);
    expect(find.text('#3 в комнате'), findsOneWidget);
  });

  testWidgets('opens results after completing voting flow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await openVoting(tester);

    await voteLeftAndSettle(tester);
    await voteLeftAndSettle(tester);
    await voteLeftAndSettle(tester);

    expect(find.text('Голосование завершено'), findsOneWidget);
    expect(find.text('Посмотреть результаты'), findsOneWidget);

    await tester.tap(find.text('Посмотреть результаты'));
    await tester.pumpAndSettle();

    expect(find.text('Results'), findsOneWidget);
    expect(find.text('Сильнее всего считалось'), findsOneWidget);
  });
}
