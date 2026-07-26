import 'dart:typed_data';

abstract interface class MediaRepository {
  Future<Uint8List> load(String mediaUrl);

  void prime(String mediaUrl, Uint8List bytes);

  void evict(String mediaUrl);

  void clear();
}
