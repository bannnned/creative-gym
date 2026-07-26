import 'dart:convert';
import 'dart:io';

import 'package:creative_gym_mobile/core/config/app_config.dart';
import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/media/data/api_media_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'deduplicates requests and keeps private media in a bounded cache',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var requests = 0;

      server.listen((request) async {
        requests++;
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType('image', 'jpeg')
          ..add(utf8.encode('photo-$requests'));
        await request.response.close();
      });

      final client = ApiClient(
        AppConfig(
          mode: DataSourceMode.api,
          apiBaseUrl: 'http://127.0.0.1:${server.port}',
        ),
      );
      final repository = ApiMediaRepository(client);

      final firstLoads = await Future.wait([
        repository.load('/photo'),
        repository.load('/photo'),
      ]);
      expect(utf8.decode(firstLoads.first), 'photo-1');
      expect(firstLoads.last, firstLoads.first);
      expect(await repository.load('/photo'), firstLoads.first);
      expect(requests, 1);

      repository.evict('/photo');
      expect(utf8.decode(await repository.load('/photo')), 'photo-2');
      expect(requests, 2);

      repository.clear();
      expect(utf8.decode(await repository.load('/photo')), 'photo-3');
      expect(requests, 3);
    },
  );
}
