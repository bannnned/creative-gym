import 'package:animations/animations.dart';
import 'package:creative_gym_mobile/features/auth/presentation/login_screen.dart';
import 'package:creative_gym_mobile/features/admin/presentation/admin_challenges_screen.dart';
import 'package:creative_gym_mobile/features/challenges/presentation/weekly_workouts_screen.dart';
import 'package:creative_gym_mobile/features/challenges/presentation/challenge_selection_screen.dart';
import 'package:creative_gym_mobile/features/results/presentation/results_screen.dart';
import 'package:creative_gym_mobile/features/profile/presentation/profile_photo_viewer_screen.dart';
import 'package:creative_gym_mobile/features/profile/presentation/profile_screen.dart';
import 'package:creative_gym_mobile/features/profile/domain/profile_data.dart';
import 'package:creative_gym_mobile/features/submissions/presentation/upload_submission_screen.dart';
import 'package:creative_gym_mobile/features/voting/presentation/voting_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const challenges = '/challenges';
  static const challengeDetailsPath = '/challenges/:challengeId';
  static const profile = '/profile';
  static const publicProfilePath = '/profiles/:userId';
  static const adminChallenges = '/profile/admin/challenges';
  static const profileWorksPath = '/profile/works';
  static const roomPath = '/rooms/:roomId';
  static const roomUploadPath = '/rooms/:roomId/upload';
  static const roomVotePath = '/rooms/:roomId/vote';
  static const roomResultsPath = '/rooms/:roomId/results';

  static String challengeDetails(String challengeId) {
    return '/challenges/$challengeId';
  }

  static String publicProfile(String userId) {
    return '/profiles/$userId';
  }

  static String profileWorks(int index, {required bool winnersOnly}) {
    return '/profile/works?index=$index&winners=${winnersOnly ? 1 : 0}';
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
        pageBuilder: (context, state) => _appPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.challenges,
        pageBuilder: (context, state) =>
            _appPage(state, const ChallengeSelectionScreen()),
      ),
      GoRoute(
        path: AppRoutes.challengeDetailsPath,
        pageBuilder: (context, state) {
          final challengeId = state.pathParameters['challengeId'] ?? '';
          return _appPage(
            state,
            WeeklyWorkoutsScreen(challengeId: challengeId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) => _appPage(state, const ProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.publicProfilePath,
        pageBuilder: (context, state) => _appPage(
          state,
          ProfileScreen(userId: state.pathParameters['userId']),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminChallenges,
        pageBuilder: (context, state) =>
            _appPage(state, const AdminChallengesScreen()),
      ),
      GoRoute(
        path: AppRoutes.profileWorksPath,
        pageBuilder: (context, state) {
          final index =
              int.tryParse(state.uri.queryParameters['index'] ?? '') ?? 0;
          final winnersOnly = state.uri.queryParameters['winners'] == '1';
          return _appPage(
            state,
            ProfilePhotoViewerScreen(
              initialIndex: index,
              winnersOnly: winnersOnly,
              works: state.extra is List<ProfileWork>
                  ? state.extra! as List<ProfileWork>
                  : null,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.roomPath,
        redirect: (context, state) => AppRoutes.challenges,
      ),
      GoRoute(
        path: AppRoutes.roomUploadPath,
        pageBuilder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return _appPage(state, UploadSubmissionScreen(roomId: roomId));
        },
      ),
      GoRoute(
        path: AppRoutes.roomVotePath,
        pageBuilder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          final demoMode = state.uri.queryParameters['demo'] == '1';
          return _appPage(
            state,
            VotingScreen(roomId: roomId, demoMode: demoMode),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.roomResultsPath,
        pageBuilder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          final demoMode = state.uri.queryParameters['demo'] == '1';
          return _appPage(
            state,
            ResultsScreen(roomId: roomId, demoMode: demoMode),
          );
        },
      ),
    ],
  );
}

CustomTransitionPage<void> _appPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return child;
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SharedAxisTransition(
        animation: curved,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.horizontal,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      );
    },
  );
}
