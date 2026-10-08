import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/core/errors/exceptions.dart';
import 'package:healthcare_app/features/diet_exercise/services/services.dart';

/// Unit tests for the timeout + error classification wrapper every Phase 15
/// Firestore call runs through. They never touch Firebase: the operation is a
/// plain Future, so the contract (always completes, always an [AppException],
/// always a safe message) is verified directly.
void main() {
  const failureMessage = 'Unable to load your water intake right now. '
      'Please try again.';

  group('runFirestoreOperation', () {
    test('returns the operation result when it succeeds', () async {
      final result = await runFirestoreOperation<String>(
        operation: () => Future.value('ok'),
        failureMessage: failureMessage,
      );

      expect(result, 'ok');
    });

    test('a never-completing operation times out instead of hanging',
        () async {
      final future = runFirestoreOperation<String>(
        // Completes after the injected budget, so the timeout must win.
        operation: () => Future.delayed(
          const Duration(milliseconds: 500),
          () => 'too late',
        ),
        failureMessage: failureMessage,
        timeout: const Duration(milliseconds: 20),
      );

      await expectLater(future, throwsA(isA<AppException>()));
    });

    test('a timeout produces the dedicated timeout message and status',
        () async {
      try {
        await runFirestoreOperation<String>(
          operation: () => Completer<String>().future,
          failureMessage: failureMessage,
          timeout: const Duration(milliseconds: 20),
        );
        fail('Expected an AppException');
      } on AppException catch (e) {
        expect(e.message, firestoreTimeoutMessage);
        expect(e.statusCode, 408);
      }
    });

    test('a permission error is classified, not swallowed', () async {
      try {
        await runFirestoreOperation<String>(
          operation: () => Future.error(
            Exception(
              '[firebase_firestore/permission-denied] '
              'Missing or insufficient permissions.',
            ),
          ),
          failureMessage: failureMessage,
        );
        fail('Expected an AppException');
      } on AppException catch (e) {
        expect(e.message, contains('permission'));
        expect(e.message, isNot(failureMessage));
      }
    });

    test('a connectivity error is classified, not swallowed', () async {
      try {
        await runFirestoreOperation<String>(
          operation: () => Future.error(
            Exception('[firebase_firestore/unavailable] network error'),
          ),
          failureMessage: failureMessage,
        );
        fail('Expected an AppException');
      } on AppException catch (e) {
        expect(e.message, contains('internet connection'));
      }
    });

    test('an unclassified failure keeps the caller message', () async {
      try {
        await runFirestoreOperation<String>(
          operation: () => Future.error(Exception('something else')),
          failureMessage: failureMessage,
        );
        fail('Expected an AppException');
      } on AppException catch (e) {
        expect(e.message, failureMessage);
      }
    });

    test('an already classified exception passes through unchanged', () async {
      const original = AuthException(message: 'User is not authenticated.');

      await expectLater(
        runFirestoreOperation<String>(
          operation: () => Future.error(original),
          failureMessage: failureMessage,
        ),
        throwsA(same(original)),
      );
    });
  });

  group('mapFirestoreError', () {
    test('permission-denied maps to the permission message', () {
      final message = mapFirestoreError(
        Exception('[firebase_firestore/permission-denied] denied'),
        failureMessage,
      );

      expect(message, contains('permission'));
    });

    test(
        'the permission message never tells a signed-in user to sign out, '
        'because the session is valid and rules are the real cause', () {
      final message = mapFirestoreError(
        Exception(
          '[firebase_firestore/permission-denied] '
          'Missing or insufficient permissions.',
        ),
        failureMessage,
      );
      final lower = message.toLowerCase();

      expect(message, contains('permission'));
      expect(lower, isNot(contains('sign out')));
      expect(lower, isNot(contains('sign in')));
    });

    test('network conditions map to the connectivity message', () {
      for (final code in ['unavailable', 'network', 'offline']) {
        final message = mapFirestoreError(
          Exception('[firebase_firestore/$code] boom'),
          failureMessage,
        );
        expect(message, contains('internet connection'), reason: code);
      }
    });

    test('unknown errors fall back to the caller message', () {
      expect(mapFirestoreError(Exception('???'), failureMessage),
          failureMessage);
    });
  });
}
