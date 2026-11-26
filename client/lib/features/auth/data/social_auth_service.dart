import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialSignInResult {
  const SocialSignInResult({
    this.token,
    this.displayName,
    this.cancelled = false,
    this.errorMessage,
  });

  const SocialSignInResult.cancelled() : this(cancelled: true);

  const SocialSignInResult.failure(String message)
    : this(errorMessage: message);

  const SocialSignInResult.success({required String token, String? displayName})
    : this(token: token, displayName: displayName);

  final String? token;
  final String? displayName;
  final bool cancelled;
  final String? errorMessage;

  bool get isSuccess =>
      !cancelled && errorMessage == null && token != null && token!.isNotEmpty;
}

abstract class SocialAuthService {
  Future<SocialSignInResult> signInWithGoogle();
  Future<SocialSignInResult> signInWithFacebook();
}

/// Default provider boundary for Google and Facebook sign-in.
///
/// Checks `.env` configuration (`GOOGLE_OAUTH_CLIENT_ID` / `FACEBOOK_APP_ID`)
/// and returns a transparent limitation until native iOS/Android SDKs
/// (`google_sign_in` / `flutter_facebook_auth`) and platform app IDs are
/// registered and wired.
class PlatformSocialAuthService implements SocialAuthService {
  const PlatformSocialAuthService();

  String _envValue(String key) {
    try {
      return (dotenv.maybeGet(key) ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  @override
  Future<SocialSignInResult> signInWithGoogle() async {
    final clientId = _envValue('GOOGLE_OAUTH_CLIENT_ID');
    if (clientId.isEmpty) {
      return const SocialSignInResult.failure(
        'Google Sign-In is not configured for this build yet. '
        'Add GOOGLE_OAUTH_CLIENT_ID and native SDK credentials to enable it.',
      );
    }

    return const SocialSignInResult.failure(
      'Native Google Sign-In SDK adapter is not linked on this platform yet.',
    );
  }

  @override
  Future<SocialSignInResult> signInWithFacebook() async {
    final appId = _envValue('FACEBOOK_APP_ID');
    if (appId.isEmpty) {
      return const SocialSignInResult.failure(
        'Facebook Sign-In is not configured for this build yet. '
        'Add FACEBOOK_APP_ID and native SDK credentials to enable it.',
      );
    }

    return const SocialSignInResult.failure(
      'Native Facebook Login SDK adapter is not linked on this platform yet.',
    );
  }
}

final socialAuthServiceProvider = Provider<SocialAuthService>(
  (ref) => const PlatformSocialAuthService(),
);
