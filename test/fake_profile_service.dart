import 'package:healthcare_app/features/profile/models/user_profile.dart';
import 'package:healthcare_app/features/profile/services/profile_service.dart';

/// A fake [ProfileService] for widget tests that avoids the real Firestore SDK.
class FakeProfileService extends ProfileService {
  FakeProfileService({this.profile});

  /// The profile to return from [getProfile]. Null simulates a missing
  /// Firestore document (no profile created yet).
  UserProfile? profile;

  /// The uid of the most recent call, so tests can verify the authenticated
  /// Firebase UID is the one used to build the user-scoped Firestore path.
  String? lastRequestedUid;

  /// When set, every call throws this error (for example a simulated
  /// permission-denied) instead of succeeding.
  Object? failure;

  @override
  Future<UserProfile?> getProfile(String uid) async {
    lastRequestedUid = uid;
    if (failure != null) throw failure!;
    return profile;
  }

  @override
  Future<void> createProfile(UserProfile newProfile) async {
    lastRequestedUid = newProfile.uid;
    if (failure != null) throw failure!;
    profile = newProfile;
  }

  @override
  Future<void> updateProfile(UserProfile newProfile) async {
    lastRequestedUid = newProfile.uid;
    if (failure != null) throw failure!;
    profile = newProfile;
  }
}
