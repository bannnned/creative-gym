import 'package:creative_gym_mobile/shared/widgets/onboarding_coach_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows and finishes a calm coach mark', (tester) async {
    final targetKey = GlobalKey();
    BuildContext? pageContext;
    var finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            pageContext = context;
            return Scaffold(
              body: Center(
                child: SizedBox(key: targetKey, width: 220, height: 120),
              ),
            );
          },
        ),
      ),
    );

    final tutorial = createOnboardingCoachMark(
      context: pageContext!,
      steps: [
        OnboardingCoachStep(
          id: 'test',
          targetKey: targetKey,
          title: 'Выбери челлендж',
          body: 'Одна короткая подсказка.',
        ),
      ],
      onFinish: () => finished = true,
      onSkip: () {},
    );
    tutorial.show(context: pageContext!, rootOverlay: true);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tutorial.isShowing, isTrue);
    expect(find.text('Пропустить'), findsOneWidget);

    tutorial.finish();
    await tester.pump();

    expect(finished, isTrue);
    expect(tutorial.isShowing, isFalse);
  });
}
