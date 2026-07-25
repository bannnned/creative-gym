import 'package:creative_gym_mobile/app/creative_gym_app.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/config/app_config.dart';
import 'package:creative_gym_mobile/features/profile/presentation/widgets/crown_icon.dart';
import 'package:creative_gym_mobile/features/profile/presentation/widgets/profile_work_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => bootstrapApp(config: const AppConfig(mode: DataSourceMode.mock)));

  Future<void> openChallenges(WidgetTester tester) async {
    await tester.pumpWidget(const CreativeGymApp());
    await tester.tap(find.byKey(const ValueKey('continue-button')));
    await tester.pumpAndSettle();
  }

  Future<void> chooseWorkout(WidgetTester tester, String title) async {
    final titleFinder = find.text(title);
    await tester.scrollUntilVisible(
      titleFinder,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(titleFinder);
    await tester.pumpAndSettle();
  }

  testWidgets('login has one clear action', (tester) async {
    await tester.pumpWidget(const CreativeGymApp());

    expect(find.text('Creative Gym'), findsOneWidget);
    expect(find.text('Тренируй\nвзгляд.'), findsOneWidget);
    expect(
      find.text('Один челлендж. Один кадр. Каждую неделю.'),
      findsOneWidget,
    );
    expect(find.text('Продолжить'), findsOneWidget);
    expect(find.textContaining('Google'), findsNothing);
    expect(find.textContaining('Yandex'), findsNothing);
  });

  testWidgets('login opens the minimalist challenge selection', (tester) async {
    await openChallenges(tester);

    expect(find.text('Челленджи'), findsOneWidget);
    expect(find.byKey(const ValueKey('challenge-list')), findsOneWidget);
    expect(find.text('Утренний свет'), findsOneWidget);
    expect(find.text('Тихое движение'), findsOneWidget);
    expect(find.text('Осталось 3 дня'), findsOneWidget);
    expect(find.text('Другие задания'), findsNothing);

    final firstCardTop = tester.getTopLeft(
      find.byKey(const ValueKey('challenge-card-morning-light')),
    );
    expect(firstCardTop.dy, greaterThan(64));
  });

  testWidgets('challenge card opens one focused assignment', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await openChallenges(tester);
    await chooseWorkout(tester, 'Тихое движение');

    expect(find.text('Задание недели'), findsOneWidget);
    expect(find.text('Челлендж'), findsNothing);
    expect(find.byKey(const ValueKey('current-workout-title')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('primary-workout-action')),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Работы собраны'), findsOneWidget);
    expect(find.text('Сравнить фотографии'), findsOneWidget);
    expect(find.text('Weekly Workouts'), findsNothing);
    expect(find.text('Gym Room'), findsNothing);
  });

  testWidgets('profile shows stats, winner filter, and swipe viewer', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await openChallenges(tester);
    await tester.tap(find.byKey(const ValueKey('profile-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profile-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-menu-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-points')), findsOneWidget);
    expect(find.text('840'), findsOneWidget);
    expect(find.text('Работы'), findsOneWidget);
    expect(find.byType(CrownIcon), findsNWidgets(8));
    expect(find.byType(ProfileWorkArtwork), findsNWidgets(12));

    await tester.tap(find.byKey(const ValueKey('winners-toggle')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileWorkArtwork), findsNWidgets(5));

    await tester.tap(find.byKey(const ValueKey('profile-work-work-01')));
    await tester.pumpAndSettle();

    final viewerFinder = find.byKey(const ValueKey('profile-photo-viewer'));
    expect(viewerFinder, findsOneWidget);
    await tester.drag(viewerFinder, const Offset(-320, 0));
    await tester.pumpAndSettle();

    final viewer = tester.widget<PageView>(viewerFinder);
    expect(viewer.controller?.page, closeTo(1, 0.01));
  });

  testWidgets('rules stay behind a secondary action', (tester) async {
    await openChallenges(tester);
    await chooseWorkout(tester, 'Утренний свет');

    await tester.tap(find.text('Условия'));
    await tester.pumpAndSettle();

    expect(find.text('Условия'), findsWidgets);
    expect(find.textContaining('• '), findsWidgets);
  });

  testWidgets('photo flow keeps one primary action', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await openChallenges(tester);
    await chooseWorkout(tester, 'Утренний свет');

    expect(find.text('Начать'), findsOneWidget);
    await tester.tap(find.text('Начать'));
    await tester.pumpAndSettle();

    expect(find.text('Фото'), findsOneWidget);
    expect(find.text('Выбрать фото'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pick-photo-button')));
    await tester.pumpAndSettle();

    expect(find.text('Фото выбрано'), findsOneWidget);
    expect(find.text('Загрузить фото'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('upload-photo-button')));
    await tester.pumpAndSettle();

    expect(find.text('Фото принято'), findsOneWidget);
    expect(find.text('Фото сохранено'), findsOneWidget);
    expect(find.text('Заменить'), findsOneWidget);
  });

  testWidgets('tapping a photo records a comparison', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await openChallenges(tester);
    await chooseWorkout(tester, 'Тихое движение');
    await tester.scrollUntilVisible(
      find.text('Сравнить фотографии'),
      180,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Сравнить фотографии'));
    await tester.pumpAndSettle();

    expect(find.text('Какой кадр сильнее?'), findsOneWidget);
    expect(find.text('1 из 3'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('vote-Frame A')));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Выбор принят'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();
    expect(find.text('2 из 3'), findsOneWidget);
  });

  testWidgets('results lead with the user outcome', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await openChallenges(tester);
    await chooseWorkout(tester, 'Вечерние контуры');
    await tester.scrollUntilVisible(
      find.text('Посмотреть итог'),
      180,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Посмотреть итог'));
    await tester.pumpAndSettle();

    expect(find.text('Итог'), findsOneWidget);
    expect(find.text('Тренировка завершена'), findsOneWidget);
    expect(find.text('Ваш кадр'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Посмотреть все работы'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Посмотреть все работы'), findsOneWidget);

    await tester.tap(find.text('Посмотреть все работы'));
    await tester.pumpAndSettle();
    expect(find.text('Скрыть работы'), findsOneWidget);
    expect(find.text('Ваш кадр'), findsWidgets);
  });
}
