import 'package:creative_gym_mobile/core/config/app_config.dart';
import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/challenges/data/api_challenges_repository.dart';
import 'package:creative_gym_mobile/features/challenges/data/fallback_challenges_repository.dart';
import 'package:creative_gym_mobile/features/challenges/data/mock_challenges_repository.dart';
import 'package:creative_gym_mobile/features/challenges/domain/challenges_repository.dart';
import 'package:creative_gym_mobile/features/rooms/data/api_rooms_repository.dart';
import 'package:creative_gym_mobile/features/rooms/data/fallback_rooms_repository.dart';
import 'package:creative_gym_mobile/features/rooms/data/mock_rooms_repository.dart';
import 'package:creative_gym_mobile/features/rooms/domain/rooms_repository.dart';

late AppDependencies appDependencies;

void bootstrapApp({AppConfig? config}) {
  appDependencies = AppDependencies.create(config: config);
}

class AppDependencies {
  AppDependencies({
    required this.config,
    required this.challenges,
    required this.rooms,
  });

  final AppConfig config;
  final ChallengesRepository challenges;
  final RoomsRepository rooms;

  factory AppDependencies.create({AppConfig? config}) {
    final resolvedConfig = config ?? AppConfig.fromEnvironment();
    final apiClient = ApiClient(resolvedConfig);
    final mockChallenges = const MockChallengesRepository();
    final apiChallenges = ApiChallengesRepository(apiClient);
    final mockRooms = const MockRoomsRepository();
    final apiRooms = ApiRoomsRepository(apiClient);

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

    return AppDependencies(
      config: resolvedConfig,
      challenges: challenges,
      rooms: rooms,
    );
  }
}
