import 'package:creative_gym_mobile/features/onboarding/data/onboarding_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededOnboardingStore implements OnboardingStateStore {
  _SeededOnboardingStore(this.value);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

void main() {
  test('tracks, completes, resets, and skips the lightweight tour', () async {
    final repository = OnboardingRepository(MemoryOnboardingStateStore());

    expect(await repository.shouldShowSelection(), isTrue);
    expect(await repository.shouldShowDetails(), isFalse);
    expect(await repository.isEnabled(), isTrue);

    await repository.markSelectionSeen();
    expect(await repository.shouldShowSelection(), isFalse);
    expect(await repository.shouldShowDetails(), isTrue);

    await repository.completeDetails();
    expect(await repository.shouldShowDetails(), isFalse);
    expect(await repository.isEnabled(), isFalse);

    await repository.setEnabled(true);
    expect(await repository.shouldShowSelection(), isTrue);
    expect(await repository.shouldShowDetails(), isFalse);

    await repository.skip();
    expect(await repository.shouldShowSelection(), isFalse);
    expect(await repository.shouldShowDetails(), isFalse);
  });

  test('can start disabled in mock and test environments', () async {
    final repository = OnboardingRepository(
      MemoryOnboardingStateStore(),
      enabledByDefault: false,
    );

    expect(await repository.isEnabled(), isFalse);
  });

  test('preserves the list-to-details step order', () async {
    final repository = OnboardingRepository(MemoryOnboardingStateStore());

    expect(await repository.shouldShowSelection(), isTrue);
    expect(await repository.shouldShowDetails(), isFalse);

    await repository.markSelectionSeen();

    expect(await repository.shouldShowSelection(), isFalse);
    expect(await repository.shouldShowDetails(), isTrue);
    expect(await repository.isEnabled(), isTrue);

    await repository.completeDetails();

    expect(await repository.shouldShowSelection(), isFalse);
    expect(await repository.shouldShowDetails(), isFalse);
    expect(await repository.isEnabled(), isFalse);
  });

  test('restarts a tour saved by an older onboarding version', () async {
    final repository = OnboardingRepository(
      _SeededOnboardingStore(
        '{"version":1,"selection_seen":true,'
        '"details_seen":true,"dismissed":false}',
      ),
    );

    expect(await repository.shouldShowSelection(), isTrue);
    expect(await repository.shouldShowDetails(), isFalse);
  });
}
