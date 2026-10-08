import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_app/features/doctor_recommendation/models/disease_specialty_mapping.dart';
import 'package:healthcare_app/features/doctor_recommendation/models/models.dart';

/// Phase 9: disease -> specialty mapping tests.
///
/// The mapping must cover the exact 41 classes produced by the experimental
/// Phase 7 model, resolve them (falling back to General Physician where a
/// specific specialty is not reliable), and be case/separator-insensitive.
void main() {
  // Exact 41 class labels produced by experimental_disease_model.joblib.
  const modelClasses = [
    'AIDS',
    'Acne',
    'Alcoholic Hepatitis',
    'Allergy',
    'Arthritis',
    'Bronchial Asthma',
    'Cervical Spondylosis',
    'Chickenpox',
    'Chronic Cholestasis',
    'Common Cold',
    'Dengue',
    'Diabetes',
    'Dimorphic Hemmorhoids (piles)',
    'Drug Reaction',
    'Fungal Infection',
    'GERD',
    'Gastroenteritis',
    'Heart Attack',
    'Hepatitis A',
    'Hepatitis B',
    'Hepatitis C',
    'Hepatitis D',
    'Hepatitis E',
    'Hypertension',
    'Hyperthyroidism',
    'Hypoglycemia',
    'Hypothyroidism',
    'Impetigo',
    'Jaundice',
    'Malaria',
    'Migraine',
    'Osteoarthritis',
    'Paralysis (brain hemorrhage)',
    'Peptic Ulcer Disease',
    'Pneumonia',
    'Psoriasis',
    'Tuberculosis',
    'Typhoid',
    'Urinary Tract Infection',
    'Varicose Veins',
    'Vertigo',
  ];

  group('DiseaseSpecialtyMapping', () {
    test('every one of the 41 model classes resolves to a non-empty specialty',
        () {
      for (final disease in modelClasses) {
        final specialty = DiseaseSpecialtyMapping.recommendedSpecialty(disease);
        expect(specialty, isNotEmpty, reason: 'missing mapping for $disease');
        expect(Specialties.all, contains(specialty),
            reason: 'unsupported specialty for $disease: $specialty');
      }
    });

    test('maps predicted conditions to recognized specialties', () {
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('Diabetes'),
          Specialties.endocrinologist);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('Bronchial Asthma'),
          Specialties.pulmonologist);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('Heart Attack'),
          Specialties.cardiologist);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('Migraine'),
          Specialties.neurologist);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('Acne'),
          Specialties.dermatologist);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('GERD'),
          Specialties.gastroenterologist);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('Osteoarthritis'),
          Specialties.orthopedic);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('Tuberculosis'),
          Specialties.pulmonologist);
    });

    test('falls back to General Physician for unmapped/ambiguous conditions',
        () {
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('Common Cold'),
          Specialties.generalPhysician);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('Malaria'),
          Specialties.generalPhysician);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('Typhoid'),
          Specialties.generalPhysician);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('Varicose Veins'),
          Specialties.generalPhysician);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty(null),
          Specialties.generalPhysician);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty(''),
          Specialties.generalPhysician);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('   '),
          Specialties.generalPhysician);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('TotallyUnknown'),
          Specialties.generalPhysician);
    });

    test('lookup is case-insensitive and tolerant of separators', () {
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('diabetes'),
          Specialties.endocrinologist);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('  DIABETES  '),
          Specialties.endocrinologist);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('Heart_Attack'),
          Specialties.cardiologist);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('chronic_kidney_disease'),
          Specialties.nephrologist);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('Type2_Diabetes'),
          Specialties.endocrinologist);
      expect(DiseaseSpecialtyMapping.recommendedSpecialty('Asthma'),
          Specialties.pulmonologist);
    });

    test('hasExplicitMapping distinguishes specific from fallback', () {
      expect(DiseaseSpecialtyMapping.hasExplicitMapping('Migraine'), isTrue);
      expect(DiseaseSpecialtyMapping.hasExplicitMapping('Common Cold'),
          isFalse);
      expect(DiseaseSpecialtyMapping.hasExplicitMapping(null), isFalse);
    });

    test('supported specialty catalog contains the mapped specialties', () {
      for (final disease in modelClasses) {
        expect(Specialties.all,
            contains(DiseaseSpecialtyMapping.recommendedSpecialty(disease)));
      }
    });
  });
}