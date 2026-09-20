import 'package:flutter/foundation.dart';

enum Environment { dev, prod }

class AppConfig {
  /// Current active environment.
  /// Change to `Environment.prod` when compiling for release / phone testing with Neon DB & Cloud backend.
  /// Or pass `--dart-define=ENV=prod` during flutter build.
  static const String _envString = String.fromEnvironment('ENV', defaultValue: 'dev');

  static Environment get currentEnvironment {
    if (_envString.toLowerCase() == 'prod') {
      return Environment.prod;
    }
    return Environment.dev;
  }

  static bool get isProduction => currentEnvironment == Environment.prod;

  // -------------------------------------------------------------
  // Backend Endpoints
  // -------------------------------------------------------------
  /// Production Backend (e.g. Render / Railway cloud deployment connected to Neon DB)
  static const String liveBackendUrl = 'https://money-reminder-backend.onrender.com';

  /// Development / Localhost Endpoints (for Chrome web & Android emulator)
  static const String localWebUrl = 'http://localhost:8080';
  static const String localAndroidEmulatorUrl = 'http://10.0.2.2:8080';

  static String get backendBaseUrl {
    if (isProduction) {
      return liveBackendUrl;
    }
    if (kIsWeb) {
      return localWebUrl;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return localAndroidEmulatorUrl;
    }
    return localWebUrl;
  }

  static String get apiBaseUrl => '$backendBaseUrl/api';
  static String get whatsAppApiUrl => '$backendBaseUrl/api/notifications/whatsapp';
}
