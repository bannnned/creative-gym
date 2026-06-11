class VotePair {
  const VotePair({
    required this.id,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftPalette,
    required this.rightPalette,
  });

  final String id;
  final String leftLabel;
  final String rightLabel;
  final VotePhotoPalette leftPalette;
  final VotePhotoPalette rightPalette;
}

class VotePhotoPalette {
  const VotePhotoPalette({
    required this.start,
    required this.middle,
    required this.end,
  });

  final int start;
  final int middle;
  final int end;
}
