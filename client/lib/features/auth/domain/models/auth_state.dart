import 'auth_user.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading([this.message]);
  final String? message;
}

class Authenticated extends AuthState {
  const Authenticated({required this.user, required this.token});
  final AuthUser user;
  final String token;
}

class Unauthenticated extends AuthState {
  const Unauthenticated([this.message]);
  final String? message;
}

class AuthFailure extends AuthState {
  const AuthFailure(this.errorMessage);
  final String errorMessage;
}
