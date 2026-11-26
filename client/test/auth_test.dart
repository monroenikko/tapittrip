import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/auth/data/auth_repository.dart';
import 'package:tapittrip/features/auth/data/social_auth_service.dart';
import 'package:tapittrip/features/auth/domain/models/auth_state.dart';
import 'package:tapittrip/features/auth/domain/models/auth_user.dart';
import 'package:tapittrip/features/auth/presentation/pages/login_page.dart';
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
    friendCode: 'TRP-TEST01',
    acceptsDirectInvites: true,
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
  Future<({AuthUser user, String token, bool isNewUser})> exchangeOAuthToken({
    required String provider,
    required String idToken,
    String? deviceName,
    String? displayName,
    String? locale,
    String? homeTimezone,
  }) async {
    if (shouldFail) {
      throw ApiException(code: 'invalid_credentials', message: failureMessage);
    }
    return (user: testUser, token: 'mock-oauth-token', isNewUser: false);
  }

  @override
  Future<({AuthUser user, String token})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? deviceName,
    String? permanentAddress,
    String? homeCountry,
    String? homeCurrency,
  }) async {
    if (shouldFail) {
      throw ApiException(code: 'validation_failed', message: failureMessage);
    }
    return (
      user: testUser.copyWith(
        permanentAddress: permanentAddress,
        homeCountry: homeCountry,
        homeCurrency: homeCurrency,
      ),
      token: 'mock-bearer-token',
    );
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
    String? permanentAddress,
    String? homeCountry,
    String? homeCurrency,
    String? homeTimezone,
    String? locale,
    bool? acceptsDirectInvites,
  }) async {
    if (shouldFail) {
      throw ApiException(code: 'update_failed', message: failureMessage);
    }
    return testUser.copyWith(
      displayName: displayName,
      permanentAddress: permanentAddress,
      homeCountry: homeCountry,
      homeCurrency: homeCurrency,
      homeTimezone: homeTimezone,
      locale: locale,
      acceptsDirectInvites: acceptsDirectInvites,
    );
  }

  @override
  Future<AuthUser> regenerateFriendCode() async {
    if (shouldFail) {
      throw ApiException(code: 'failed', message: failureMessage);
    }
    return testUser.copyWith(friendCode: 'TRP-NEW999');
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> deleteAccount() async {
    if (shouldFail) {
      throw ApiException(
        code: 'validation_failed',
        message: failureMessage,
        statusCode: 422,
      );
    }
  }
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

    test('register with permanentAddress, homeCountry, and homeCurrency preserves fields', () async {
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
            name: 'Maria Santos',
            email: 'maria@tapittrip.local',
            password: 'secretPassword123!',
            passwordConfirmation: 'secretPassword123!',
            permanentAddress: 'Taguig, Metro Manila, Philippines',
            homeCountry: 'PH',
            homeCurrency: 'PHP',
          );

      expect(success, isTrue);
      final state = container.read(authProvider);
      expect(state, isA<Authenticated>());
      final user = (state as Authenticated).user;
      expect(user.permanentAddress, 'Taguig, Metro Manila, Philippines');
      expect(user.homeCountry, 'PH');
      expect(user.homeCurrency, 'PHP');
    });

    test('updateProfile updates permanentAddress and homeCurrency', () async {
      final fakeTokenStorage = InMemoryTokenStorage('mock-token');
      final fakeRepo = FakeAuthRepository();

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeTokenStorage),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // Initialize with authenticated user
      await container
          .read(authProvider.notifier)
          .register(
            name: 'Maria Santos',
            email: 'maria@tapittrip.local',
            password: 'password123',
            passwordConfirmation: 'password123',
          );

      final success = await container
          .read(authProvider.notifier)
          .updateProfile(
            displayName: 'Maria S.',
            permanentAddress: 'Cebu City, Philippines',
            homeCountry: 'PH',
            homeCurrency: 'PHP',
          );

      expect(success, isTrue);
      final state = container.read(authProvider);
      expect(state, isA<Authenticated>());
      final user = (state as Authenticated).user;
      expect(user.displayName, 'Maria S.');
      expect(user.permanentAddress, 'Cebu City, Philippines');
      expect(user.homeCountry, 'PH');
      expect(user.homeCurrency, 'PHP');
    });

    test('regenerateFriendCode updates authenticated user code', () async {
      final fakeTokenStorage = InMemoryTokenStorage('mock-token');
      final fakeRepo = FakeAuthRepository();

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeTokenStorage),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authProvider.notifier)
          .login(email: 'traveler@tapittrip.local', password: 'password');

      final updated = await container
          .read(authProvider.notifier)
          .regenerateFriendCode();

      expect(updated, isNotNull);
      expect(updated!.friendCode, 'TRP-NEW999');
      expect(
        (container.read(authProvider) as Authenticated).user.friendCode,
        'TRP-NEW999',
      );
    });

    test('deleteAccount failure preserves Authenticated state and returns explanation', () async {
      final fakeTokenStorage = InMemoryTokenStorage('mock-token');
      final fakeRepo = FakeAuthRepository();

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeTokenStorage),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authProvider.notifier)
          .login(email: 'traveler@tapittrip.local', password: 'password');

      fakeRepo.shouldFail = true;
      fakeRepo.failureMessage =
          'Transfer organizer ownership or delete shared trips first.';

      final error = await container.read(authProvider.notifier).deleteAccount();

      expect(error, fakeRepo.failureMessage);
      expect(container.read(authProvider), isA<Authenticated>());

      fakeRepo.shouldFail = false;
      final cleared = await container
          .read(authProvider.notifier)
          .deleteAccount();
      expect(cleared, isNull);
      expect(container.read(authProvider), isA<Unauthenticated>());
    });

    test(
      'exchangeOAuthToken updates state to Authenticated on success',
      () async {
        final fakeTokenStorage = InMemoryTokenStorage();
        final fakeRepo = FakeAuthRepository();

        final container = ProviderContainer(
          overrides: [
            tokenStorageProvider.overrideWithValue(fakeTokenStorage),
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
        );
        addTearDown(container.dispose);

        final ok = await container
            .read(authProvider.notifier)
            .exchangeOAuthToken(provider: 'google', idToken: 'valid-id-token');

        expect(ok, isTrue);
        final state = container.read(authProvider);
        expect(state, isA<Authenticated>());
        expect((state as Authenticated).token, 'mock-oauth-token');
      },
    );

    test('exchangeOAuthToken transitions to AuthFailure on error', () async {
      final fakeTokenStorage = InMemoryTokenStorage();
      final fakeRepo = FakeAuthRepository(
        shouldFail: true,
        failureMessage: 'Invalid OAuth token.',
      );

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(fakeTokenStorage),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final ok = await container
          .read(authProvider.notifier)
          .exchangeOAuthToken(provider: 'google', idToken: 'bad-token');

      expect(ok, isFalse);
      final state = container.read(authProvider);
      expect(state, isA<AuthFailure>());
      expect((state as AuthFailure).errorMessage, 'Invalid OAuth token.');
    });

    testWidgets(
      'LoginPage Continue with Google and Continue with Facebook authenticate via SocialAuthService',
      (tester) async {
        final fakeSocial = _FakeSocialAuthService(
          googleResult: const SocialSignInResult.success(
            token: 'valid-google-token:g1|g@example.com|Google User',
            displayName: 'Google User',
          ),
          facebookResult: const SocialSignInResult.success(
            token: 'valid-facebook-token:f1|f@example.com|FB User',
            displayName: 'FB User',
          ),
        );

        final router = GoRouter(
          initialLocation: '/login',
          routes: [
            GoRoute(
              path: '/login',
              builder: (context, state) => const LoginPage(),
            ),
            GoRoute(
              path: '/trips',
              builder: (context, state) =>
                  const Scaffold(body: Text('Trips Home')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
              authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
              socialAuthServiceProvider.overrideWithValue(fakeSocial),
            ],
            child: MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('Continue with Facebook'), findsOneWidget);

        await tester.ensureVisible(find.text('Continue with Google'));
        await tester.tap(find.text('Continue with Google'));
        await tester.pumpAndSettle();

        expect(fakeSocial.googleCalls, 1);
        expect(find.text('Trips Home'), findsOneWidget);
        expect(find.text('Welcome back, Traveler!'), findsOneWidget);
      },
    );

    test('signInWithSocialProvider handles Facebook success, cancellation, and error', () async {
      final fakeSocial = _FakeSocialAuthService(
        googleResult: const SocialSignInResult.cancelled(),
        facebookResult: const SocialSignInResult.success(
          token: 'valid-facebook-token:fb-1|fb@example.com|FB Traveler',
          displayName: 'FB Traveler',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          socialAuthServiceProvider.overrideWithValue(fakeSocial),
        ],
      );
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);

      // Cancelled Google sign-in does not set AuthFailure
      final cancelled = await container
          .read(authProvider.notifier)
          .signInWithSocialProvider('google');
      expect(cancelled, isFalse);
      expect(container.read(authProvider), isA<Unauthenticated>());

      // Facebook sign-in succeeds
      final fbOk = await container
          .read(authProvider.notifier)
          .signInWithSocialProvider('facebook');
      expect(fbOk, isTrue);
      expect(container.read(authProvider), isA<Authenticated>());
    });
  });
}

class _FakeSocialAuthService implements SocialAuthService {
  _FakeSocialAuthService({
    required this.googleResult,
    required this.facebookResult,
  });

  final SocialSignInResult googleResult;
  final SocialSignInResult facebookResult;
  int googleCalls = 0;
  int facebookCalls = 0;

  @override
  Future<SocialSignInResult> signInWithGoogle() async {
    googleCalls++;
    return googleResult;
  }

  @override
  Future<SocialSignInResult> signInWithFacebook() async {
    facebookCalls++;
    return facebookResult;
  }
}
