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
  });

  Future<AuthUser> getProfile();

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
  }) async {
    final response = await apiClient.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
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
  Future<AuthUser> getProfile() async {
    final response = await apiClient.get('/me');
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
