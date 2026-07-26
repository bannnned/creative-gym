class RoomResult {
  const RoomResult({
    required this.roomId,
    required this.participantsCount,
    required this.submissionsCount,
    required this.completionLabel,
    required this.encouragementLabel,
    required this.currentUserSubmission,
    required this.rankedSubmissions,
  });

  final String roomId;
  final int participantsCount;
  final int submissionsCount;
  final String completionLabel;
  final String encouragementLabel;
  final ResultSubmission? currentUserSubmission;
  final List<ResultSubmission> rankedSubmissions;

  String get outcomeActionLabel =>
      currentUserSubmission?.isPrizeWinner == true ? 'Ура!' : 'Ну штош';
}

class ResultSubmission {
  const ResultSubmission({
    required this.id,
    required this.rank,
    required this.title,
    required this.authorLabel,
    this.authorUserId = '',
    required this.wins,
    required this.comparisons,
    required this.paletteStart,
    required this.paletteEnd,
    this.mediaUrl = '',
    this.isCurrentUser = false,
  });

  final String id;
  final int rank;
  final String title;
  final String authorLabel;
  final String authorUserId;
  final int wins;
  final int comparisons;
  final int paletteStart;
  final int paletteEnd;
  final String mediaUrl;
  final bool isCurrentUser;

  bool get isPrizeWinner => rank >= 1 && rank <= 3;
  String get scoreLabel => '$wins из $comparisons сравнений';
}
