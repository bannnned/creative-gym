import 'dart:typed_data';

abstract interface class MediaRepository {
  Future<Uint8List> load(String mediaUrl);
}
