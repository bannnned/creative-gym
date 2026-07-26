import 'package:creative_gym_mobile/core/auth/auth_session_store.dart';
import 'package:creative_gym_mobile/core/config/app_config.dart';
import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/admin/data/api_admin_repository.dart';
import 'package:creative_gym_mobile/features/admin/data/disabled_admin_repository.dart';
import 'package:creative_gym_mobile/features/admin/domain/admin_repository.dart';
import 'package:creative_gym_mobile/features/auth/data/auth_repository.dart';
import 'package:creative_gym_mobile/features/challenges/data/api_challenges_repository.dart';
import 'package:creative_gym_mobile/features/challenges/data/fallback_challenges_repository.dart';
import 'package:creative_gym_mobile/features/challenges/data/mock_challenges_repository.dart';
import 'package:creative_gym_mobile/features/challenges/domain/challenges_repository.dart';
import 'package:creative_gym_mobile/features/media/data/api_media_repository.dart';
import 'package:creative_gym_mobile/features/media/data/mock_media_repository.dart';
import 'package:creative_gym_mobile/features/media/domain/media_repository.dart';
import 'package:creative_gym_mobile/features/profile/data/api_profile_repository.dart';
import 'package:creative_gym_mobile/features/profile/data/mock_profile_repository.dart';
import 'package:creative_gym_mobile/features/profile/domain/profile_repository.dart';
import 'package:creative_gym_mobile/features/results/data/api_results_repository.dart';
import 'package:creative_gym_mobile/features/results/data/mock_results_repository.dart';
import 'package:creative_gym_mobile/features/results/domain/results_repository.dart';
import 'package:creative_gym_mobile/features/rooms/data/api_rooms_repository.dart';
import 'package:creative_gym_mobile/features/rooms/data/fallback_rooms_repository.dart';
import 'package:creative_gym_mobile/features/rooms/data/mock_rooms_repository.dart';
import 'package:creative_gym_mobile/features/rooms/domain/rooms_repository.dart';
import 'package:creative_gym_mobile/features/submissions/data/api_submissions_repository.dart';
import 'package:creative_gym_mobile/features/submissions/data/image_picker_photo_picker.dart';
import 'package:creative_gym_mobile/features/submissions/data/mock_photo_picker.dart';
import 'package:creative_gym_mobile/features/submissions/data/mock_submissions_repository.dart';
import 'package:creative_gym_mobile/features/submissions/domain/photo_picker.dart';
import 'package:creative_gym_mobile/features/submissions/domain/submissions_repository.dart';
import 'package:creative_gym_mobile/features/voting/data/api_voting_repository.dart';
import 'package:creative_gym_mobile/features/voting/data/mock_voting_repository.dart';
import 'package:creative_gym_mobile/features/voting/domain/voting_repository.dart';

late AppDependencies appDependencies;

void bootstrapApp({AppConfig? config}) {
  appDependencies = AppDependencies.create(config: config);
}

class AppDependencies {
  AppDependencies({
    required this.config,
    required this.auth,
    required this.admin,
    required this.challenges,
    required this.rooms,
    required this.submissions,
    required this.photoPicker,
    required this.voting,
    required this.results,
    required this.profile,
    required this.media,
  });

  final AppConfig config;
  final AuthRepository auth;
  final AdminRepository admin;
  final ChallengesRepository challenges;
  final RoomsRepository rooms;
  final SubmissionsRepository submissions;
  final PhotoPicker photoPicker;
  final VotingRepository voting;
  final ResultsRepository results;
  final ProfileRepository profile;
  final MediaRepository media;

  factory AppDependencies.create({AppConfig? config}) {
    final resolvedConfig = config ?? AppConfig.fromEnvironment();
    final sessionStore = switch (resolvedConfig.mode) {
      DataSourceMode.mock => MemoryAuthSessionStore(),
      DataSourceMode.api ||
      DataSourceMode.apiWithMockFallback => SecureAuthSessionStore(),
    };
    final apiClient = ApiClient(resolvedConfig, sessionStore);
    final apiMedia = ApiMediaRepository(apiClient);
    final auth = AuthRepository(
      apiClient,
      sessionStore,
      resolvedConfig.mode != DataSourceMode.mock,
      onSessionChanged: apiMedia.clear,
    );
    final admin = switch (resolvedConfig.mode) {
      DataSourceMode.mock => const DisabledAdminRepository(),
      DataSourceMode.api ||
      DataSourceMode.apiWithMockFallback => ApiAdminRepository(apiClient),
    };
    final mockChallenges = const MockChallengesRepository();
    final apiChallenges = ApiChallengesRepository(apiClient);
    final mockRooms = const MockRoomsRepository();
    final apiRooms = ApiRoomsRepository(apiClient);
    final mockSubmissions = MockSubmissionsRepository();
    final apiSubmissions = ApiSubmissionsRepository(apiClient, apiMedia);
    final mockVoting = MockVotingRepository();
    final apiVoting = ApiVotingRepository(apiClient);
    const mockResults = MockResultsRepository();
    final apiResults = ApiResultsRepository(apiClient);
    const mockProfile = MockProfileRepository();
    final apiProfile = ApiProfileRepository(apiClient);

    final challenges = switch (resolvedConfig.mode) {
      DataSourceMode.mock => mockChallenges,
      DataSourceMode.api => apiChallenges,
      DataSourceMode.apiWithMockFallback => FallbackChallengesRepository(
        api: apiChallenges,
        mock: mockChallenges,
      ),
    };

    final rooms = switch (resolvedConfig.mode) {
      DataSourceMode.mock => mockRooms,
      DataSourceMode.api => apiRooms,
      DataSourceMode.apiWithMockFallback => FallbackRoomsRepository(
        api: apiRooms,
        mock: mockRooms,
      ),
    };

    final submissions = switch (resolvedConfig.mode) {
      DataSourceMode.mock => mockSubmissions,
      DataSourceMode.api ||
      DataSourceMode.apiWithMockFallback => apiSubmissions,
    };

    final photoPicker = switch (resolvedConfig.mode) {
      DataSourceMode.mock => const MockPhotoPicker(),
      DataSourceMode.api ||
      DataSourceMode.apiWithMockFallback => ImagePickerPhotoPicker(),
    };

    final voting = switch (resolvedConfig.mode) {
      DataSourceMode.mock => mockVoting,
      DataSourceMode.api || DataSourceMode.apiWithMockFallback => apiVoting,
    };
    final results = switch (resolvedConfig.mode) {
      DataSourceMode.mock => mockResults,
      DataSourceMode.api || DataSourceMode.apiWithMockFallback => apiResults,
    };
    final profile = switch (resolvedConfig.mode) {
      DataSourceMode.mock => mockProfile,
      DataSourceMode.api || DataSourceMode.apiWithMockFallback => apiProfile,
    };
    final media = switch (resolvedConfig.mode) {
      DataSourceMode.mock => const MockMediaRepository(),
      DataSourceMode.api || DataSourceMode.apiWithMockFallback => apiMedia,
    };

    return AppDependencies(
      config: resolvedConfig,
      auth: auth,
      admin: admin,
      challenges: challenges,
      rooms: rooms,
      submissions: submissions,
      photoPicker: photoPicker,
      voting: voting,
      results: results,
      profile: profile,
      media: media,
    );
  }
}
