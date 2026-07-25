class ProfileData {
  const ProfileData({
    required this.points,
    required this.firstPlaces,
    required this.secondPlaces,
    required this.thirdPlaces,
    required this.works,
  });

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
