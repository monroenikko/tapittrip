import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/models/auth_user.dart';

abstract interface class AuthRepository {
  Future<({AuthUser user, String token})> login({
    required String email,
    required String password,
    String? deviceName,
  });

  Future<({AuthUser user, String token})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? deviceName,
    String? permanentAddress,
    String? homeCountry,
    String? homeCurrency,
  });

  Future<AuthUser> getProfile();

  Future<AuthUser> updateProfile({
    String? displayName,
    String? permanentAddress,
    String? homeCountry,
    String? homeCurrency,
    String? homeTimezone,
    String? locale,
  });

  Future<void> logout();

  Future<void> deleteAccount();
}

class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  @override
  Future<({AuthUser user, String token})> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    final response = await apiClient.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        'device_name': deviceName ?? 'TapItTrip Mobile',
      },
    );

    final token = response['token'] as String;
    final userJson = response['user'] as Map<String, dynamic>;
    final user = AuthUser.fromJson(userJson);

    await tokenStorage.writeToken(token);
    return (user: user, token: token);
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
    final response = await apiClient.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': deviceName ?? 'TapItTrip Mobile',
        if (permanentAddress != null && permanentAddress.isNotEmpty)
          'permanent_address': permanentAddress,
        if (homeCountry != null && homeCountry.isNotEmpty)
          'home_country': homeCountry,
        if (homeCurrency != null && homeCurrency.isNotEmpty)
          'home_currency': homeCurrency,
      },
    );

    final token = response['token'] as String;
    final userJson = response['user'] as Map<String, dynamic>;
    final user = AuthUser.fromJson(userJson);

    await tokenStorage.writeToken(token);
    return (user: user, token: token);
  }

  @override
  Future<AuthUser> getProfile() async {
    final response = await apiClient.get('/me');
    return AuthUser.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AuthUser> updateProfile({
    String? displayName,
    String? permanentAddress,
    String? homeCountry,
    String? homeCurrency,
    String? homeTimezone,
    String? locale,
  }) async {
    final payload = <String, dynamic>{};
    if (displayName != null) payload['display_name'] = displayName;
    if (permanentAddress != null) {
      payload['permanent_address'] = permanentAddress;
    }
    if (homeCountry != null) payload['home_country'] = homeCountry;
    if (homeCurrency != null) payload['home_currency'] = homeCurrency;
    if (homeTimezone != null) payload['home_timezone'] = homeTimezone;
    if (locale != null) payload['locale'] = locale;

    final response = await apiClient.patch('/me', data: payload);
    return AuthUser.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post('/auth/logout');
    } finally {
      await tokenStorage.deleteToken();
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await apiClient.delete('/me');
    } finally {
      await tokenStorage.deleteToken();
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return RemoteAuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);
});
