import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/diet_exercise/services/services.dart';
import 'package:healthcare_app/features/profile/services/profile_service.dart';

/// Verifies the exact Firestore paths the client builds for every user-scoped
/// document. Each path must be rooted at `users/{uid}` using the authenticated
/// Firebase UID, because that is precisely what the security rules
/// (`request.auth.uid == userId`) allow.
void main() {
  const uid = 'firebase-uid-123';

  group('user-scoped Firestore paths use the authenticated UID', () {
    test('profile document lives at users/{uid}', () {
      expect(ProfileService.userDocPath(uid), 'users/$uid');
    });

    test('wellness preferences live at '
        'users/{uid}/diet_exercise_preferences/preferences', () {
      expect(
        DietService.preferencesDocPath(uid),
        'users/$uid/diet_exercise_preferences/preferences',
      );
    });

    test('water intake lives at users/{uid}/water_intake/{date}', () {
      expect(
        ActivityTrackingService.waterDocPath(uid, '2026-10-07'),
        'users/$uid/water_intake/2026-10-07',
      );
    });

    test('completed exercises live at users/{uid}/workouts/{date}', () {
      expect(
        ExerciseService.workoutDocPath(uid, '2026-10-07'),
        'users/$uid/workouts/2026-10-07',
      );
    });

    test('manual activity lives at users/{uid}/daily_activity/{date}', () {
      expect(
        ActivityTrackingService.activityDocPath(uid, '2026-10-07'),
        'users/$uid/daily_activity/2026-10-07',
      );
    });

    test('different users never share a document path', () {
      expect(
        ProfileService.userDocPath('user-a'),
        isNot(ProfileService.userDocPath('user-b')),
      );
      expect(
        DietService.preferencesDocPath('user-a'),
        isNot(DietService.preferencesDocPath('user-b')),
      );
      expect(
        ExerciseService.workoutDocPath('user-a', '2026-10-07'),
        isNot(ExerciseService.workoutDocPath('user-b', '2026-10-07')),
      );
    });
  });
}