class Submission {
  const Submission({
    required this.id,
    required this.roomId,
    required this.mediaUrl,
    required this.contentType,
    required this.byteSize,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String roomId;
  final String mediaUrl;
  final String contentType;
  final int byteSize;
  final DateTime createdAt;
  final DateTime updatedAt;
}
