import 'dart:collection';
import 'dart:typed_data';

import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/media/domain/media_repository.dart';

class ApiMediaRepository implements MediaRepository {
  ApiMediaRepository(this._client, {this.maxCacheBytes = 32 * 1024 * 1024});

  final ApiClient _client;
  final int maxCacheBytes;
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();
  final Map<String, Future<Uint8List>> _inFlight = {};
  int _cacheBytes = 0;
  int _generation = 0;

  @override
  Future<Uint8List> load(String mediaUrl) {
    final cached = _cache.remove(mediaUrl);
    if (cached != null) {
      _cache[mediaUrl] = cached;
      return Future.value(cached);
    }

    final generation = _generation;
    final flightKey = '$generation:$mediaUrl';
    final pending = _inFlight[flightKey];
    if (pending != null) {
      return pending;
    }

    final request = _loadAndCache(mediaUrl, generation, flightKey);
    _inFlight[flightKey] = request;
    return request;
  }

  Future<Uint8List> _loadAndCache(
    String mediaUrl,
    int generation,
    String flightKey,
  ) async {
    try {
      final bytes = await _client.getBytes(mediaUrl);
      if (generation == _generation) {
        prime(mediaUrl, bytes);
      }
      return bytes;
    } finally {
      _inFlight.remove(flightKey);
    }
  }

  @override
  void prime(String mediaUrl, Uint8List bytes) {
    if (mediaUrl.isEmpty || bytes.isEmpty || bytes.length > maxCacheBytes) {
      return;
    }

    final previous = _cache.remove(mediaUrl);
    if (previous != null) {
      _cacheBytes -= previous.length;
    }
    _cache[mediaUrl] = bytes;
    _cacheBytes += bytes.length;

    while (_cacheBytes > maxCacheBytes && _cache.isNotEmpty) {
      final oldestKey = _cache.keys.first;
      final removed = _cache.remove(oldestKey);
      if (removed != null) {
        _cacheBytes -= removed.length;
      }
    }
  }

  @override
  void evict(String mediaUrl) {
    final removed = _cache.remove(mediaUrl);
    if (removed != null) {
      _cacheBytes -= removed.length;
    }
  }

  @override
  void clear() {
    _generation++;
    _cache.clear();
    _inFlight.clear();
    _cacheBytes = 0;
  }
}
