import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:dio/dio.dart';

String userErrorMessage(Object? error) {
  if (error is DioException && error.error != null) {
    return userErrorMessage(error.error);
  }

  if (error is ApiException) {
    if (error.code == 'results_pending') {
      return 'Итоги появятся после завершения голосования.';
    }
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Нужно войти в приложение ещё раз.';
    }
    if (error.statusCode == 404) {
      return 'Эти данные больше недоступны.';
    }
  }

  final technicalMessage = error.toString().toLowerCase();
  if (technicalMessage.contains('timeout') ||
      technicalMessage.contains('connection') ||
      technicalMessage.contains('socket') ||
      technicalMessage.contains('network')) {
    return 'Проверьте интернет и попробуйте ещё раз.';
  }

  return 'Попробуйте ещё раз через несколько секунд.';
}
