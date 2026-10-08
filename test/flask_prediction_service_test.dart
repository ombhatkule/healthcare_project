import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/disease_prediction/models/prediction_result.dart';
import 'package:healthcare_app/features/disease_prediction/models/symptom.dart';
import 'package:healthcare_app/features/disease_prediction/services/disease_prediction_service.dart';
import 'package:healthcare_app/features/disease_prediction/services/flask_disease_prediction_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const selectedSymptoms = [
    Symptom(id: 'fever', name: 'Fever'),
    Symptom(id: 'cough', name: 'Cough'),
  ];

  MockClient successClient() {
    return MockClient((request) async {
      final body = json.decode(request.body) as Map<String, dynamic>;
      expect(request.method, 'POST');
      expect(request.url.path, '/api/predict');
      expect(body['symptoms'], isNotEmpty);
      return http.Response(
        json.encode({
          'status': 'success',
          'prediction': {'disease': 'muscular dystrophy', 'score': 0.0286},
          'top_predictions': [
            {'disease': 'muscular dystrophy', 'score': 0.0286},
            {'disease': 'influenza', 'score': 0.0213},
          ],
          'disclaimer':
              'Research/Educational Use Only. This experimental prediction is '
              'not a medical diagnosis.',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
  }

  FlaskDiseasePredictionService build(http.Client client) =>
      FlaskDiseasePredictionService(client: client);

  group('FlaskDiseasePredictionService.predict', () {
    test('parses a successful response into a PredictionResult', () async {
      final result = await build(successClient()).predict(selectedSymptoms);

      expect(result.isDemo, isFalse);
      expect(result.prediction, 'muscular dystrophy');
      expect(result.score, closeTo(0.0286, 0.00001));
      expect(result.modelScoreLabel, '2.86%');
      expect(result.topPredictions, hasLength(2));
      expect(result.topPredictions.first.disease, 'muscular dystrophy');
      expect(result.topPredictions.first.scoreLabel, '2.86%');
      expect(result.disclaimer, contains('Research/Educational'));
      expect(result.selectedSymptoms, hasLength(2));
    });

    test('sends canonical backend symptom IDs unchanged (no remapping)',
        () async {
      List<dynamic>? sentSymptoms;
      final client = MockClient((request) async {
        sentSymptoms =
            (json.decode(request.body) as Map<String, dynamic>)['symptoms']
                as List<dynamic>?;
        return http.Response(
          json.encode({
            'status': 'success',
            'prediction': {'disease': 'influenza', 'score': 0.01},
            'top_predictions': [
              {'disease': 'influenza', 'score': 0.01},
            ],
            'disclaimer': 'Research/Educational Use Only',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      // The UI catalog comes straight from GET /api/symptoms, so these IDs
      // ARE the canonical backend names and are forwarded unchanged.
      await build(client).predict(const [
        Symptom(id: 'sore_throat', name: 'Sore Throat'),
        Symptom(id: 'shortness_of_breath', name: 'Shortness of Breath'),
        Symptom(id: 'nasal_congestion', name: 'Nasal Congestion'),
      ]);

      expect(sentSymptoms, [
        'sore_throat',
        'shortness_of_breath',
        'nasal_congestion',
      ]);
    });

    test('throws a friendly error listing unknown symptoms', () async {
      final client = MockClient((request) async => http.Response(
            json.encode({
              'status': 'error',
              'message': 'One or more symptoms are not recognized',
              'unknown_symptoms': ['chest_pain', 'runny_nose'],
            }),
            400,
            headers: {'content-type': 'application/json'},
          ));

      await expectLater(
        build(client).predict(selectedSymptoms),
        throwsA(
          isA<PredictionException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('not supported'),
              contains('chest_pain'),
              contains('runny_nose'),
            ),
          ),
        ),
      );
    });

    test('throws "Please select at least one symptom." for empty symptoms',
        () async {
      final client = MockClient((request) async => http.Response(
            json.encode({
              'status': 'error',
              "message": "'symptoms' must not be empty",
            }),
            400,
            headers: {'content-type': 'application/json'},
          ));

      await expectLater(
        build(client).predict(selectedSymptoms),
        throwsA(
          isA<PredictionException>().having(
            (e) => e.message,
            'message',
            'Please select at least one symptom.',
          ),
        ),
      );
    });

    test('connection refused surfaces the backend connection message',
        () async {
      final client = MockClient(
        (request) async => throw SocketException('Connection refused'),
      );

      await expectLater(
        build(client).predict(selectedSymptoms),
        throwsA(
          isA<PredictionException>().having(
            (e) => e.message,
            'message',
            allOf(contains('Unable to connect'), contains('backend')),
          ),
        ),
      );
    });

    test('HTTP client errors surface the backend connection message',
        () async {
      final client = MockClient(
        (request) async =>
            throw http.ClientException('Connection failed', request.url),
      );

      await expectLater(
        build(client).predict(selectedSymptoms),
        throwsA(
          isA<PredictionException>().having(
            (e) => e.message,
            'message',
            allOf(contains('Unable to connect'), contains('backend')),
          ),
        ),
      );
    });

    test('server error surfaces the backend message', () async {
      final client = MockClient((request) async => http.Response(
            json.encode({
              'status': 'error',
              'message': 'Prediction failed. Please try again.',
            }),
            500,
            headers: {'content-type': 'application/json'},
          ));

      await expectLater(
        build(client).predict(selectedSymptoms),
        throwsA(
          isA<PredictionException>().having(
            (e) => e.message,
            'message',
            'Prediction failed. Please try again.',
          ),
        ),
      );
    });

    test('503 without a body message surfaces an unavailable message',
        () async {
      final client = MockClient((request) async => http.Response(
            'Service Unavailable',
            503,
            headers: {'content-type': 'text/plain'},
          ));

      await expectLater(
        build(client).predict(selectedSymptoms),
        throwsA(
          isA<PredictionException>().having(
            (e) => e.message,
            'message',
            contains('temporarily unavailable'),
          ),
        ),
      );
    });

    test('404 surfaces a clear not-found error', () async {
      final client = MockClient((request) async => http.Response(
            'Not Found',
            404,
            headers: {'content-type': 'text/html'},
          ));

      await expectLater(
        build(client).predict(selectedSymptoms),
        throwsA(
          isA<PredictionException>().having(
            (e) => e.message,
            'message',
            contains('could not be found'),
          ),
        ),
      );
    });

    test('malformed response body does not crash and throws a safe error',
        () async {
      final client = MockClient((request) async => http.Response(
            'this is not json',
            200,
            headers: {'content-type': 'text/plain'},
          ));

      await expectLater(
        build(client).predict(selectedSymptoms),
        throwsA(isA<PredictionException>()),
      );
    });

    test('empty selection throws before any HTTP request', () async {
      final client = MockClient(
        (request) async => fail('should not make an HTTP request'),
      );

      await expectLater(
        build(client).predict(const <Symptom>[]),
        throwsA(
          isA<PredictionException>().having(
            (e) => e.message,
            'message',
            'Please select at least one symptom.',
          ),
        ),
      );
    });
  });

  group('PredictionResult.fromFlaskResponse', () {
    test('parses prediction, top predictions and disclaimer', () {
      final result = PredictionResult.fromFlaskResponse(
        {
          'status': 'success',
          'prediction': {'disease': 'muscular dystrophy', 'score': 0.0286},
          'top_predictions': [
            {'disease': 'muscular dystrophy', 'score': 0.0286},
          ],
          'disclaimer': 'Scores are raw Random Forest ensemble outputs.',
        },
        selectedSymptoms: const [
          Symptom(id: 'fever', name: 'Fever'),
        ],
      );

      expect(result.isDemo, isFalse);
      expect(result.prediction, 'muscular dystrophy');
      expect(result.modelScoreLabel, '2.86%');
      expect(result.topPredictions.single.disease, 'muscular dystrophy');
      expect(result.disclaimer, isNotNull);
    });

    test('does not treat the model score as a calibrated probability', () {
      final result = PredictionResult.fromFlaskResponse(
        {
          'status': 'success',
          'prediction': {'disease': 'flu', 'score': 0.5},
          'top_predictions': [
            {'disease': 'flu', 'score': 0.5},
          ],
        },
        selectedSymptoms: const [],
      );

      // The raw score must not be relabelled as health/confidence math.
      expect(result.modelScoreLabel, isNot(equals('98%')));
      expect(result.modelScoreLabel, '50.00%');
      expect(result.topPredictions.single.scoreLabel, '50.00%');
    });
  });

  group('FlaskDiseasePredictionService.fetchSymptoms', () {
    test('parses the backend symptom catalog in server order', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/symptoms');
        return http.Response(
          json.encode({
            'status': 'success',
            'count': 3,
            'symptoms': ['itching', 'skin_rash', 'cold_hands_and_feets'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final symptoms = await build(client).fetchSymptoms();

      expect(symptoms, hasLength(3));
      expect(symptoms[0].id, 'itching');
      expect(symptoms[0].name, 'Itching');
      // Underscores become spaces and words are title-cased for display.
      expect(symptoms[2].id, 'cold_hands_and_feets');
      expect(symptoms[2].name, 'Cold Hands And Feets');
    });

    test('surfaces a friendly error when the catalog endpoint fails',
        () async {
      final client = MockClient((request) async => http.Response(
            'Service Unavailable',
            503,
            headers: {'content-type': 'text/plain'},
          ));

      await expectLater(
        build(client).fetchSymptoms(),
        throwsA(isA<PredictionException>()),
      );
    });

    test('connection failure surfaces the backend connection message',
        () async {
      final client = MockClient(
        (request) async => throw SocketException('Connection refused'),
      );

      await expectLater(
        build(client).fetchSymptoms(),
        throwsA(
          isA<PredictionException>().having(
            (e) => e.message,
            'message',
            allOf(contains('Unable to connect'), contains('backend')),
          ),
        ),
      );
    });
  });
}