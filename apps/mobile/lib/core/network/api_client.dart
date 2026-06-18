import 'package:creative_gym_mobile/core/config/app_config.dart';
import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient(AppConfig config)
    : _dio = Dio(
        BaseOptions(
          baseUrl: config.apiBaseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: const {'Content-Type': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-Dev-User-Id'] = config.devUserId;
          handler.next(options);
        },
        onError: (error, handler) {
          handler.reject(_mapError(error));
        },
      ),
    );
  }

  final Dio _dio;

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _dio.get<Map<String, dynamic>>(path);
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: body);
    return response.data ?? const {};
  }

  DioException _mapError(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final errorBody = data['error'];
      if (errorBody is Map<String, dynamic>) {
        return DioException(
          requestOptions: error.requestOptions,
          response: response,
          type: error.type,
          error: ApiException(
            code: errorBody['code'] as String?,
            message: errorBody['message'] as String? ?? 'Request failed.',
            statusCode: response?.statusCode,
          ),
        );
      }
    }

    return DioException(
      requestOptions: error.requestOptions,
      response: response,
      type: error.type,
      error: ApiException(
        message: error.message ?? 'Network request failed.',
        statusCode: response?.statusCode,
      ),
    );
  }
}
