import 'dart:typed_data';

import 'package:creative_gym_mobile/features/media/domain/media_repository.dart';

class MockMediaRepository implements MediaRepository {
  const MockMediaRepository();

  @override
  Future<Uint8List> load(String mediaUrl) {
    throw UnsupportedError('Mock artwork has no remote media.');
  }
}
