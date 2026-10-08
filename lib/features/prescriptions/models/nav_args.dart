import 'medicine.dart';
import 'prescription.dart';

/// Arguments for the add/edit prescription form.
class PrescriptionFormArguments {
  /// When editing, the existing prescription to load. When null the form
  /// creates a new prescription.
  final Prescription? prescription;

  /// Optional doctor id pre-selected from another flow (e.g. appointment).
  final String? doctorId;

  /// Optional appointment id the prescription may be associated with.
  final String? appointmentId;

  const PrescriptionFormArguments({
    this.prescription,
    this.doctorId,
    this.appointmentId,
  });
}

/// Arguments for the prescription details screen.
class PrescriptionDetailsArguments {
  final String prescriptionId;

  const PrescriptionDetailsArguments({required this.prescriptionId});
}

/// Arguments for the add/edit medicine form.
class MedicineFormArguments {
  /// When editing, the existing medicine to load. When null the form adds a
  /// new medicine.
  final Medicine? medicine;

  const MedicineFormArguments({this.medicine});
}