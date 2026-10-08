import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../shared/services/base_service.dart';
import '../models/prediction_result.dart';
import '../models/symptom.dart';
import 'disease_prediction_service.dart';

/// Real implementation of [DiseasePredictionService] backed by the Flask
/// backend (`GET /api/symptoms` and `POST /api/predict`).
///
/// The endpoint runs the Phase 7J research/educational experimental Logistic
/// Regression model. Symptom IDs are the backend's canonical symptom names:
/// the catalog returned by `GET /api/symptoms` feeds the UI directly, so the
/// same string is sent back to `POST /api/predict` without any remapping.
///
/// Scores are raw, un-calibrated model outputs — the UI must keep presenting
/// them labelled as experimental model scores and must never present them as
/// medical probability or diagnostic confidence.
class FlaskDiseasePredictionService extends BaseService
    implements DiseasePredictionService {
  static const String _unreachableMessage =
      'Unable to connect to the healthcare server. Please make sure the '
      'backend is running and try again.';

  static const String _genericFailure =
      'Prediction could not be completed. Please try again.';

  final http.Client _client;

  /// [client] is injectable so unit tests can run against a mocked HTTP layer
  /// without a running Flask server.
  FlaskDiseasePredictionService({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<List<Symptom>> fetchSymptoms() async {
    // baseUrl already includes /api so this targets /api/symptoms.
    final uri = Uri.parse('$baseUrl/symptoms');

    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      final decoded = _decodeMap(response.body);
      if (response.statusCode == 200 &&
          decoded?['status'] == 'success' &&
          decoded != null) {
        final raw = decoded['symptoms'];
        if (raw is List) {
          return List.unmodifiable(
            raw
                .whereType<String>()
                .map((id) => Symptom(id: id, name: _humanize(id))),
          );
        }
        throw const PredictionException(_genericFailure);
      }

      throw PredictionException(
        _errorMessage(decoded ?? const {}, response.statusCode),
      );
    } on TimeoutException {
      throw const PredictionException(_unreachableMessage);
    } on SocketException {
      throw const PredictionException(_unreachableMessage);
    } on http.ClientException {
      throw const PredictionException(_unreachableMessage);
    } on PredictionException {
      rethrow;
    } on FormatException {
      throw const PredictionException(_genericFailure);
    } catch (_) {
      throw const PredictionException(_genericFailure);
    }
  }

  @override
  Future<PredictionResult> predict(List<Symptom> symptoms) async {
    // Symptom IDs ARE the canonical backend symptom names (the catalog comes
    // from GET /api/symptoms), so they are sent through unchanged.
    final symptomIds = symptoms.map((s) => s.id).toList(growable: false);

    if (symptomIds.isEmpty) {
      throw const PredictionException(
        'Please select at least one symptom.',
      );
    }

    // baseUrl already includes /api so this targets /api/predict.
    final uri = Uri.parse('$baseUrl/predict');

    try {
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode({'symptoms': symptomIds}),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response, symptoms);
    } on TimeoutException {
      throw const PredictionException(_unreachableMessage);
    } on SocketException {
      throw const PredictionException(_unreachableMessage);
    } on http.ClientException {
      throw const PredictionException(_unreachableMessage);
    } on PredictionException {
      rethrow;
    } on FormatException {
      throw const PredictionException(_genericFailure);
    } catch (_) {
      throw const PredictionException(_genericFailure);
    }
  }

  /// Interprets the Flask response and converts it into a [PredictionResult]
  /// or throws a user-friendly [PredictionException].
  PredictionResult _handleResponse(
    http.Response response,
    List<Symptom> symptoms,
  ) {
    final body = _decodeMap(response.body);

    if (response.statusCode == 200 && body?['status'] == 'success') {
      return PredictionResult.fromFlaskResponse(
        body!,
        selectedSymptoms: symptoms,
      );
    }

    throw PredictionException(_errorMessage(body ?? const {}, response.statusCode));
  }

  /// Decodes a JSON object body, or null when the body is not a JSON object.
  Map<String, dynamic>? _decodeMap(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Non-JSON body (e.g. an HTML 404 page) — fall through to status-code
      // messaging in _handleResponse/fetchSymptoms.
    }
    return null;
  }

  /// Builds a clear, user-facing message from a backend error response.
  String _errorMessage(Map<String, dynamic> body, int statusCode) {
    final message = body['message'] as String?;

    // Unknown symptoms -> list them so the user can adjust the selection.
    if (body['unknown_symptoms'] is List &&
        (body['unknown_symptoms'] as List).isNotEmpty) {
      final unknown =
          (body['unknown_symptoms'] as List).map((e) => e.toString()).join(', ');
      return 'Some selected symptoms are not supported: $unknown. '
          'Please remove them and try again.';
    }

    if (message != null && message.isNotEmpty) {
      // Convert backend wording for the empty selection case.
      if (message.contains('must not be empty')) {
        return 'Please select at least one symptom.';
      }
      return message;
    }

    switch (statusCode) {
      case 400:
        return 'Please select at least one symptom.';
      case 404:
        return 'The prediction endpoint could not be found on the server. '
            'Please check the backend setup.';
      case 500:
      case 503:
        return 'The prediction service is temporarily unavailable. '
            'Please try again later.';
      default:
        return _genericFailure;
    }
  }

  /// Converts a canonical backend symptom name (e.g. `cold_hands_and_feets`)
  /// into a display label (e.g. `Cold Hands And Feets`).
  static String _humanize(String id) {
    return id
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}