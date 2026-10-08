import 'package:cloud_firestore/cloud_firestore.dart';
import 'medical_record_category.dart';

/// A single EHR medical record persisted in Firestore.
///
/// Records live under `users/{userId}/medical_records/{recordId}` and are
/// strictly scoped to the authenticated user. Each record carries stable ids,
/// explicit user ownership and timestamps so future phases (prescriptions,
/// QR sharing) can extend it without structural changes.
class MedicalRecord {
  final String id;
  final String userId;
  final String title;
  final MedicalRecordCategory category;
  final String description;
  final DateTime date;
  final String doctorName;
  final String hospitalName;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicalRecord({
    required this.id,
    required this.userId,
    required this.title,
    this.category = MedicalRecordCategory.general,
    this.description = '',
    required this.date,
    this.doctorName = '',
    this.hospitalName = '',
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  factory MedicalRecord.fromMap(String id, Map<String, dynamic> map) {
    return MedicalRecord(
      id: id,
      userId: (map['userId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      category: MedicalRecordCategory.parse(map['category'] as String?),
      description: (map['description'] as String?) ?? '',
      date: _parseDate(map['date']) ?? DateTime.now(),
      doctorName: (map['doctorName'] as String?) ?? '',
      hospitalName: (map['hospitalName'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final map = <String, dynamic>{
      'userId': userId,
      'title': title,
      'category': category.name,
      'description': description,
      'date': Timestamp.fromDate(date),
      'doctorName': doctorName,
      'hospitalName': hospitalName,
      'notes': notes,
    };
    if (includeTimestamps) {
      final now = Timestamp.now();
      map['createdAt'] = now;
      map['updatedAt'] = now;
    }
    return map;
  }

  MedicalRecord copyWith({
    String? id,
    String? userId,
    String? title,
    MedicalRecordCategory? category,
    String? description,
    DateTime? date,
    String? doctorName,
    String? hospitalName,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      doctorName: doctorName ?? this.doctorName,
      hospitalName: hospitalName ?? this.hospitalName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}