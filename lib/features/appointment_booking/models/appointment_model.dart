import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/enums/appointment_status.dart';

/// Represents a doctor appointment persisted in Firestore.
///
/// Stored under `users/{userId}/appointments/{appointmentId}`.
class AppointmentModel {
  final String id;
  final String userId;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String hospital;
  final String location;
  final DateTime appointmentDate;
  final String appointmentTime;
  final AppointmentStatus status;
  final String reasonForVisit;
  final String notes;
  final int consultationFee;
  final DateTime createdAt;

  const AppointmentModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.hospital,
    required this.location,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.reasonForVisit = '',
    this.notes = '',
    this.consultationFee = 0,
    required this.createdAt,
  });

  /// Whether this appointment is considered "upcoming".
  bool get isUpcoming =>
      status == AppointmentStatus.confirmed ||
      status == AppointmentStatus.pending;

  /// A short label for the appointment status.
  String get statusLabel => switch (status) {
        AppointmentStatus.pending => 'Pending',
        AppointmentStatus.confirmed => 'Confirmed',
        AppointmentStatus.completed => 'Completed',
        AppointmentStatus.cancelled => 'Cancelled',
      };

  /// A short label for the appointment type (used by dashboard card).
  String get type => 'Consultation';

  /// Lightweight time value for backward compatibility with dashboard widgets.
  TimeOfDayValue get time {
    final parts = appointmentTime.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final isPm = appointmentTime.toUpperCase().contains('PM');
      int hour24 = h;
      if (isPm && h != 12) hour24 = h + 12;
      if (!isPm && h == 12) hour24 = 0;
      return TimeOfDayValue(hour: hour24, minute: m);
    }
    return const TimeOfDayValue(hour: 0, minute: 0);
  }

  /// Create from Firestore document.
  factory AppointmentModel.fromMap(String id, Map<String, dynamic> map) {
    return AppointmentModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      doctorId: map['doctorId'] as String? ?? '',
      doctorName: map['doctorName'] as String? ?? '',
      specialty: map['specialty'] as String? ?? '',
      hospital: map['hospital'] as String? ?? '',
      location: map['location'] as String? ?? '',
      appointmentDate: (map['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appointmentTime: map['appointmentTime'] as String? ?? '',
      status: _parseStatus(map['status'] as String?),
      reasonForVisit: map['reasonForVisit'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      consultationFee: (map['consultationFee'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'specialty': specialty,
      'hospital': hospital,
      'location': location,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'appointmentTime': appointmentTime,
      'status': status.name,
      'reasonForVisit': reasonForVisit,
      'notes': notes,
      'consultationFee': consultationFee,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with modified fields.
  AppointmentModel copyWith({
    String? id,
    String? userId,
    String? doctorId,
    String? doctorName,
    String? specialty,
    String? hospital,
    String? location,
    DateTime? appointmentDate,
    String? appointmentTime,
    AppointmentStatus? status,
    String? reasonForVisit,
    String? notes,
    int? consultationFee,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      hospital: hospital ?? this.hospital,
      location: location ?? this.location,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      status: status ?? this.status,
      reasonForVisit: reasonForVisit ?? this.reasonForVisit,
      notes: notes ?? this.notes,
      consultationFee: consultationFee ?? this.consultationFee,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static AppointmentStatus _parseStatus(String? value) {
    if (value == null) return AppointmentStatus.pending;
    return AppointmentStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => AppointmentStatus.pending,
    );
  }
}

/// A lightweight stand-in for a time value that avoids importing the
/// Material [TimeOfDay] type into a pure model file.
class TimeOfDayValue {
  final int hour;
  final int minute;

  const TimeOfDayValue({required this.hour, required this.minute});

  /// Formatted as e.g. "09:30 AM".
  String get formatted {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final h = h12.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}
