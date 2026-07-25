import 'dart:typed_data';

import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/media/domain/media_repository.dart';

class ApiMediaRepository implements MediaRepository {
  const ApiMediaRepository(this._client);

  final ApiClient _client;

  @override
  Future<Uint8List> load(String mediaUrl) => _client.getBytes(mediaUrl);
}
