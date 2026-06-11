import 'package:creative_gym_mobile/features/voting/domain/vote_pair.dart';

const mockVotePairs = [
  VotePair(
    id: 'pair-1',
    leftLabel: 'Frame A',
    rightLabel: 'Frame B',
    leftPalette: VotePhotoPalette(
      start: 0xFFE8B96E,
      middle: 0xFF8ABBAA,
      end: 0xFF173F35,
    ),
    rightPalette: VotePhotoPalette(
      start: 0xFFAFCDF4,
      middle: 0xFF87A89B,
      end: 0xFF24334D,
    ),
  ),
  VotePair(
    id: 'pair-2',
    leftLabel: 'Frame C',
    rightLabel: 'Frame D',
    leftPalette: VotePhotoPalette(
      start: 0xFFE9B9A6,
      middle: 0xFFA9CEB0,
      end: 0xFF6E4654,
    ),
    rightPalette: VotePhotoPalette(
      start: 0xFFD6C4F2,
      middle: 0xFF8FB9B1,
      end: 0xFF314B47,
    ),
  ),
  VotePair(
    id: 'pair-3',
    leftLabel: 'Frame E',
    rightLabel: 'Frame F',
    leftPalette: VotePhotoPalette(
      start: 0xFFF2D08A,
      middle: 0xFFC28B73,
      end: 0xFF24493F,
    ),
    rightPalette: VotePhotoPalette(
      start: 0xFFB9D8EF,
      middle: 0xFF86A89D,
      end: 0xFF173F35,
    ),
  ),
];
