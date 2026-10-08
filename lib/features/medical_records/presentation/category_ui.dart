import 'package:flutter/material.dart';
import '../models/medical_record_category.dart';

/// Icon used to represent a [MedicalRecordCategory] across screens.
IconData medicalRecordCategoryIcon(MedicalRecordCategory category) {
  return switch (category) {
    MedicalRecordCategory.general => Icons.folder_outlined,
    MedicalRecordCategory.medicalHistory => Icons.history_edu_outlined,
    MedicalRecordCategory.surgery => Icons.medical_services_outlined,
    MedicalRecordCategory.doctorVisit => Icons.event_note_outlined,
    MedicalRecordCategory.labTest => Icons.science_outlined,
    MedicalRecordCategory.other => Icons.description_outlined,
  };
}