class ProfileData {
  const ProfileData({
    this.userId = '',
    this.displayName = 'Участник',
    this.avatarUrl = '',
    this.isCurrentUser = true,
    this.emailVerified = true,
    this.pendingPrizePoints = 0,
    required this.points,
    required this.firstPlaces,
    required this.secondPlaces,
    required this.thirdPlaces,
    required this.works,
  });

  final String userId;
  final String displayName;
  final String avatarUrl;
  final bool isCurrentUser;
  final bool emailVerified;
  final int pendingPrizePoints;
  final int points;
  final int firstPlaces;
  final int secondPlaces;
  final int thirdPlaces;
  final List<ProfileWork> works;
}

class ProfileWork {
  const ProfileWork({
    required this.id,
    required this.title,
    required this.paletteStart,
    required this.paletteEnd,
    required this.composition,
    this.mediaUrl = '',
    this.place,
  });

  final String id;
  final String title;
  final int paletteStart;
  final int paletteEnd;
  final int composition;
  final String mediaUrl;
  final int? place;

  bool get isWinner => place != null && place! >= 1 && place! <= 3;
}
