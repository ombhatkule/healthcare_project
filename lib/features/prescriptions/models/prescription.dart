import 'package:cloud_firestore/cloud_firestore.dart';
import 'medicine.dart';
import 'prescription_status.dart';

/// A prescription record persisted in Firestore.
///
/// Prescriptions live under `users/{userId}/prescriptions/{prescriptionId}`
/// and are strictly scoped to the authenticated user. The prescription stores
/// doctor snapshot information (name/specialty/hospital) so historical records
/// remain understandable even if a doctor's profile later changes. It is a
/// record of an existing prescription — never an AI/ML-generated prescription.
class Prescription {
  final String id;
  final String userId;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String hospitalName;
  final String appointmentId;
  final DateTime prescriptionDate;
  final String diagnosisOrCondition;
  final List<Medicine> medicines;
  final String notes;
  final PrescriptionStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Prescription({
    required this.id,
    required this.userId,
    this.doctorId = '',
    this.doctorName = '',
    this.doctorSpecialty = '',
    this.hospitalName = '',
    this.appointmentId = '',
    required this.prescriptionDate,
    this.diagnosisOrCondition = '',
    this.medicines = const [],
    this.notes = '',
    this.status = PrescriptionStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  /// Number of medicines on this prescription.
  int get medicineCount => medicines.length;

  factory Prescription.fromMap(String id, Map<String, dynamic> map) {
    return Prescription(
      id: id,
      userId: (map['userId'] as String?) ?? '',
      doctorId: (map['doctorId'] as String?) ?? '',
      doctorName: (map['doctorName'] as String?) ?? '',
      doctorSpecialty: (map['doctorSpecialty'] as String?) ?? '',
      hospitalName: (map['hospitalName'] as String?) ?? '',
      appointmentId: (map['appointmentId'] as String?) ?? '',
      prescriptionDate: _parseDate(map['prescriptionDate']) ?? DateTime.now(),
      diagnosisOrCondition: (map['diagnosisOrCondition'] as String?) ?? '',
      medicines: _parseMedicines(map['medicines']),
      notes: (map['notes'] as String?) ?? '',
      status: PrescriptionStatus.parse(map['status'] as String?),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({bool includeTimestamps = false}) {
    final map = <String, dynamic>{
      'userId': userId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'hospitalName': hospitalName,
      'appointmentId': appointmentId,
      'prescriptionDate': Timestamp.fromDate(prescriptionDate),
      'diagnosisOrCondition': diagnosisOrCondition,
      'medicines': medicines.map((m) => m.toMap()).toList(),
      'notes': notes,
      'status': status.name,
    };
    if (includeTimestamps) {
      final now = Timestamp.now();
      map['createdAt'] = now;
      map['updatedAt'] = now;
    }
    return map;
  }

  Prescription copyWith({
    String? id,
    String? userId,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    String? hospitalName,
    String? appointmentId,
    DateTime? prescriptionDate,
    String? diagnosisOrCondition,
    List<Medicine>? medicines,
    String? notes,
    PrescriptionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Prescription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      hospitalName: hospitalName ?? this.hospitalName,
      appointmentId: appointmentId ?? this.appointmentId,
      prescriptionDate: prescriptionDate ?? this.prescriptionDate,
      diagnosisOrCondition: diagnosisOrCondition ?? this.diagnosisOrCondition,
      medicines: medicines ?? this.medicines,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<Medicine> _parseMedicines(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Medicine.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}