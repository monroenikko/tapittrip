import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/features/auth/data/auth_repository.dart';
import 'package:tapittrip/features/auth/domain/models/auth_state.dart';
import 'package:tapittrip/features/auth/domain/models/auth_user.dart';
import 'package:tapittrip/features/auth/presentation/providers/auth_provider.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.shouldFail = false,
    this.failureMessage = 'Invalid credentials.',
  });

  bool shouldFail;
  String failureMessage;

  static const testUser = AuthUser(
    id: 'user-uuid-1',
    name: 'Traveler Tester',
    displayName: 'Traveler',
    email: 'traveler@tapittrip.local',
  );

  @override
  Future<({AuthUser user, String token})> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    if (shouldFail) {
      throw ApiException(code: 'invalid_credentials', message: failureMessage);
    }
    return (user: testUser, token: 'mock-bearer-token');
  }

  @override
  Future<({AuthUser user, String token})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? deviceName,
  }) async {
    if (shouldFail) {
      throw ApiException(code: 'validation_failed', message: failureMessage);
    }
    return (user: testUser, token: 'mock-bearer-token');
  }

  @override
  Future<AuthUser> getProfile() async {
    if (shouldFail) {
      throw const UnauthenticatedException();
    }
    return testUser;
  }

  @override
  Future<AuthUser> updateProfile({
    String? displayName,
    String? homeCountry,
    String? homeCurrency,
    String? homeTimezone,
    String? locale,
  }) async {
    if (shouldFail) {
      throw ApiException(code: 'update_failed', message: failureMessage);
    }
    return testUser.copyWith(
      displayName: displayName,
      homeCountry: homeCountry,
      homeCurrency: homeCurrency,
      homeTimezone: homeTimezone,
      locale: locale,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> deleteAccount() async {}
}

void main() {
  group('AuthNotifier and Flow', () {
    test(
      'initial state is Unauthenticated when token storage is empty',
      () async {
        final fakeTokenStorage = InMemoryTokenStorage();
        final container = ProviderContainer(
          overrides: [
            tokenStorageProvider.overrideWithValue(fakeTokenStorage),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ],
        );
        addTearDown(container.dispose);

        final state = container.read(authProvider);
        expect(state, isA<AuthState>());
        await Future<void>.delayed(Duration.zero);
        expect(container.read(authProvider), isA<Unauthenticated>());
      },
    );

    test('successful login updates state to Authenticated', () async {
      final fakeTokenStorage = InMemoryTokenStorage();
      final fakeRepo = FakeAuthRepository();

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeTokenStorage),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(authProvider.notifier)
          .login(
            email: 'traveler@tapittrip.local',
            password: 'secretPassword123!',
          );

      expect(success, isTrue);
      final state = container.read(authProvider);
      expect(state, isA<Authenticated>());
      final auth = state as Authenticated;
      expect(auth.user.email, 'traveler@tapittrip.local');
      expect(auth.token, 'mock-bearer-token');
    });

    test('failed login updates state to AuthFailure', () async {
      final fakeTokenStorage = InMemoryTokenStorage();
      final fakeRepo = FakeAuthRepository(shouldFail: true);

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeTokenStorage),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(authProvider.notifier)
          .login(email: 'traveler@tapittrip.local', password: 'wrongPassword');

      expect(success, isFalse);
      final state = container.read(authProvider);
      expect(state, isA<AuthFailure>());
      expect((state as AuthFailure).errorMessage, 'Invalid credentials.');
    });

    test('successful register updates state to Authenticated', () async {
      final fakeTokenStorage = InMemoryTokenStorage();
      final fakeRepo = FakeAuthRepository();

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeTokenStorage),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final success = await container
          .read(authProvider.notifier)
          .register(
            name: 'Traveler Tester',
            email: 'traveler@tapittrip.local',
            password: 'secretPassword123!',
            passwordConfirmation: 'secretPassword123!',
          );

      expect(success, isTrue);
      final state = container.read(authProvider);
      expect(state, isA<Authenticated>());
    });

    test('logout updates state to Unauthenticated', () async {
      final fakeTokenStorage = InMemoryTokenStorage('mock-token');
      final fakeRepo = FakeAuthRepository();

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeTokenStorage),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).logout();
      expect(container.read(authProvider), isA<Unauthenticated>());
    });
  });
}
