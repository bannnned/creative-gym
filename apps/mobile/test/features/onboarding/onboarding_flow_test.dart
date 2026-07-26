import 'package:creative_gym_mobile/app/creative_gym_app.dart';
import 'package:creative_gym_mobile/core/app_dependencies.dart';
import 'package:creative_gym_mobile/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('first visit softly points at an active challenge', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    bootstrapApp(config: const AppConfig(mode: DataSourceMode.mock));
    await appDependencies.onboarding.setEnabled(true);

    await tester.pumpWidget(const CreativeGymApp());
    await tester.tap(find.byKey(const ValueKey('continue-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('Пропустить'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('challenge-card-morning-light')),
      findsOneWidget,
    );

    await tester.tap(find.text('Пропустить'));
    await tester.pumpAndSettle();
    expect(await appDependencies.onboarding.isEnabled(), isFalse);
  });
}
