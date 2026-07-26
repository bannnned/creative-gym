import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OnboardingProgress {
  const OnboardingProgress({
    required this.selectionSeen,
    required this.detailsSeen,
    required this.dismissed,
  });

  const OnboardingProgress.initial()
    : selectionSeen = false,
      detailsSeen = false,
      dismissed = false;

  const OnboardingProgress.disabled()
    : selectionSeen = true,
      detailsSeen = true,
      dismissed = true;

  final bool selectionSeen;
  final bool detailsSeen;
  final bool dismissed;

  bool get isEnabled => !dismissed && (!selectionSeen || !detailsSeen);

  Map<String, dynamic> toJson() => {
    'version': OnboardingRepository.currentVersion,
    'selection_seen': selectionSeen,
    'details_seen': detailsSeen,
    'dismissed': dismissed,
  };

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    if (json['version'] != OnboardingRepository.currentVersion) {
      return const OnboardingProgress.initial();
    }
    return OnboardingProgress(
      selectionSeen: json['selection_seen'] == true,
      detailsSeen: json['details_seen'] == true,
      dismissed: json['dismissed'] == true,
    );
  }

  OnboardingProgress copyWith({
    bool? selectionSeen,
    bool? detailsSeen,
    bool? dismissed,
  }) {
    return OnboardingProgress(
      selectionSeen: selectionSeen ?? this.selectionSeen,
      detailsSeen: detailsSeen ?? this.detailsSeen,
      dismissed: dismissed ?? this.dismissed,
    );
  }
}

abstract interface class OnboardingStateStore {
  Future<String?> read();

  Future<void> write(String value);
}

class SecureOnboardingStateStore implements OnboardingStateStore {
  SecureOnboardingStateStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'creative_gym_onboarding';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
}

class MemoryOnboardingStateStore implements OnboardingStateStore {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async {
    _value = value;
  }
}

class OnboardingRepository {
  OnboardingRepository(this._store, {this.enabledByDefault = true});

  // Version 1 could be stored before the list target became available.
  // Reset it once so every existing installation receives the fixed tour.
  static const currentVersion = 2;

  final OnboardingStateStore _store;
  final bool enabledByDefault;
  OnboardingProgress? _cached;

  Future<OnboardingProgress> load() async {
    final cached = _cached;
    if (cached != null) {
      return cached;
    }

    final encoded = await _store.read();
    if (encoded == null || encoded.isEmpty) {
      final initial = enabledByDefault
          ? const OnboardingProgress.initial()
          : const OnboardingProgress.disabled();
      _cached = initial;
      return initial;
    }

    try {
      final json = jsonDecode(encoded);
      final progress = json is Map<String, dynamic>
          ? OnboardingProgress.fromJson(json)
          : const OnboardingProgress.initial();
      _cached = progress;
      return progress;
    } on FormatException {
      const progress = OnboardingProgress.initial();
      _cached = progress;
      return progress;
    }
  }

  Future<bool> shouldShowSelection() async {
    final progress = await load();
    return !progress.dismissed && !progress.selectionSeen;
  }

  Future<bool> shouldShowDetails() async {
    final progress = await load();
    return !progress.dismissed &&
        progress.selectionSeen &&
        !progress.detailsSeen;
  }

  Future<bool> isEnabled() async => (await load()).isEnabled;

  Future<void> markSelectionSeen() async {
    final progress = await load();
    await _save(progress.copyWith(selectionSeen: true));
  }

  Future<void> completeDetails() async {
    final progress = await load();
    await _save(
      progress.copyWith(
        selectionSeen: true,
        detailsSeen: true,
        dismissed: false,
      ),
    );
  }

  Future<void> skip() async {
    await _save(const OnboardingProgress.disabled());
  }

  Future<void> setEnabled(bool enabled) async {
    await _save(
      enabled
          ? const OnboardingProgress.initial()
          : const OnboardingProgress.disabled(),
    );
  }

  Future<void> _save(OnboardingProgress progress) async {
    _cached = progress;
    await _store.write(jsonEncode(progress.toJson()));
  }
}
