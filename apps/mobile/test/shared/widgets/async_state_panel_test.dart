import 'package:creative_gym_mobile/shared/widgets/async_state_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders every skeleton layout without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final layout in AsyncLoadingLayout.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AsyncLoadingPanel(layout: layout)),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(ValueKey('loading-skeleton-${layout.name}')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
