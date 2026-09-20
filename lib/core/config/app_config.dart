import 'package:flutter/foundation.dart';

class AppConfig {
  /// Toggle this to `true` when building the APK for live deployment!
  static const bool isProduction = false;

  /// Replace this with your live Render/Railway URL (e.g. https://money-reminder-backend.onrender.com)
  static const String liveBackendUrl = 'https://money-reminder-backend.onrender.com';

  /// Local development URLs
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
