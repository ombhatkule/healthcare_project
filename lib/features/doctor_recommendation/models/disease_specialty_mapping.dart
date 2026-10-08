/// Canonical medical specialties used across the app.
///
/// Kept deliberately conservative: only well-recognized specialties are used
/// and unknown/unclear conditions fall back to [Specialties.generalPhysician].
abstract final class Specialties {
  static const String generalPhysician = 'General Physician';
  static const String cardiologist = 'Cardiologist';
  static const String dermatologist = 'Dermatologist';
  static const String endocrinologist = 'Endocrinologist';
  static const String gastroenterologist = 'Gastroenterologist';
  static const String nephrologist = 'Nephrologist';
  static const String neurologist = 'Neurologist';
  static const String orthopedic = 'Orthopedic';
  static const String pulmonologist = 'Pulmonologist';
  static const String ophthalmologist = 'Ophthalmologist';

  /// Every specialty the app can recommend/browse, in display order.
  static const List<String> all = [
    generalPhysician,
    cardiologist,
    pulmonologist,
    gastroenterologist,
    dermatologist,
    neurologist,
    orthopedic,
    endocrinologist,
    nephrologist,
    ophthalmologist,
  ];
}

/// Maps predicted conditions (disease names) to a recommended specialty.
///
/// The primary keys come from the 41 disease classes produced by the
/// experimental ML model (Phase 7). Additional common aliases are included so
/// the mapping tolerates spelling variants from any future backend.
///
/// Any disease without an explicit, reliable mapping falls back to the
/// [Specialties.generalPhysician] default. Lookup is case-insensitive,
/// whitespace-normalized and tolerant of `_`/`-` separators.
abstract final class DiseaseSpecialtyMapping {
  static const String fallbackSpecialty = Specialties.generalPhysician;

  /// Disease display name (lowercase, single spaces) -> specialty.
  static const Map<String, String> _diseaseToSpecialty = {
    // --- 41 classes of the experimental model ---
    'aids': Specialties.generalPhysician,
    'acne': Specialties.dermatologist,
    'alcoholic hepatitis': Specialties.gastroenterologist,
    'allergy': Specialties.generalPhysician,
    'arthritis': Specialties.orthopedic,
    'bronchial asthma': Specialties.pulmonologist,
    'cervical spondylosis': Specialties.orthopedic,
    'chickenpox': Specialties.generalPhysician,
    'chronic cholestasis': Specialties.gastroenterologist,
    'common cold': Specialties.generalPhysician,
    'dengue': Specialties.generalPhysician,
    'diabetes': Specialties.endocrinologist,
    'dimorphic hemmorhoids piles': Specialties.generalPhysician,
    'drug reaction': Specialties.dermatologist,
    'fungal infection': Specialties.dermatologist,
    'gerd': Specialties.gastroenterologist,
    'gastroenteritis': Specialties.gastroenterologist,
    'heart attack': Specialties.cardiologist,
    'hepatitis a': Specialties.gastroenterologist,
    'hepatitis b': Specialties.gastroenterologist,
    'hepatitis c': Specialties.gastroenterologist,
    'hepatitis d': Specialties.gastroenterologist,
    'hepatitis e': Specialties.gastroenterologist,
    'hypertension': Specialties.cardiologist,
    'hyperthyroidism': Specialties.endocrinologist,
    'hypoglycemia': Specialties.endocrinologist,
    'hypothyroidism': Specialties.endocrinologist,
    'impetigo': Specialties.dermatologist,
    'jaundice': Specialties.gastroenterologist,
    'malaria': Specialties.generalPhysician,
    'migraine': Specialties.neurologist,
    'osteoarthritis': Specialties.orthopedic,
    'paralysis brain hemorrhage': Specialties.neurologist,
    'peptic ulcer disease': Specialties.gastroenterologist,
    'pneumonia': Specialties.pulmonologist,
    'psoriasis': Specialties.dermatologist,
    'tuberculosis': Specialties.pulmonologist,
    'typhoid': Specialties.generalPhysician,
    'urinary tract infection': Specialties.generalPhysician,
    'varicose veins': Specialties.generalPhysician,
    'vertigo': Specialties.neurologist,

    // --- Common aliases / other conditions (future-proofing) ---
    'asthma': Specialties.pulmonologist,
    'coronary artery disease': Specialties.cardiologist,
    'type2 diabetes': Specialties.endocrinologist,
    'type 2 diabetes': Specialties.endocrinologist,
    'chronic kidney disease': Specialties.nephrologist,
    'irritable bowel syndrome': Specialties.gastroenterologist,
    'flu': Specialties.generalPhysician,
    'flu with fever': Specialties.generalPhysician,
    'cataracts': Specialties.ophthalmologist,
  };

  /// Returns the recommended specialty for [disease].
  ///
  /// Returns [fallbackSpecialty] for unknown/empty/[null] disease names.
  static String recommendedSpecialty(String? disease) {
    if (disease == null) return fallbackSpecialty;
    final key = _normalize(disease);
    if (key.isEmpty) return fallbackSpecialty;
    return _diseaseToSpecialty[key] ?? fallbackSpecialty;
  }

  /// True when [disease] resolves to a specialty other than the fallback.
  static bool hasExplicitMapping(String? disease) {
    return recommendedSpecialty(disease) != fallbackSpecialty;
  }

  /// Normalizes a disease name for case/whitespace/separator-insensitive lookup.
  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll('  ', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}