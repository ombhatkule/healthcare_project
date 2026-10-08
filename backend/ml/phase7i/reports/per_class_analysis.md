# Phase 7I — Per-Class Analysis

**Non-clinical research/educational evaluation; not clinically validated.**

## Reference model
Aggregate per-class metrics come from the **best representative model** (LR `class_weight=None`), summing all 50 grouped folds of the best model. Support shown is that model's aggregated test support (304 associations × 10 repeats = 3,040 test-instances).

Because the best representative model achieves **zero errors in grouped CV**, every class has precision = recall = F1 = 1.0. Full table: `reports/per_class_metrics.csv`.

## Distribution of support (per class, aggregated over repeats)
| Support (aggregate) | Classes |
|---|---|
| 50 (5 unique vectors × 10) | AIDS, Acne, Allergy, Fungal Infection, Heart Attack, Gastroenteritis, UTI, Paralysis (brain hemorrhage) |
| 60 | Impetigo, Hypertension, Dimorphic Hemmorhoids, Arthritis, Cervical Spondylosis, Drug Reaction |
| 70 | Bronchial Asthma, GERD, Peptic Ulcer Disease, Psoriasis, Hepatitis C, Vertigo, Osteoarthritis |
| 80 | Alcoholic Hepatitis, Hypothyroidism, Chronic Cholestasis, Varicose Veins, Malaria |
| 90 | Jaundice, Hypoglycemia, Hyperthyroidism, Hepatitis E, Common Cold, Diabetes, Tuberculosis, Hepatitis A, Typhoid, Pneumonia, Hepatitis B |
| 100 (10 vectors × 10) | Hepatitis D, Chickenpox, Dengue, Migraine |

## Lowest-support classes (highest per-class uncertainty)
- 8 classes carry only **5 unique symptom vectors each** (AIDS, Acne, Allergy, Fungal Infection, Gastroenteritis, Heart Attack, Urinary Tract Infection, Paralysis (brain hemorrhage)).
- With 5 vectors and 5 folds, each fold sees exactly ~1 such vector of these classes; macro metrics are driven by these small cells and can shift abruptly if a single vector were different.

## Zero / near-zero recall classes
- **None** under grouped CV for the best representative model (all recall = 1.0).
- For the slightly imperfect RF (balanced) config, only **Chronic Cholestasis** lost 3 / 80 test instances (recall 0.9625) — all misclassified as Hepatitis D.

## Classes consistently confused
- Under the perfect representative model: none (0 errors).
- Under RF (balanced): a single confusion pair, **Chronic Cholestasis → Hepatitis D** (3 errors, true recall 0.9625). This matches Phase 7H's separability finding that Hepatitis D ↔ Hepatitis E is the closest class pair (cosine ≈ 0.83); liver pathologies share overlapping symptom signatures.

## Caveats
- Perfect per-class scores reflect the clean canonical separation of the representation, not patient-level generalization.
- Small support (5–10 vectors/class) means per-class uncertainty is high even though the point estimates are 1.0.