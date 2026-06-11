import 'package:creative_gym_mobile/features/auth/presentation/login_screen.dart';
import 'package:creative_gym_mobile/features/challenges/presentation/challenge_details_screen.dart';
import 'package:creative_gym_mobile/features/challenges/presentation/weekly_workouts_screen.dart';
import 'package:creative_gym_mobile/features/results/presentation/results_screen.dart';
import 'package:creative_gym_mobile/features/rooms/presentation/gym_room_screen.dart';
import 'package:creative_gym_mobile/features/submissions/presentation/upload_submission_screen.dart';
import 'package:creative_gym_mobile/features/voting/presentation/voting_screen.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const challenges = '/challenges';
  static const challengeDetailsPath = '/challenges/:challengeId';
  static const roomPath = '/rooms/:roomId';
  static const roomUploadPath = '/rooms/:roomId/upload';
  static const roomVotePath = '/rooms/:roomId/vote';
  static const roomResultsPath = '/rooms/:roomId/results';

  static String challengeDetails(String challengeId) {
    return '/challenges/$challengeId';
  }

  static String room(String roomId) {
    return '/rooms/$roomId';
  }

  static String roomUpload(String roomId) {
    return '/rooms/$roomId/upload';
  }

  static String roomVote(String roomId, {bool demo = false}) {
    return demo ? '/rooms/$roomId/vote?demo=1' : '/rooms/$roomId/vote';
  }

  static String roomResults(String roomId, {bool demo = false}) {
    return demo ? '/rooms/$roomId/results?demo=1' : '/rooms/$roomId/results';
  }
}

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.challenges,
        builder: (context, state) => const WeeklyWorkoutsScreen(),
      ),
      GoRoute(
        path: AppRoutes.challengeDetailsPath,
        builder: (context, state) {
          final challengeId = state.pathParameters['challengeId'] ?? '';
          return ChallengeDetailsScreen(challengeId: challengeId);
        },
      ),
      GoRoute(
        path: AppRoutes.roomPath,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return GymRoomScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: AppRoutes.roomUploadPath,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return UploadSubmissionScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: AppRoutes.roomVotePath,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          final demoMode = state.uri.queryParameters['demo'] == '1';
          return VotingScreen(roomId: roomId, demoMode: demoMode);
        },
      ),
      GoRoute(
        path: AppRoutes.roomResultsPath,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          final demoMode = state.uri.queryParameters['demo'] == '1';
          return ResultsScreen(roomId: roomId, demoMode: demoMode);
        },
      ),
    ],
  );
}
