class WeeklyWorkout {
  const WeeklyWorkout({
    required this.id,
    required this.title,
    required this.theme,
    required this.description,
    required this.phase,
    required this.submissionDeadlineLabel,
    required this.submissionWindowLabel,
    required this.votingWindowLabel,
    required this.participantsLabel,
    required this.roomSizeLabel,
    required this.roomId,
    required this.rules,
    required this.isJoined,
  });

  final String id;
  final String title;
  final String theme;
  final String description;
  final String phase;
  final String submissionDeadlineLabel;
  final String submissionWindowLabel;
  final String votingWindowLabel;
  final String participantsLabel;
  final String roomSizeLabel;
  final String roomId;
  final List<String> rules;
  final bool isJoined;
}
