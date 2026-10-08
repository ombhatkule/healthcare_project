import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user's profile document stored in Firestore.
///
/// The document is keyed by the Firebase Authentication UID under the
/// `users/{uid}` path. This model intentionally only holds non-sensitive
/// profile fields — passwords and authentication credentials are never stored.
class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final num? height;
  final num? weight;
  final String? bloodGroup;
  final String? emergencyContact;
  final String? allergies;
  final String? profileImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.bloodGroup,
    this.emergencyContact,
    this.allergies,
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// A copy of this profile with [fullName] overridden by the Auth display
  /// name when available, so the UI never shows a hardcoded name.
  UserProfile copyWith({String? fullName}) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      gender: gender,
      height: height,
      weight: weight,
      bloodGroup: bloodGroup,
      emergencyContact: emergencyContact,
      allergies: allergies,
      profileImageUrl: profileImageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Builds a [UserProfile] from a Firestore document snapshot.
  /// Missing optional fields are handled safely (default to null / empty).
  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      fullName: (data['fullName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phoneNumber: data['phoneNumber'] as String?,
      dateOfBirth: _parseDate(data['dateOfBirth']),
      gender: data['gender'] as String?,
      height: data['height'] as num?,
      weight: data['weight'] as num?,
      bloodGroup: data['bloodGroup'] as String?,
      emergencyContact: data['emergencyContact'] as String?,
      allergies: data['allergies'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  /// Converts the profile to a map for Firestore writes.
  ///
  /// Only writable fields are persisted. Null values are never used to
  /// overwrite existing data — nulls are skipped during updates.
  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final map = <String, dynamic>{
      'fullName': fullName,
      'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (dateOfBirth != null) 'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
      if (gender != null) 'gender': gender,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (emergencyContact != null) 'emergencyContact': emergencyContact,
      if (allergies != null) 'allergies': allergies,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    };
    if (includeTimestamps) {
      final now = Timestamp.now();
      map['createdAt'] = now;
      map['updatedAt'] = now;
    }
    return map;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
