import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:creative_gym_mobile/core/errors/user_error_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hides technical connection details', () {
    final message = userErrorMessage(
      const ApiException(message: 'Connection timeout after 8000ms'),
    );

    expect(message, 'Проверьте интернет и попробуйте ещё раз.');
    expect(message, isNot(contains('8000')));
    expect(message, isNot(contains('ApiException')));
  });

  test('explains expired authentication without technical terms', () {
    final message = userErrorMessage(
      const ApiException(message: 'forbidden', statusCode: 403),
    );

    expect(message, 'Нужно войти в приложение ещё раз.');
  });
}
