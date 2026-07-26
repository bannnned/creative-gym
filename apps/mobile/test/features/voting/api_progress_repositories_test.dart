import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:creative_gym_mobile/core/config/app_config.dart';
import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/profile/data/api_profile_repository.dart';
import 'package:creative_gym_mobile/features/results/data/api_results_repository.dart';
import 'package:creative_gym_mobile/features/voting/data/api_voting_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps voting, results, and profile API responses', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final handled = Completer<void>();
    var count = 0;

    server.listen((request) async {
      count++;
      request.response.headers.contentType = ContentType.json;
      switch ('${request.method} ${request.uri.path}') {
        case 'GET /api/v1/rooms/room-1/votes/next-pair':
          request.response.write(
            jsonEncode({
              'pair': {
                'left': {
                  'id': 'left-id',
                  'media_url': '/api/v1/submissions/left-id/media',
                },
                'right': {
                  'id': 'right-id',
                  'media_url': '/api/v1/submissions/right-id/media',
                },
              },
              'progress': {'completed': 2, 'target': 10},
            }),
          );
        case 'POST /api/v1/rooms/room-1/votes':
          final body = jsonDecode(await utf8.decoder.bind(request).join());
          expect(body['chosen_submission_id'], 'left-id');
          request.response
            ..statusCode = HttpStatus.created
            ..write(jsonEncode({'completed': 3, 'target': 10}));
        case 'GET /api/v1/rooms/room-1/results':
          request.response.write(
            jsonEncode({
              'result': {
                'room_id': 'room-1',
                'participants_count': 4,
                'submissions_count': 2,
                'current_user_submission': {
                  'id': 'mine',
                  'author_user_id': 'current-user',
                  'rank': 2,
                  'title': 'Morning Light',
                  'author_label': 'Участник',
                  'wins': 7,
                  'comparisons': 10,
                  'media_url': '/api/v1/submissions/mine/media',
                  'is_current_user': true,
                },
                'ranked_submissions': <Map<String, dynamic>>[],
              },
            }),
          );
        case 'GET /api/v1/profile/me':
          request.response.write(
            jsonEncode({
              'profile': {
                'id': 'current-user',
                'display_name': 'Участник',
                'is_current_user': true,
                'points': 60,
                'first_places': 0,
                'second_places': 1,
                'third_places': 0,
                'works': [
                  {
                    'id': 'mine',
                    'title': 'Morning Light',
                    'media_url': '/api/v1/submissions/mine/media',
                    'place': 2,
                  },
                ],
              },
            }),
          );
        case 'GET /api/v1/profiles/author-user':
          request.response.write(
            jsonEncode({
              'profile': {
                'id': 'author-user',
                'display_name': 'Автор',
                'is_current_user': false,
                'points': 100,
                'first_places': 1,
                'second_places': 0,
                'third_places': 0,
                'works': <Map<String, dynamic>>[],
              },
            }),
          );
      }
      await request.response.close();
      if (count == 5 && !handled.isCompleted) {
        handled.complete();
      }
    });

    final client = ApiClient(
      AppConfig(
        mode: DataSourceMode.api,
        apiBaseUrl: 'http://127.0.0.1:${server.port}',
      ),
    );
    final voting = ApiVotingRepository(client);
    final pair = await voting.getNextPair('room-1');
    expect(pair?.completed, 2);
    expect(pair?.leftSubmissionId, 'left-id');
    await voting.castVote('room-1', pair!, pair.leftSubmissionId);

    final result = await ApiResultsRepository(client).getRoomResult('room-1');
    expect(result?.currentUserSubmission?.rank, 2);
    expect(result?.currentUserSubmission?.authorUserId, 'current-user');

    final profile = await ApiProfileRepository(client).getProfile();
    expect(profile.userId, 'current-user');
    expect(profile.isCurrentUser, isTrue);
    expect(profile.points, 60);
    expect(profile.works.single.place, 2);

    final publicProfile = await ApiProfileRepository(
      client,
    ).getProfile(userId: 'author-user');
    expect(publicProfile.displayName, 'Автор');
    expect(publicProfile.isCurrentUser, isFalse);
    await handled.future;
  });

  test('exposes results_pending as an API error the UI can handle', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    server.listen((request) async {
      request.response
        ..statusCode = HttpStatus.conflict
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'error': {
              'code': 'results_pending',
              'message': 'Results are not available yet.',
            },
          }),
        );
      await request.response.close();
    });

    final client = ApiClient(
      AppConfig(
        mode: DataSourceMode.api,
        apiBaseUrl: 'http://127.0.0.1:${server.port}',
      ),
    );

    await expectLater(
      ApiResultsRepository(client).getRoomResult('room-1'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'results_pending')
            .having((error) => error.statusCode, 'statusCode', 409),
      ),
    );
  });
}
