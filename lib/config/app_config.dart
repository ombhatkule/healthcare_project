import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized application configuration.
/// Reads values from the environment (.env file and --dart-define).
/// Secrets are never hardcoded in source code.
abstract final class AppConfig {
  // Firebase Web config (used for web builds).
  static String get firebaseApiKey =>
      _readEnv('FIREBASE_API_KEY');

  static String get firebaseAuthDomain =>
      _readEnv('FIREBASE_AUTH_DOMAIN');

  static String get firebaseProjectId =>
      _readEnv('FIREBASE_PROJECT_ID');

  static String get firebaseStorageBucket =>
      _readEnv('FIREBASE_STORAGE_BUCKET');

  static String get firebaseMessagingSenderId =>
      _readEnv('FIREBASE_MESSAGING_SENDER_ID');

  static String get firebaseAppId =>
      _readEnv('FIREBASE_APP_ID');

  // Flask backend.
  static String get backendBaseUrl =>
      _readEnv('BACKEND_BASE_URL', fallback: 'http://localhost:5000/api');

  // The AI assistant provider key is server-side only: it lives in the Flask
  // backend's .env and is never read by the app.

  /// Reads a value from .env file or returns the fallback.
  /// --dart-define values take precedence over the .env file.
  static String _readEnv(String key, {String fallback = ''}) {
    final fromDefine = String.fromEnvironment(key);
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.maybeGet(key) ?? fallback;
  }

  /// Whether the app is running inside a unit/widget test.
  static bool get isTesting =>
      const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
}
