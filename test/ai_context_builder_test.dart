import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/ai_assistant/services/ai_context_builder.dart';
import 'package:healthcare_app/features/appointment_booking/models/appointment_model.dart';
import 'package:healthcare_app/features/medical_records/models/medical_profile.dart';
import 'package:healthcare_app/features/medical_records/models/medical_record.dart';
import 'package:healthcare_app/features/medical_records/models/medical_record_category.dart';
import 'package:healthcare_app/features/medical_records/models/past_surgery.dart';
import 'package:healthcare_app/features/prescriptions/models/medicine.dart';
import 'package:healthcare_app/features/prescriptions/models/prescription.dart';
import 'package:healthcare_app/features/prescriptions/models/prescription_status.dart';
import 'package:healthcare_app/shared/enums/appointment_status.dart';

void main() {
  const builder = AiContextBuilder();

  group('buildContext', () {
    test('returns user id and null sections when no data is provided', () {
      final ctx = builder.buildContext(userId: 'user-A');
      expect((ctx['user'] as Map)['id'], 'user-A');
      expect(ctx['medicalProfile'], isNull);
      expect(ctx['medicalRecords'], isNull);
      expect(ctx['prescriptions'], isNull);
      expect(ctx['appointments'], isNull);
    });

    test('includes allergies, conditions and surgeries from the profile', () {
      final profile = MedicalProfile(
        userId: 'user-A',
        bloodGroup: 'O+',
        allergies: const ['Penicillin'],
        conditions: const ['Asthma'],
        pastSurgeries: const [
          PastSurgery(name: 'Appendectomy', year: 2019, hospital: 'City Care'),
        ],
      );
      final ctx = builder.buildContext(
        userId: 'user-A',
        medicalProfile: profile,
      );
      final profileCtx = ctx['medicalProfile'] as Map;
      expect(profileCtx['bloodGroup'], 'O+');
      expect(profileCtx['allergies'], ['Penicillin']);
      expect(profileCtx['conditions'], ['Asthma']);
      final surgeries = profileCtx['pastSurgeries'] as List;
      expect(surgeries, hasLength(1));
      expect((surgeries.first as Map)['name'], 'Appendectomy');
    });

    test('includes medical record essential fields', () {
      final record = MedicalRecord(
        id: 'r1',
        userId: 'user-A',
        title: 'Annual check-up',
        category: MedicalRecordCategory.doctorVisit,
        description: 'Routine health review',
        date: DateTime(2025, 6, 1),
        doctorName: 'Dr. Mehta',
      );
      final ctx = builder.buildContext(
        userId: 'user-A',
        records: [record],
      );
      final records = ctx['medicalRecords'] as List;
      final first = records.first as Map;
      expect(first['title'], 'Annual check-up');
      expect(first['category'], 'doctorVisit');
      expect(first['doctor'], 'Dr. Mehta');
      expect(first['date'], isNotEmpty);
    });

    test('includes prescription medicines without inventing data', () {
      final prescription = Prescription(
        id: 'p1',
        userId: 'user-A',
        doctorName: 'Dr. Rao',
        prescriptionDate: DateTime(2025, 6, 10),
        medicines: const [
          Medicine(
            medicineName: 'Paracetamol',
            dosage: '500 mg',
            frequency: 'twice daily',
            duration: '5 days',
          ),
        ],
        status: PrescriptionStatus.active,
      );
      final ctx = builder.buildContext(
        userId: 'user-A',
        prescriptions: [prescription],
      );
      final prescriptions = ctx['prescriptions'] as List;
      final first = prescriptions.first as Map;
      final medicines = first['medicines'] as List;
      expect(medicines, hasLength(1));
      final med = medicines.first as Map;
      expect(med['name'], 'Paracetamol');
      expect(med['dosage'], '500 mg');
      expect(med['frequency'], 'twice daily');
    });

    test('includes upcoming appointment information', () {
      final appointment = AppointmentModel(
        id: 'a1',
        userId: 'user-A',
        doctorId: 'd1',
        doctorName: 'Dr. Kapoor',
        specialty: 'Cardiology',
        hospital: 'Heart Institute',
        location: 'Mumbai',
        appointmentDate: DateTime(2025, 9, 20),
        appointmentTime: '10:30 AM',
        status: AppointmentStatus.confirmed,
        createdAt: DateTime(2025, 9, 1),
      );
      final ctx = builder.buildContext(
        userId: 'user-A',
        appointments: [appointment],
      );
      final appointments = ctx['appointments'] as List;
      final first = appointments.first as Map;
      expect(first['doctor'], 'Dr. Kapoor');
      expect(first['time'], '10:30 AM');
      expect(first['status'], 'confirmed');
      expect(first['date'], isNotEmpty);
    });

    test('limits records to the most relevant entries', () {
      final manyRecords = List.generate(
        15,
        (i) => MedicalRecord(
          id: 'r$i',
          userId: 'user-A',
          title: 'Record $i',
          date: DateTime(2025, 1, i + 1),
        ),
      );
      final ctx = builder.buildContext(userId: 'user-A', records: manyRecords);
      final records = ctx['medicalRecords'] as List;
      expect(records.length, lessThanOrEqualTo(10));
    });
  });
}