import 'package:healthcare_app/features/prescriptions/models/models.dart';
import 'package:healthcare_app/features/prescriptions/services/prescription_service.dart';

/// An in-memory fake [PrescriptionService] for unit and widget tests that
/// avoids the real Firestore SDK.
class FakePrescriptionService extends PrescriptionService {
  FakePrescriptionService({List<Prescription> initial = const []})
      : _prescriptions = List.of(initial);

  final List<Prescription> _prescriptions;

  @override
  Future<List<Prescription>> getPrescriptions(String userId) async {
    return _prescriptions.where((p) => p.userId == userId).toList()
      ..sort((a, b) => b.prescriptionDate.compareTo(a.prescriptionDate));
  }

  @override
  Future<Prescription?> getPrescription(
      String userId, String prescriptionId) async {
    for (final p in _prescriptions) {
      if (p.id == prescriptionId && p.userId == userId) return p;
    }
    return null;
  }

  @override
  Future<Prescription> createPrescription(Prescription prescription) async {
    final saved = prescription.copyWith(id: 'prescription-${_prescriptions.length + 1}');
    _prescriptions.add(saved);
    return saved;
  }

  @override
  Future<void> updatePrescription(Prescription prescription) async {
    final index = _prescriptions.indexWhere((p) => p.id == prescription.id);
    if (index != -1) {
      _prescriptions[index] = prescription.copyWith(updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> deletePrescription(String userId, String prescriptionId) async {
    _prescriptions
        .removeWhere((p) => p.id == prescriptionId && p.userId == userId);
  }
}