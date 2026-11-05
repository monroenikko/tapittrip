import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  /// Default API base URL if not provided via .env
  static const String defaultApiBaseUrl = 'http://127.0.0.1:8088/api/v1';

  /// Returns the configured API base URL.
  static String get apiBaseUrl {
    if (!dotenv.isInitialized) {
      return defaultApiBaseUrl;
    }
    return dotenv.env['API_BASE_URL'] ?? defaultApiBaseUrl;
  }
}
