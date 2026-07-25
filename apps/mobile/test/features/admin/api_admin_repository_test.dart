import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:creative_gym_mobile/core/auth/auth_session_store.dart';
import 'package:creative_gym_mobile/core/config/app_config.dart';
import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/admin/data/api_admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('checks and unlocks admin access with the current session', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final requestsHandled = Completer<void>();
    var requestCount = 0;

    server.listen((request) async {
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer session-token',
      );

      if (request.method == 'GET') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'is_admin': false}));
      } else {
        final body = jsonDecode(await utf8.decoder.bind(request).join());
        expect(body, {'code': 'private-code'});
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'is_admin': true}));
      }
      await request.response.close();

      requestCount += 1;
      if (requestCount == 2 && !requestsHandled.isCompleted) {
        requestsHandled.complete();
      }
    });

    final sessions = MemoryAuthSessionStore();
    await sessions.writeToken('session-token');
    final repository = ApiAdminRepository(
      ApiClient(
        AppConfig(
          mode: DataSourceMode.api,
          apiBaseUrl: 'http://127.0.0.1:${server.port}',
        ),
        sessions,
      ),
    );

    expect(await repository.isAdmin(), isFalse);
    await repository.unlock('private-code');
    await requestsHandled.future;
  });
}
