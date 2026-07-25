import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:creative_gym_mobile/core/config/app_config.dart';
import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/submissions/data/api_submissions_repository.dart';
import 'package:creative_gym_mobile/features/submissions/data/mock_photo_data.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uploads multipart photo, reads media, and deletes submission',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      const devUserId = '00000000-0000-0000-0000-000000000001';
      final seenMethods = <String>[];
      final requestHandled = Completer<void>();
      var remainingRequests = 3;

      server.listen((request) async {
        seenMethods.add('${request.method} ${request.uri.path}');
        expect(request.headers.value('X-Dev-User-Id'), devUserId);

        if (request.method == 'POST') {
          expect(request.headers.contentType?.mimeType, 'multipart/form-data');
          final body = await request.fold<List<int>>(
            <int>[],
            (bytes, chunk) => bytes..addAll(chunk),
          );
          final multipartText = latin1.decode(body);
          expect(multipartText, contains('name="photo"'));
          expect(multipartText, contains('filename="photo.png"'));

          request.response
            ..statusCode = HttpStatus.created
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({
                'submission': {
                  'id': 'submission-1',
                  'room_id': 'room-1',
                  'media_url': '/api/v1/submissions/submission-1/media',
                  'content_type': 'image/png',
                  'byte_size': body.length,
                  'created_at': '2026-07-24T20:22:46Z',
                  'updated_at': '2026-07-24T20:22:46Z',
                },
              }),
            );
        } else if (request.method == 'GET') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType('image', 'png')
            ..add(mockPhotoBytes());
        } else if (request.method == 'DELETE') {
          request.response.statusCode = HttpStatus.noContent;
        }
        await request.response.close();

        remainingRequests -= 1;
        if (remainingRequests == 0 && !requestHandled.isCompleted) {
          requestHandled.complete();
        }
      });

      final client = ApiClient(
        AppConfig(
          mode: DataSourceMode.api,
          apiBaseUrl: 'http://127.0.0.1:${server.port}',
          devUserId: devUserId,
        ),
      );
      final repository = ApiSubmissionsRepository(client);
      final submission = await repository.upload(
        'room-1',
        SelectedPhoto(fileName: 'photo.png', bytes: mockPhotoBytes()),
      );

      expect(submission.id, 'submission-1');
      expect(await repository.loadMedia(submission), mockPhotoBytes());
      await repository.delete(submission.id);
      await requestHandled.future;

      expect(seenMethods, [
        'POST /api/v1/rooms/room-1/submissions',
        'GET /api/v1/submissions/submission-1/media',
        'DELETE /api/v1/submissions/submission-1',
      ]);
    },
  );
}
