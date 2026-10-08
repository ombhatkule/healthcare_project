import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/prescriptions/models/models.dart';

void main() {
  group('Medicine', () {
    test('toMap/fromMap round-trips all fields', () {
      const medicine = Medicine(
        id: 'm1',
        medicineName: 'Paracetamol',
        dosage: '500 mg',
        frequency: 'Twice daily',
        duration: '5 days',
        instructions: 'After meals',
      );
      final decoded = Medicine.fromMap(medicine.toMap());
      expect(decoded.id, 'm1');
      expect(decoded.medicineName, 'Paracetamol');
      expect(decoded.dosage, '500 mg');
      expect(decoded.frequency, 'Twice daily');
      expect(decoded.duration, '5 days');
      expect(decoded.instructions, 'After meals');
    });

    test('copyWith overrides only provided fields', () {
      const medicine = Medicine(id: 'm1', medicineName: 'A');
      final updated = medicine.copyWith(dosage: '10 mg');
      expect(updated.id, 'm1');
      expect(updated.medicineName, 'A');
      expect(updated.dosage, '10 mg');
    });
  });

  group('PrescriptionStatus', () {
    test('label is human readable', () {
      expect(PrescriptionStatus.active.label, 'Active');
      expect(PrescriptionStatus.completed.label, 'Completed');
    });

    test('parse falls back to active', () {
      expect(PrescriptionStatus.parse('completed'), PrescriptionStatus.completed);
      expect(PrescriptionStatus.parse('active'), PrescriptionStatus.active);
      expect(PrescriptionStatus.parse('weird'), PrescriptionStatus.active);
      expect(PrescriptionStatus.parse(null), PrescriptionStatus.active);
    });
  });

  group('Prescription', () {
    Prescription makePrescription({
      String id = 'p1',
      String userId = 'user-1',
      String doctorName = 'Dr. Test',
      PrescriptionStatus status = PrescriptionStatus.active,
      List<Medicine> medicines = const [],
    }) {
      return Prescription(
        id: id,
        userId: userId,
        doctorName: doctorName,
        prescriptionDate: DateTime(2026, 9, 11),
        medicines: medicines,
        status: status,
      );
    }

    test('toMap/fromMap round-trips basic fields', () {
      final prescription = makePrescription(
        doctorName: 'Dr. Smith',
        userId: 'user-9',
      );
      final decoded = Prescription.fromMap('p1', prescription.toMap());
      expect(decoded.id, 'p1');
      expect(decoded.userId, 'user-9');
      expect(decoded.doctorName, 'Dr. Smith');
      expect(decoded.status, PrescriptionStatus.active);
      expect(decoded.prescriptionDate, DateTime(2026, 9, 11));
    });

    test('toMap includes medicines as structured maps', () {
      const medicine = Medicine(
        id: 'm1',
        medicineName: 'Aspirin',
        dosage: '75 mg',
      );
      final prescription = makePrescription(medicines: const [medicine]);
      final map = prescription.toMap();
      final meds = map['medicines'] as List;
      expect(meds, hasLength(1));
      expect((meds.first as Map)['medicineName'], 'Aspirin');
      expect(map['status'], 'active');
    });

    test('medicineCount reflects the medicine list', () {
      final empty = makePrescription();
      final withMeds = makePrescription(
        medicines: const [
          Medicine(id: 'm1', medicineName: 'A'),
          Medicine(id: 'm2', medicineName: 'B'),
        ],
      );
      expect(empty.medicineCount, 0);
      expect(withMeds.medicineCount, 2);
    });

    test('fromMap handles completed status and free-text string fields', () {
      final map = makePrescription(status: PrescriptionStatus.completed)
          .toMap()
        ..['doctorName'] = 'Dr. Very Long Name That Must Be Preserved In Full';
      final decoded = Prescription.fromMap('p1', map);
      expect(decoded.status, PrescriptionStatus.completed);
      expect(decoded.doctorName, 'Dr. Very Long Name That Must Be Preserved In Full');
    });

    test('copyWith preserves id and updates editable fields', () {
      final original = makePrescription(doctorName: 'Dr. Old');
      final updated = original.copyWith(
        doctorName: 'Dr. New',
        diagnosisOrCondition: 'Flu',
      );
      expect(updated.id, 'p1');
      expect(updated.doctorName, 'Dr. New');
      expect(updated.diagnosisOrCondition, 'Flu');
      expect(updated.status, PrescriptionStatus.active);
    });
  });
}