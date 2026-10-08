# Phase 7K — Label Mapping (Phase 7I → Columbia)

This is a non-clinical research/educational evaluation.
Results do not establish medical diagnostic accuracy, clinical validity, or suitability for patient care.

## Mapping summary (41 Phase 7I labels)

| Status | Count | Automatic use allowed? | Notes |
|--------|-------|------------------------|-------|
| EXACT | 8 | YES (per 7K rules) | Textually equivalent after normalization |
| HIGH_CONFIDENCE | 8 | NO — requires review | Standard clinical synonym; no clinician sign-off available in this session |
| POSSIBLE | 3 | NO — requires review | Partial/syndrome overlap only |
| NO_MATCH | 22 | NO | No credible counterpart in Columbia's 134 diseases |
| **Total** | **41** | Only **8** usable automatically | Coverage 8/41 = 19.5% |

No mappings were fabricated. No diseases were merged to inflate overlap.

## EXACT (8)
| Phase 7I label | Columbia label |
|----------------|----------------|
| Arthritis | arthritis |
| Diabetes | diabetes |
| Gastroenteritis | gastroenteritis |
| Hepatitis B | hepatitis B |
| Hepatitis C | hepatitis C |
| Hypoglycemia | hypoglycemia |
| Hypothyroidism | hypothyroidism |
| Pneumonia | pneumonia |

## HIGH_CONFIDENCE (8) — require review, NOT used automatically
| Phase 7I label | Columbia label | Comment |
|----------------|----------------|---------|
| AIDS | acquired immuno-deficiency syndrome^HIV^hiv infections | UMLS-alias resolved |
| Bronchial Asthma | asthma | accepted medical synonym |
| Heart Attack | myocardial infarction | accepted medical synonym |
| Hypertension | hypertensive disease | accepted medical synonym |
| Jaundice | hyperbilirubinemia | pathophysiological correlate |
| Migraine | migraine disorders | accepted medical synonym |
| Peptic Ulcer Disease | ulcer peptic | accepted medical synonym |
| Urinary Tract Infection | infection urinary tract | accepted medical synonym |

## POSSIBLE (3) — require review, NOT used automatically
| Phase 7I label | Columbia label | Why only POSSIBLE |
|----------------|----------------|-------------------|
| Alcoholic Hepatitis | chronic alcoholic intoxication | exposure syndrome, not confirmed hepatitis |
| Chronic Cholestasis | biliary calculus | cholestasis correlate, not the same disease |
| Fungal Infection | oral candidiasis | specific entity, not a general fungal label |

## NO_MATCH (22)
Acne, Allergy, Cervical Spondylosis, Chickenpox, Common Cold, Dengue, Dimorphic Hemmorhoids (piles), Drug Reaction,
GERD, Hepatitis A, Hepatitis D, Hepatitis E, Hyperthyroidism, Impetigo, Malaria, Osteoarthritis,
Paralysis (brain hemorrhage), Psoriasis, Tuberculosis, Typhoid, Varicose Veins, Vertigo.

## Consequence
Only 8/41 labels could enter an evaluation automatically, and even those 8 cannot be evaluated credibly because of
feature-coverage loss (see coverage_report.md). Under Phase 7K rule §5 and the no-manufactured-evidence rule, an
evaluation restricted to these 8 diseases would be a partial, unrepresentative artifact — it was therefore NOT run.