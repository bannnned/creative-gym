import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:creative_gym_mobile/core/auth/auth_session_store.dart';
import 'package:creative_gym_mobile/core/config/app_config.dart';
import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates, stores, and restores a guest session', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    final requestsHandled = Completer<void>();
    var requestCount = 0;

    server.listen((request) async {
      requestCount += 1;

      if (request.method == 'POST' &&
          request.uri.path == '/api/v1/auth/guest') {
        expect(request.headers.value('Authorization'), isNull);
        request.response
          ..statusCode = HttpStatus.created
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'token': 'guest-session-token',
              'expires_at': '2026-10-23T12:00:00Z',
              'user': {
                'id': 'guest-user',
                'display_name': 'Участник',
                'is_guest': true,
              },
            }),
          );
      } else if (request.method == 'GET' &&
          request.uri.path == '/api/v1/auth/me') {
        expect(
          request.headers.value('Authorization'),
          'Bearer guest-session-token',
        );
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'user': {
                'id': 'guest-user',
                'display_name': 'Участник',
                'is_guest': true,
              },
            }),
          );
      }

      await request.response.close();
      if (requestCount == 2 && !requestsHandled.isCompleted) {
        requestsHandled.complete();
      }
    });

    final sessionStore = MemoryAuthSessionStore();
    final config = AppConfig(
      mode: DataSourceMode.api,
      apiBaseUrl: 'http://127.0.0.1:${server.port}',
    );
    final repository = AuthRepository(
      ApiClient(config, sessionStore),
      sessionStore,
      true,
    );

    await repository.signInAsGuest();
    expect(await sessionStore.readToken(), 'guest-session-token');
    expect(await repository.restoreSession(), isTrue);
    await requestsHandled.future;
  });

  test('starts a new guest without sending the previous session', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final handled = Completer<void>();

    server.listen((request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/v1/auth/guest');
      expect(request.headers.value('Authorization'), isNull);
      request.response
        ..statusCode = HttpStatus.created
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'token': 'new-session-token'}));
      await request.response.close();
      handled.complete();
    });

    final sessionStore = MemoryAuthSessionStore();
    await sessionStore.writeToken('old-session-token');
    final repository = AuthRepository(
      ApiClient(
        AppConfig(
          mode: DataSourceMode.api,
          apiBaseUrl: 'http://127.0.0.1:${server.port}',
        ),
        sessionStore,
      ),
      sessionStore,
      true,
    );

    await repository.startNewGuestSession();

    expect(await sessionStore.readToken(), 'new-session-token');
    await handled.future;
  });
}
