import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../circles/data/trip_circle_repository.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/auth_user.dart';

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;
  late final TokenStorage _tokenStorage;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _tokenStorage = ref.watch(tokenStorageProvider);
    _checkInitialAuth();
    return const AuthInitial();
  }

  Future<void> _checkInitialAuth() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      state = const Unauthenticated();
      return;
    }

    try {
      final user = await _repository.getProfile();
      state = Authenticated(user: user, token: token);
    } catch (_) {
      await _tokenStorage.deleteToken();
      state = const Unauthenticated();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AuthLoading('Logging in...');
    try {
      final result = await _repository.login(email: email, password: password);
      state = Authenticated(user: result.user, token: result.token);
      return true;
    } on ApiException catch (e) {
      state = AuthFailure(e.message);
      return false;
    } catch (e) {
      state = AuthFailure('An unexpected error occurred: $e');
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? permanentAddress,
    String? homeCountry,
    String? homeCurrency,
  }) async {
    state = const AuthLoading('Creating your account...');
    try {
      final result = await _repository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        permanentAddress: permanentAddress,
        homeCountry: homeCountry,
        homeCurrency: homeCurrency,
      );
      state = Authenticated(user: result.user, token: result.token);
      return true;
    } on ValidationException catch (e) {
      state = AuthFailure(e.fieldErrors.join('\n'));
      return false;
    } on ApiException catch (e) {
      state = AuthFailure(e.message);
      return false;
    } catch (e) {
      state = AuthFailure('An unexpected error occurred: $e');
      return false;
    }
  }

  Future<void> logout() async {
    state = const AuthLoading('Logging out...');
    try {
      await _repository.logout();
      await ref.read(tripCircleRepositoryProvider).purgeInboxCaches();
    } finally {
      state = const Unauthenticated();
    }
  }

  Future<String?> deleteAccount() async {
    final previousState = state;
    state = const AuthLoading('Deleting account...');
    try {
      await _repository.deleteAccount();
      await ref.read(tripCircleRepositoryProvider).purgeInboxCaches();
      state = const Unauthenticated();
      return null;
    } on ValidationException catch (e) {
      state = previousState;
      return e.fieldErrors.isNotEmpty ? e.fieldErrors.join('\n') : e.message;
    } on ApiException catch (e) {
      state = previousState;
      return e.message;
    } catch (e) {
      state = previousState;
      return 'Unable to delete account right now.';
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? permanentAddress,
    String? homeCountry,
    String? homeCurrency,
    String? homeTimezone,
    String? locale,
    bool? acceptsDirectInvites,
  }) async {
    final current = state;
    if (current is! Authenticated) return false;

    try {
      final updatedUser = await _repository.updateProfile(
        displayName: displayName,
        permanentAddress: permanentAddress,
        homeCountry: homeCountry,
        homeCurrency: homeCurrency,
        homeTimezone: homeTimezone,
        locale: locale,
        acceptsDirectInvites: acceptsDirectInvites,
      );
      state = Authenticated(user: updatedUser, token: current.token);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<AuthUser?> regenerateFriendCode() async {
    final current = state;
    if (current is! Authenticated) return null;

    try {
      final updatedUser = await _repository.regenerateFriendCode();
      state = Authenticated(user: updatedUser, token: current.token);
      return updatedUser;
    } catch (_) {
      return null;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
