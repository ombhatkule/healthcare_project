import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'base_service.dart';

/// Result of a backend health check.
class HealthCheckResult {
  final bool isConnected;
  final String message;
  final int? statusCode;

  const HealthCheckResult({
    required this.isConnected,
    required this.message,
    this.statusCode,
  });

  factory HealthCheckResult.connected() => const HealthCheckResult(
        isConnected: true,
        message: 'Backend Connected ✓',
      );

  factory HealthCheckResult.failed(String message, {int? statusCode}) =>
      HealthCheckResult(
        isConnected: false,
        message: message,
        statusCode: statusCode,
      );
}

/// Service for communicating with the Flask backend API.
class ApiService extends BaseService {
  /// Checks the Flask backend health endpoint.
  ///
  /// Sends GET /api/health to http://10.0.2.2:5000/api/health
  /// Returns a [HealthCheckResult] indicating success or failure.
  Future<HealthCheckResult> checkBackendHealth() async {
    final url = Uri.parse('$baseUrl/health');

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final status = body['status'] as String?;

        if (status == 'success') {
          return HealthCheckResult.connected();
        } else {
          return HealthCheckResult.failed(
            'Unexpected response status: $status',
            statusCode: response.statusCode,
          );
        }
      } else {
        return HealthCheckResult.failed(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      return HealthCheckResult.failed('Connection timed out (10s)');
    } on SocketException catch (e) {
      if (e.message.contains('Connection refused')) {
        return HealthCheckResult.failed('Connection refused — is Flask running?');
      }
      return HealthCheckResult.failed('Socket error: ${e.message}');
    } on HttpException catch (e) {
      return HealthCheckResult.failed('HTTP error: ${e.message}');
    } on FormatException {
      return HealthCheckResult.failed('Invalid response format');
    } catch (e) {
      return HealthCheckResult.failed('Unexpected error: $e');
    }
  }
}
