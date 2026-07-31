import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:creative_gym_mobile/core/config/app_config.dart';
import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/challenges/data/api_challenges_repository.dart';
import 'package:creative_gym_mobile/features/submissions/data/mock_photo_data.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads, caches, and replaces a private challenge cover', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    const devUserId = '00000000-0000-0000-0000-000000000001';
    final seenMethods = <String>[];
    final requestsHandled = Completer<void>();
    var remainingRequests = 3;

    server.listen((request) async {
      seenMethods.add('${request.method} ${request.uri.path}');
      expect(request.headers.value('X-Dev-User-Id'), devUserId);

      if (request.method == 'GET' &&
          request.uri.path == '/api/v1/challenges/active') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'challenges': [
                {
                  'id': 'challenge-1',
                  'kind': 'photo',
                  'title': 'Morning Light',
                  'theme': 'Light',
                  'description': 'Find the light.',
                  'rules': ['One photo.'],
                  'status': 'submitting',
                  'phase': 'submission',
                  'submission_starts_at': '2026-07-24T00:00:00Z',
                  'submission_ends_at': '2026-07-30T00:00:00Z',
                  'voting_starts_at': '2026-07-30T00:00:00Z',
                  'voting_ends_at': '2026-08-01T00:00:00Z',
                  'participant_count': 1,
                  'room_capacity': 16,
                  'viewer_room_id': null,
                  'viewer_has_joined': false,
                  'viewer_has_submission': false,
                  'viewer_has_voting_options': false,
                  'viewer_has_completed_voting': false,
                  'viewer_can_edit': true,
                  'cover_url': '/api/v1/challenges/challenge-1/cover?v=123',
                },
              ],
            }),
          );
      } else if (request.method == 'GET' &&
          request.uri.path == '/api/v1/challenges/challenge-1/cover') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType('image', 'png')
          ..add(mockPhotoBytes());
      } else if (request.method == 'PUT') {
        expect(request.headers.contentType?.mimeType, 'multipart/form-data');
        final body = await request.fold<List<int>>(
          <int>[],
          (bytes, chunk) => bytes..addAll(chunk),
        );
        final multipartText = latin1.decode(body);
        expect(multipartText, contains('name="cover"'));
        expect(multipartText, contains('filename="cover.png"'));

        request.response
          ..statusCode = HttpStatus.created
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'cover_url': '/api/v1/challenges/challenge-1/cover?v=456',
            }),
          );
      }
      await request.response.close();

      remainingRequests -= 1;
      if (remainingRequests == 0 && !requestsHandled.isCompleted) {
        requestsHandled.complete();
      }
    });

    final repository = ApiChallengesRepository(
      ApiClient(
        AppConfig(
          mode: DataSourceMode.api,
          apiBaseUrl: 'http://127.0.0.1:${server.port}',
          devUserId: devUserId,
        ),
      ),
    );

    final workout = (await repository.getActiveWorkouts()).single;
    expect(workout.viewerCanEdit, isTrue);

    expect(await repository.loadCover(workout), mockPhotoBytes());
    expect(await repository.loadCover(workout), mockPhotoBytes());

    await repository.uploadCover(
      workout.id,
      SelectedPhoto(fileName: 'cover.png', bytes: mockPhotoBytes()),
    );
    await requestsHandled.future;

    expect(seenMethods, [
      'GET /api/v1/challenges/active',
      'GET /api/v1/challenges/challenge-1/cover',
      'PUT /api/v1/challenges/challenge-1/cover',
    ]);
  });
}
