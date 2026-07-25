import 'package:creative_gym_mobile/features/voting/domain/vote_pair.dart';

abstract interface class VotingRepository {
  Future<VotePair?> getNextPair(String roomId);

  Future<void> castVote(
    String roomId,
    VotePair pair,
    String chosenSubmissionId,
  );

  Future<void> skip(String roomId, VotePair pair);
}
