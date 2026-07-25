class VotePair {
  const VotePair({
    required this.id,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftPalette,
    required this.rightPalette,
    this.leftSubmissionId = '',
    this.rightSubmissionId = '',
    this.leftMediaUrl = '',
    this.rightMediaUrl = '',
    this.completed = 0,
    this.target = 0,
  });

  final String id;
  final String leftLabel;
  final String rightLabel;
  final VotePhotoPalette leftPalette;
  final VotePhotoPalette rightPalette;
  final String leftSubmissionId;
  final String rightSubmissionId;
  final String leftMediaUrl;
  final String rightMediaUrl;
  final int completed;
  final int target;
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
