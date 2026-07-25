import 'package:creative_gym_mobile/features/voting/data/mock_vote_pairs.dart';
import 'package:creative_gym_mobile/features/voting/domain/vote_pair.dart';
import 'package:creative_gym_mobile/features/voting/domain/voting_repository.dart';

class MockVotingRepository implements VotingRepository {
  int _index = 0;

  @override
  Future<VotePair?> getNextPair(String roomId) async {
    if (_index >= mockVotePairs.length) {
      return null;
    }
    final pair = mockVotePairs[_index];
    return VotePair(
      id: pair.id,
      leftLabel: pair.leftLabel,
      rightLabel: pair.rightLabel,
      leftPalette: pair.leftPalette,
      rightPalette: pair.rightPalette,
      leftSubmissionId: '${pair.id}-left',
      rightSubmissionId: '${pair.id}-right',
      completed: _index,
      target: mockVotePairs.length,
    );
  }

  @override
  Future<void> castVote(
    String roomId,
    VotePair pair,
    String chosenSubmissionId,
  ) async {
    _index++;
  }

  @override
  Future<void> skip(String roomId, VotePair pair) async {
    _index++;
  }
}
