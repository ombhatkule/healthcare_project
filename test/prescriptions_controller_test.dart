import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/prescriptions/models/models.dart';
import 'package:healthcare_app/features/prescriptions/presentation/providers/prescriptions_controller.dart';
import 'package:healthcare_app/features/prescriptions/services/prescription_service.dart';
import 'fake_prescription_service.dart';

void main() {
  Prescription makePrescription({
    String? id,
    String userId = 'user-1',
    String doctorName = 'Dr. Test',
    PrescriptionStatus status = PrescriptionStatus.active,
    DateTime? date,
    List<Medicine> medicines = const [],
  }) {
    return Prescription(
      id: id ?? 'p-1',
      userId: userId,
      doctorName: doctorName,
      doctorSpecialty: 'General',
      prescriptionDate: date ?? DateTime(2026, 9, 11),
      medicines: medicines,
      status: status,
    );
  }

  group('PrescriptionsController', () {
    test('loadAll populates prescriptions and resets loading', () async {
      final service = FakePrescriptionService(
        initial: [
          makePrescription(id: 'p1', doctorName: 'Dr. A'),
          makePrescription(
            id: 'p2',
            doctorName: 'Dr. B',
            status: PrescriptionStatus.completed,
          ),
        ],
      );
      final controller = PrescriptionsController(service);
      await controller.loadAll('user-1');

      expect(controller.prescriptions.length, 2);
      expect(controller.activePrescriptions.length, 1);
      expect(controller.previousPrescriptions.length, 1);
      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isFalse);
    });

    test('loadAll filters out other users', () async {
      final service = FakePrescriptionService(
        initial: [
          makePrescription(id: 'p1', userId: 'user-1'),
          makePrescription(id: 'p2', userId: 'user-2'),
        ],
      );
      final controller = PrescriptionsController(service);
      await controller.loadAll('user-1');
      expect(controller.prescriptions.length, 1);
    });

    test('createPrescription adds to list', () async {
      final service = FakePrescriptionService();
      final controller = PrescriptionsController(service);
      await controller.loadAll('user-1');

      final ok = await controller.createPrescription(makePrescription());
      expect(ok, isTrue);
      expect(controller.prescriptions.length, 1);
      expect(controller.prescriptions.first.id, isNotEmpty);
    });

    test('updatePrescription replaces in place without duplicate', () async {
      final existing =
          makePrescription(id: 'p1', doctorName: 'Dr. Old');
      final service = FakePrescriptionService(initial: [existing]);
      final controller = PrescriptionsController(service);
      await controller.loadAll('user-1');

      final updated =
          controller.prescriptions.first.copyWith(doctorName: 'Dr. New');
      final ok = await controller.updatePrescription(updated);
      expect(ok, isTrue);
      expect(controller.prescriptions.length, 1);
      expect(controller.prescriptions.first.doctorName, 'Dr. New');
    });

    test('deletePrescription removes from list', () async {
      final existing = makePrescription(id: 'p1');
      final service = FakePrescriptionService(initial: [existing]);
      final controller = PrescriptionsController(service);
      await controller.loadAll('user-1');

      final ok = await controller.deletePrescription('user-1', 'p1');
      expect(ok, isTrue);
      expect(controller.prescriptions, isEmpty);
    });

    test('search filters by doctor name and medicine name', () async {
      const paracetamol = Medicine(
        id: 'm1',
        medicineName: 'Paracetamol',
        frequency: 'Twice daily',
      );
      final service = FakePrescriptionService(
        initial: [
          makePrescription(id: 'p1', doctorName: 'Dr. Smith'),
          makePrescription(
            id: 'p2',
            doctorName: 'Dr. Jones',
            medicines: const [paracetamol],
          ),
        ],
      );
      final controller = PrescriptionsController(service);
      await controller.loadAll('user-1');

      controller.setSearchQuery('smith');
      expect(controller.filteredPrescriptions.length, 1);
      expect(controller.filteredPrescriptions.first.id, 'p1');

      controller.setSearchQuery('paracetamol');
      expect(controller.filteredPrescriptions.length, 1);
      expect(controller.filteredPrescriptions.first.id, 'p2');

      controller.setSearchQuery('');
      expect(controller.filteredPrescriptions.length, 2);
    });

    test('error message is set on service failure', () async {
      final controller = PrescriptionsController(_FailingService());
      await controller.loadAll('user-1');
      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, contains('Unable to load'));
      expect(controller.isLoading, isFalse);
    });

    test('loadPrescription loads a single selected prescription', () async {
      final existing = makePrescription(id: 'p1');
      final service = FakePrescriptionService(initial: [existing]);
      final controller = PrescriptionsController(service);

      final found = await controller.loadPrescription('user-1', 'p1');
      expect(found, isTrue);
      expect(controller.selectedPrescription?.id, 'p1');

      final missing = await controller.loadPrescription('user-1', 'nope');
      expect(missing, isFalse);
    });
  });
}

class _FailingService extends PrescriptionService {
  @override
  Future<List<Prescription>> getPrescriptions(String userId) async {
    throw Exception('Firestore failure');
  }
}