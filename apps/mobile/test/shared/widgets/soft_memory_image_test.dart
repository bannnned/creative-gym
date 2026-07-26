import 'dart:convert';

import 'package:creative_gym_mobile/shared/widgets/soft_memory_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps its placeholder while revealing a decoded image', (
    tester,
  ) async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0l'
      'EQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: SoftMemoryImage(
              bytes: bytes,
              placeholder: const ColoredBox(
                key: ValueKey('photo-placeholder'),
                color: Colors.grey,
              ),
              revealKey: 'image',
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('photo-placeholder')), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('photo-placeholder')), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
