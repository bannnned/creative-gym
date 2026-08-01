import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:dio/dio.dart';

String userErrorMessage(Object? error) {
  if (error is DioException && error.error != null) {
    return userErrorMessage(error.error);
  }

  if (error is ApiException) {
    if (error.code == 'email_auth_unavailable') {
      return 'Вход по почте пока не настроен.';
    }
    if (error.code == 'yandex_auth_unavailable') {
      return 'Вход через Яндекс пока не настроен.';
    }
    if (error.code == 'passkey_unavailable') {
      return 'Ключи доступа пока не настроены.';
    }
    if (error.code == 'email_rate_limited') {
      return 'Письмо уже отправлено. Подождите минуту.';
    }
    if (error.code == 'identity_in_use') {
      return 'Этот способ входа связан с другим аккаунтом. Ваши текущие работы сохранены.';
    }
    if (error.code == 'verified_identity_required') {
      return 'Сначала подтвердите почту или подключите Яндекс ID.';
    }
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
