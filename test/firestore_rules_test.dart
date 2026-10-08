import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the project Firestore security rules against accidental weakening.
///
/// The rules file is the source of truth that `firebase deploy --only
/// firestore:rules` uploads, so these checks protect the owner-scoped access
/// model the whole app depends on. They must never be relaxed to
/// `if true` or to an unauthenticated wildcard.
void main() {
  final rules = File('firestore.rules').readAsStringSync();

  group('Firestore rules stay owner-scoped', () {
    test('never opens public or unauthenticated access', () {
      expect(RegExp(r'if\s+true').hasMatch(rules), isFalse,
          reason: 'no rule may allow access unconditionally');
      expect(rules.contains('match /{document=**}'), isFalse,
          reason: 'no unauthenticated wildcard match may exist');
    });

    test('every allow statement requires an authenticated owner', () {
      final allowLines = rules
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.startsWith('allow '))
          .toList();

      expect(allowLines, isNotEmpty,
          reason: 'the rules file must contain allow statements');

      for (final line in allowLines) {
        // `allow delete: if false;` is an explicit deny and needs no guard.
        if (line.contains('if false')) continue;
        expect(line, contains('request.auth != null'), reason: line);
        expect(line, contains('request.auth.uid == userId'), reason: line);
      }
    });

    test('covers every user-scoped path the app reads and writes', () {
      const expectedPaths = <String>[
        'match /users/{userId}',
        'match /users/{userId}/appointments/{appointmentId}',
        'match /users/{userId}/medical_records/{recordId}',
        'match /users/{userId}/medical_profile/{docId}',
        'match /users/{userId}/prescriptions/{prescriptionId}',
        'match /users/{userId}/diet_exercise_preferences/{docId}',
        'match /users/{userId}/water_intake/{date}',
        'match /users/{userId}/workouts/{date}',
        'match /users/{userId}/daily_activity/{date}',
      ];

      for (final path in expectedPaths) {
        expect(rules, contains(path), reason: 'missing rule for $path');
      }
    });
  });
}