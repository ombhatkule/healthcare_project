import 'package:cloud_firestore/cloud_firestore.dart';
import 'past_surgery.dart';

/// The user's structured "Medical Information" profile.
///
/// Stored as a single document at `users/{userId}/medical_profile`. Holds
/// blood group, allergies, existing conditions, family history and past
/// surgeries. All fields are optional so users never have to enter data they
/// do not know.
class MedicalProfile {
  final String userId;
  final String? bloodGroup;
  final List<String> allergies;
  final List<String> conditions;
  final String? familyHistory;
  final List<PastSurgery> pastSurgeries;
  final DateTime? updatedAt;

  const MedicalProfile({
    required this.userId,
    this.bloodGroup,
    this.allergies = const [],
    this.conditions = const [],
    this.familyHistory,
    this.pastSurgeries = const [],
    this.updatedAt,
  });

  /// Whether any medical information has been recorded yet.
  bool get isEmpty =>
      bloodGroup == null &&
      allergies.isEmpty &&
      conditions.isEmpty &&
      familyHistory == null &&
      pastSurgeries.isEmpty;

  factory MedicalProfile.fromMap(String uid, Map<String, dynamic> map) {
    return MedicalProfile(
      userId: uid,
      bloodGroup: map['bloodGroup'] as String?,
      allergies: _parseStringList(map['allergies']),
      conditions: _parseStringList(map['conditions']),
      familyHistory: map['familyHistory'] as String?,
      pastSurgeries: _parseSurgeries(map['pastSurgeries']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final map = <String, dynamic>{
      'userId': userId,
      'allergies': allergies,
      'conditions': conditions,
      'pastSurgeries':
          pastSurgeries.map((s) => s.toMap()).toList(growable: false),
    };
    if (bloodGroup != null) map['bloodGroup'] = bloodGroup;
    if (familyHistory != null) map['familyHistory'] = familyHistory;
    if (includeTimestamps || updatedAt != null) {
      map['updatedAt'] = updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : Timestamp.now();
    }
    return map;
  }

  MedicalProfile copyWith({
    String? userId,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? conditions,
    String? familyHistory,
    List<PastSurgery>? pastSurgeries,
    DateTime? updatedAt,
  }) {
    return MedicalProfile(
      userId: userId ?? this.userId,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      familyHistory: familyHistory ?? this.familyHistory,
      pastSurgeries: pastSurgeries ?? this.pastSurgeries,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }

  static List<PastSurgery> _parseSurgeries(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((m) => PastSurgery.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }
    return const [];
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}