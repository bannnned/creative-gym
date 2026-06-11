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
  final ResultSubmission currentUserSubmission;
  final List<ResultSubmission> rankedSubmissions;
}

class ResultSubmission {
  const ResultSubmission({
    required this.id,
    required this.rank,
    required this.title,
    required this.authorLabel,
    required this.wins,
    required this.comparisons,
    required this.paletteStart,
    required this.paletteEnd,
    this.isCurrentUser = false,
  });

  final String id;
  final int rank;
  final String title;
  final String authorLabel;
  final int wins;
  final int comparisons;
  final int paletteStart;
  final int paletteEnd;
  final bool isCurrentUser;

  String get scoreLabel => '$wins из $comparisons сравнений';
}
