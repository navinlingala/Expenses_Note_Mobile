import 'package:flutter/foundation.dart';

enum Environment { dev, prod }

class AppConfig {
  /// Current active environment.
  /// Defaults to prod for live backend with Neon DB, or pass `--dart-define=ENV=dev` for localhost testing.
  static const String _envString = String.fromEnvironment('ENV', defaultValue: 'prod');

  static Environment get currentEnvironment {
    if (_envString.toLowerCase() == 'dev') {
      return Environment.dev;
    }
    return Environment.prod;
  }

  static bool get isProduction => currentEnvironment == Environment.prod;

  // -------------------------------------------------------------
  // Backend Endpoints
  // -------------------------------------------------------------
  /// Current Wi-Fi IP of this machine (updated from ipconfig)
  static const String liveBackendUrl = 'http://192.168.55.105:8080';
  // static const String liveBackendUrl = 'https://expenses-note-backend.onrender.com';
  
  /// Development / Localhost Endpoints (for Chrome web & Android emulator)
  static const String localWebUrl = 'http://localhost:8080';
  static const String localAndroidEmulatorUrl = 'http://10.0.2.2:8080';

  static String get backendBaseUrl {
    // When running in web browser (Chrome), always connect to localhost:8080 directly
    if (kIsWeb) {
      return localWebUrl;
    }
    if (isProduction) {
      return liveBackendUrl;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return localAndroidEmulatorUrl;
    }
    return localWebUrl;
  }

  static String get apiBaseUrl => '$backendBaseUrl/api';
  static String get whatsAppApiUrl => '$backendBaseUrl/api/notifications/whatsapp';
}
