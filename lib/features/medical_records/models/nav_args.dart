import 'medical_record.dart';
import 'medical_record_category.dart';
import 'past_surgery.dart';

/// Arguments for the add/edit medical record form.
class MedicalRecordFormArguments {
  /// When editing, the existing record to load. When null the form creates
  /// a new record.
  final MedicalRecord? record;

  /// Category preselected for a new record (used by list screens).
  final MedicalRecordCategory? initialCategory;

  const MedicalRecordFormArguments({this.record, this.initialCategory});
}

/// Arguments for the medical record details screen.
class MedicalRecordDetailsArguments {
  final String recordId;

  const MedicalRecordDetailsArguments({required this.recordId});
}

/// Arguments for the category-filtered record list screen.
class MedicalRecordsListArguments {
  /// Title shown in the app bar, e.g. "Medical History".
  final String title;

  /// Identifier of the collection shown: 'history' or 'visits'.
  final String collection;

  const MedicalRecordsListArguments({
    required this.title,
    required this.collection,
  });
}

/// Arguments for the add/edit past-surgery form.
class SurgeryFormArguments {
  /// When editing, the existing surgery to load; null adds a new one.
  final PastSurgery? surgery;

  const SurgeryFormArguments({this.surgery});
}