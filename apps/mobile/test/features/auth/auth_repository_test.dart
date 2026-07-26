import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:creative_gym_mobile/core/auth/auth_session_store.dart';
import 'package:creative_gym_mobile/core/config/app_config.dart';
import 'package:creative_gym_mobile/core/errors/api_exception.dart';
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

  test(
    'admin creates, switches, and removes a protected test account',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final handled = Completer<void>();
      var requestCount = 0;

      server.listen((request) async {
        requestCount++;
        expect(request.headers.value('Authorization'), 'Bearer admin-token');
        request.response.headers.contentType = ContentType.json;
        switch ('${request.method} ${request.uri.path}') {
          case 'GET /api/v1/admin/status':
            request.response.write(jsonEncode({'is_admin': true}));
          case 'GET /api/v1/auth/me':
            request.response.write(
              jsonEncode({
                'user': {'id': 'admin-user'},
              }),
            );
          case 'POST /api/v1/auth/guest':
            request.response
              ..statusCode = HttpStatus.created
              ..write(
                jsonEncode({
                  'token': 'test-session-token',
                  'user': {'id': 'test-user'},
                }),
              );
        }
        await request.response.close();
        if (requestCount == 3 && !handled.isCompleted) {
          handled.complete();
        }
      });

      final sessionStore = MemoryAuthSessionStore();
      await sessionStore.writeToken('admin-token');
      var sessionChanges = 0;
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
        onSessionChanged: () => sessionChanges++,
      );

      final created = await repository.createTestAccount();
      expect(created, hasLength(2));
      expect(
        created.singleWhere((account) => account.isAdmin).label,
        'Администратор',
      );
      expect(
        created.singleWhere((account) => account.isCurrent).userId,
        'test-user',
      );
      expect(await sessionStore.readToken(), 'test-session-token');
      expect(sessionChanges, 1);

      await repository.switchTestAccount('admin-user');
      expect(await sessionStore.readToken(), 'admin-token');
      expect(sessionChanges, 2);
      final remaining = await repository.removeTestAccount('test-user');
      expect(remaining, hasLength(1));
      expect(remaining.single.isAdmin, isTrue);
      await handled.future;
    },
  );

  test('non-admin cannot create a test account', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    server.listen((request) async {
      expect(request.uri.path, '/api/v1/admin/status');
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'is_admin': false}));
      await request.response.close();
    });

    final sessionStore = MemoryAuthSessionStore();
    await sessionStore.writeToken('regular-token');
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

    await expectLater(
      repository.createTestAccount(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'admin_required',
        ),
      ),
    );
  });

  test('admin cannot save more than eight test participants', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    server.listen((request) async {
      expect(request.uri.path, '/api/v1/admin/status');
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'is_admin': true}));
      await request.response.close();
    });

    final sessionStore = MemoryAuthSessionStore();
    await sessionStore.writeToken('admin-token');
    await sessionStore.writeTestAccounts([
      const StoredTestAccount(
        userId: 'admin-user',
        token: 'admin-token',
        label: 'Администратор',
        isAdmin: true,
      ),
      for (var index = 1; index <= 8; index++)
        StoredTestAccount(
          userId: 'test-user-$index',
          token: 'test-token-$index',
          label: 'Участник $index',
          isAdmin: false,
        ),
    ]);
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

    await expectLater(
      repository.createTestAccount(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'test_account_limit',
        ),
      ),
    );
  });
}
