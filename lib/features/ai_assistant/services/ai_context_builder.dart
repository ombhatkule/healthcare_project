import '../../../core/utils/app_utils.dart' as utils;
import '../../appointment_booking/models/appointment_model.dart';
import '../../medical_records/models/medical_profile.dart';
import '../../medical_records/models/medical_record.dart';
import '../../prescriptions/models/prescription.dart';

/// Builds the minimal, user-scoped context sent to the AI assistant.
///
/// Medical data is sensitive: only the minimum information required for the
/// current question is included, and everything belongs to the authenticated
/// user. No other user's data is ever reachable here.
class AiContextBuilder {
  const AiContextBuilder();

  /// Builds a structured context map from the authenticated user's data.
  ///
  /// [records], [prescriptions] and [appointments] are already filtered to the
  /// current user by the caller (retrieved through the user-scoped services).
  Map<String, dynamic> buildContext({
    required String userId,
    List<MedicalRecord>? records,
    MedicalProfile? medicalProfile,
    List<Prescription>? prescriptions,
    List<AppointmentModel>? appointments,
  }) {
    return {
      'user': {
        'id': userId,
      },
      'medicalProfile': _profileContext(medicalProfile),
      'medicalRecords': _recordsContext(records),
      'prescriptions': _prescriptionsContext(prescriptions),
      'appointments': _appointmentsContext(appointments),
    };
  }

  Map<String, dynamic>? _profileContext(MedicalProfile? profile) {
    if (profile == null || profile.isEmpty) return null;
    return {
      if (profile.bloodGroup != null) 'bloodGroup': profile.bloodGroup,
      if (profile.allergies.isNotEmpty) 'allergies': profile.allergies,
      if (profile.conditions.isNotEmpty) 'conditions': profile.conditions,
      if (profile.familyHistory != null)
        'familyHistory': profile.familyHistory,
      if (profile.pastSurgeries.isNotEmpty)
        'pastSurgeries': profile.pastSurgeries
            .map(
              (s) => {
                'name': s.name,
                if (s.year != null) 'year': s.year,
                if (s.hospital.isNotEmpty) 'hospital': s.hospital,
              },
            )
            .toList(),
    };
  }

  List<Map<String, dynamic>>? _recordsContext(List<MedicalRecord>? records) {
    if (records == null || records.isEmpty) return null;
    // Only the essential fields are sent; free-form sensitive notes are
    // limited to the most recent records to keep the payload minimal.
    return records.take(10).map((r) {
      return {
        'title': r.title,
        'category': r.category.name,
        'description': r.description,
        'date': utils.AppUtils.formatDate(r.date),
        if (r.doctorName.isNotEmpty) 'doctor': r.doctorName,
        if (r.hospitalName.isNotEmpty) 'hospital': r.hospitalName,
        if (r.notes.isNotEmpty) 'notes': r.notes,
      };
    }).toList();
  }

  List<Map<String, dynamic>>? _prescriptionsContext(
      List<Prescription>? prescriptions) {
    if (prescriptions == null || prescriptions.isEmpty) return null;
    return prescriptions.take(5).map((p) {
      return {
        'date': utils.AppUtils.formatDate(p.prescriptionDate),
        if (p.doctorName.isNotEmpty) 'doctor': p.doctorName,
        if (p.doctorSpecialty.isNotEmpty) 'specialty': p.doctorSpecialty,
        if (p.hospitalName.isNotEmpty) 'hospital': p.hospitalName,
        if (p.diagnosisOrCondition.isNotEmpty)
          'diagnosisOrCondition': p.diagnosisOrCondition,
        'medicines': p.medicines
            .map(
              (m) => {
                'name': m.medicineName,
                if (m.dosage.isNotEmpty) 'dosage': m.dosage,
                if (m.frequency.isNotEmpty) 'frequency': m.frequency,
                if (m.duration.isNotEmpty)
                  'duration': m.duration,
                if (m.instructions.isNotEmpty)
                  'instructions': m.instructions,
              },
            )
            .toList(),
      };
    }).toList();
  }

  List<Map<String, dynamic>>? _appointmentsContext(
      List<AppointmentModel>? appointments) {
    if (appointments == null || appointments.isEmpty) return null;
    return appointments.take(5).map((a) {
      return {
        'date': utils.AppUtils.formatDate(a.appointmentDate),
        'time': a.appointmentTime,
        'doctor': a.doctorName,
        if (a.specialty.isNotEmpty) 'specialty': a.specialty,
        if (a.hospital.isNotEmpty) 'hospital': a.hospital,
        if (a.location.isNotEmpty) 'location': a.location,
        'status': a.statusLabel.toLowerCase(),
      };
    }).toList();
  }
}