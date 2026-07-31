import 'package:creative_gym_mobile/app/creative_gym_app.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/config/app_config.dart';
import 'package:creative_gym_mobile/features/profile/presentation/widgets/crown_icon.dart';
import 'package:creative_gym_mobile/features/profile/presentation/widgets/profile_work_artwork.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    bootstrapApp(config: const AppConfig(mode: DataSourceMode.mock));
    await appDependencies.onboarding.setEnabled(false);
  });

  Future<void> openChallenges(WidgetTester tester) async {
    // Recreate the app so routes and modal sheets from a previous widget test
    // cannot leak into this scenario.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const CreativeGymApp());
    await tester.tap(find.byKey(const ValueKey('continue-button')));
    await tester.pumpAndSettle();
  }

  Future<void> chooseWorkout(WidgetTester tester, String title) async {
    final challengeId = switch (title) {
      'Утренний свет' => 'morning-light',
      'Тихое движение' => 'quiet-motion',
      'Вечерние контуры' => 'evening-shapes',
      _ => throw ArgumentError.value(title, 'title'),
    };
    var cardFinder = find.byKey(ValueKey('challenge-card-$challengeId'));
    if (challengeId == 'evening-shapes') {
      final completedButton = find.byKey(
        const ValueKey('completed-challenges-button'),
      );
      for (
        var attempt = 0;
        attempt < 8 && completedButton.evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -280));
        await tester.pumpAndSettle();
      }
      if (completedButton.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(
          completedButton,
          220,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(completedButton);
        await tester.pumpAndSettle();
        cardFinder = find.byKey(ValueKey('challenge-card-$challengeId'));
        for (
          var attempt = 0;
          attempt < 6 && cardFinder.evaluate().isEmpty;
          attempt++
        ) {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -280),
          );
          await tester.pumpAndSettle();
        }
      }
    } else {
      for (
        var attempt = 0;
        attempt < 8 && cardFinder.evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -220));
        await tester.pumpAndSettle();
      }
    }
    await tester.scrollUntilVisible(
      cardFinder,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(cardFinder);
    await tester.pumpAndSettle();
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();
  }

  testWidgets('login has one clear action', (tester) async {
    await tester.pumpWidget(const CreativeGymApp());

    expect(find.text('Creative Gym'), findsOneWidget);
    expect(find.text('Тренируй\nвзгляд.'), findsOneWidget);
    expect(
      find.text(
        'Выбери челлендж → сними один кадр → проголосуй → узнай результат.',
      ),
      findsOneWidget,
    );
    expect(find.text('Начать'), findsOneWidget);
    expect(find.textContaining('Google'), findsNothing);
    expect(find.textContaining('Yandex'), findsNothing);
  });

  testWidgets('login opens the minimalist challenge selection', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await openChallenges(tester);

    expect(find.text('Челленджи'), findsOneWidget);
    expect(find.byKey(const ValueKey('challenge-list')), findsOneWidget);
    expect(find.text('Утренний свет'), findsOneWidget);
    expect(find.text('Тихое движение'), findsOneWidget);
    expect(find.text('Осталось 3 дня'), findsOneWidget);
    expect(find.text('Сейчас'), findsOneWidget);
    expect(find.text('Другие челленджи'), findsOneWidget);
    expect(find.text('Работы собраны'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('challenge-action-quiet-motion')),
      findsOneWidget,
    );
    expect(find.text('Завершённые'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('challenge-card-evening-shapes')),
      findsNothing,
    );

    final votingCardTop = tester.getTopLeft(
      find.byKey(const ValueKey('challenge-card-quiet-motion')),
    );
    expect(votingCardTop.dy, greaterThan(64));
    final openCardTop = tester.getTopLeft(
      find.byKey(const ValueKey('challenge-card-morning-light')),
    );
    expect(openCardTop.dy, greaterThan(votingCardTop.dy));

    await tester.tap(find.byKey(const ValueKey('completed-challenges-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('challenge-card-evening-shapes')),
      findsOneWidget,
    );
    Navigator.of(
      tester.element(find.byKey(const ValueKey('completed-challenges-list'))),
    ).pop();
    await tester.pumpAndSettle();
  });

  testWidgets('main action opens the next step directly', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await openChallenges(tester);
    await tester.tap(
      find.byKey(const ValueKey('challenge-action-quiet-motion')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Какой кадр сильнее?'), findsOneWidget);
  });

  testWidgets('challenge card opens one focused assignment', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await openChallenges(tester);
    await chooseWorkout(tester, 'Тихое движение');

    expect(find.text('Задание недели'), findsNothing);
    expect(find.text('Челлендж'), findsNothing);
    expect(find.byKey(const ValueKey('current-workout-title')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('primary-workout-action')),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Работы собраны'), findsOneWidget);
    expect(find.text('Осталось 2 дн голосования'), findsOneWidget);
    expect(find.text('Голосовать'), findsOneWidget);
    expect(find.text('Weekly Workouts'), findsNothing);
    expect(find.text('Gym Room'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('challenge-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('continue-button')), findsNothing);
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
    expect(find.byKey(const ValueKey('profile-avatar-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('winners-toggle')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileWorkArtwork), findsNWidgets(5));

    await tester.tap(find.byKey(const ValueKey('profile-work-work-01')));
    await tester.pumpAndSettle();

    final viewerFinder = find.byKey(const ValueKey('profile-photo-viewer'));
    expect(viewerFinder, findsOneWidget);
    final zoomableWorkFinder = find.byKey(
      const ValueKey('zoomable-profile-work-work-01'),
    );
    expect(zoomableWorkFinder, findsOneWidget);
    final zoomableWork = tester.widget<InteractiveViewer>(zoomableWorkFinder);
    expect(zoomableWork.minScale, 1);
    expect(zoomableWork.maxScale, 5);
    final fullScreenArtwork = tester.widget<ProfileWorkArtwork>(
      find
          .descendant(
            of: zoomableWorkFinder,
            matching: find.byType(ProfileWorkArtwork),
          )
          .first,
    );
    expect(fullScreenArtwork.fit, BoxFit.contain);
    await tester.drag(viewerFinder, const Offset(-320, 0));
    await tester.pumpAndSettle();

    final viewer = tester.widget<PageView>(viewerFinder);
    expect(viewer.controller?.page, closeTo(1, 0.01));
  });

  testWidgets('admin code dialog closes without a disposed controller error', (
    tester,
  ) async {
    await openChallenges(tester);
    await tester.tap(find.byKey(const ValueKey('profile-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('admin-menu-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('admin-code-field')),
      'test-code',
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Режим автора'), findsNothing);
  });

  testWidgets('non-admin profile only offers the secret code entry', (
    tester,
  ) async {
    await openChallenges(tester);
    await tester.tap(find.byKey(const ValueKey('profile-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('test-account-switcher-button')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('admin-menu-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('admin-menu-button')));
    await tester.pumpAndSettle();

    expect(find.text('Режим автора'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-code-field')), findsOneWidget);
  });

  testWidgets('rules stay behind a secondary action', (tester) async {
    await openChallenges(tester);
    await chooseWorkout(tester, 'Утренний свет');

    await tester.tap(find.text('Условия'));
    await tester.pumpAndSettle();

    expect(find.text('Условия'), findsWidgets);
    expect(find.textContaining('• '), findsWidgets);
    expect(
      tester.getSize(find.byKey(const ValueKey('rules-sheet'))).width,
      tester.view.physicalSize.width / tester.view.devicePixelRatio,
    );
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
      find.text('Голосовать'),
      180,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Голосовать'));
    await tester.pumpAndSettle();

    expect(find.text('Какой кадр сильнее?'), findsOneWidget);
    expect(find.text('1 из 3'), findsOneWidget);
    expect(find.text('Пропустить'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('fullscreen-Frame A')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('vote-fullscreen-viewer')),
      findsOneWidget,
    );
    expect(find.text('1 из 2'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('vote-fullscreen-viewer')),
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 из 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close-vote-fullscreen')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('vote-Frame A')));
    await tester.pump();
    expect(find.text('Выбор сделан'), findsOneWidget);
    expect(find.text('1 из 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('submit-vote-button')));
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
    expect(find.byKey(const ValueKey('results-complete-check')), findsNothing);
    expect(find.text('Ваш кадр'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Посмотреть все работы'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Посмотреть все работы'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('results-finish-button')),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Ура!'), findsOneWidget);
    expect(find.text('Готово'), findsNothing);
    await tester.ensureVisible(find.text('Посмотреть все работы'));

    await tester.tap(find.text('Посмотреть все работы'));
    await tester.pumpAndSettle();
    expect(find.text('Скрыть работы'), findsOneWidget);
    expect(find.text('Ваш кадр'), findsWidgets);

    final firstResultPhoto = find.byKey(
      const ValueKey('open-result-photo-evening-shapes-top-1'),
    );
    await tester.scrollUntilVisible(
      firstResultPhoto,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(firstResultPhoto);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('result-photo-viewer')), findsOneWidget);
    expect(find.text('1 из 3'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('result-photo-viewer')),
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 из 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close-result-photo-viewer')));
    await tester.pumpAndSettle();

    final firstResultAuthor = find.byKey(
      const ValueKey('open-result-profile-evening-shapes-top-1'),
    );
    await tester.ensureVisible(firstResultAuthor);
    await tester.tap(firstResultAuthor);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profile-screen')), findsOneWidget);
    expect(find.text('Участник'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-menu-button')), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Итог'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('current-workout-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('continue-button')), findsNothing);
  });
}
