import 'dart:typed_data';

import 'package:creative_gym_mobile/features/media/domain/media_repository.dart';

class MockMediaRepository implements MediaRepository {
  const MockMediaRepository();

  @override
  void clear() {}

  @override
  void evict(String mediaUrl) {}

  @override
  Future<Uint8List> load(String mediaUrl) {
    throw UnsupportedError('Mock artwork has no remote media.');
  }

  @override
  void prime(String mediaUrl, Uint8List bytes) {}
}
