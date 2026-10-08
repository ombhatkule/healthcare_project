import 'dart:io';

/// Base service class that all services will extend.
/// Provides common functionality for API communication and error handling.
abstract class BaseService {
  /// Base URL for the Flask backend API.
  /// Uses 10.0.2.2 for Android Emulator (maps to host 127.0.0.1).
  /// Uses localhost for other platforms.
  String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  /// Common headers for API requests.
  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Headers with authentication token.
  Map<String, String> authHeaders(String token) => {
        ...headers,
        'Authorization': 'Bearer $token',
      };
}
