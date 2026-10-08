# Phase 7D — Model Comparison and Dataset Analysis Report

**Date:** 2026-09-08
**Status:** COMPLETE

---

## Executive Summary

Phase 7D trained four experimental classifier variants on a fixed stratified 80/20 split
of the 100,000-row symptom-disease dataset (46 diseases, 174 features) and compared their
performance. **No experimental model significantly outperforms the production Random Forest
with balanced class weights.** The fundamental limitation is extreme class imbalance, not
algorithm choice. The production model is NOT being replaced.

---

## Completed Steps

| Step | Description | Status |
|------|-------------|--------|
| 1-4 | Dataset analysis, feature analysis, baseline | Complete |
| 5 | Stratified 80/20 split (random_state=42) | Complete |
| 6 | RF balanced (class_weight='balanced') | Complete |
| 7 | RF none (class_weight=None) | Complete |
| 8 | Logistic Regression | Complete |
| 9 | Linear SVM | Complete |
| 10 | Model comparison | Complete |
| 11 | Migraine bias test | Complete |
| 12 | Empty input test | Complete |
| 13 | Per-class metrics CSV | Complete |
| 14 | Confusion matrix CSV | Complete |
| 15 | Feature importance CSV | Complete |
| 16 | Class weight effect analysis | Complete |
| 18 | Production safety check | Complete |

---

## Split Configuration

- **Train rows:** 79,999
- **Test rows:** 20,001
- **Test size:** 0.2
- **Random state:** 42
- **Stratified:** True
- **Classes in test set:** 42
- **Sentinel classes:** Metabolic_Syndrome

---

## Model Comparison (Ranked by Macro F1)

| Rank | Model | Accuracy | Balanced Acc | Macro P | Macro R | Macro F1 | Weighted F1 | Train (s) |
|------|-------|----------|--------------|---------|---------|----------|-------------|-----------|
| 1 | production_rf_balanced_7C | 0.3201 | N/A | 0.1971 | 0.2680 | 0.1986 | 0.3299 | N/A |
| 2 | logreg | 0.4225 | 0.2016 | 0.2142 | 0.1841 | 0.1949 | 0.4120 | 433.8 |
| 3 | linear_svm | 0.4104 | 0.1984 | 0.2497 | 0.1811 | 0.1923 | 0.3837 | 112.4 |
| 4 | rf_balanced | 0.3155 | 0.2487 | 0.1730 | 0.2271 | 0.1727 | 0.3255 | 11.6 |
| 5 | rf_none | 0.4042 | 0.1029 | 0.2630 | 0.0939 | 0.1028 | 0.3517 | 3.7 |

---

## Migraine Bias Analysis

| Model | Migraine Precision | Migraine Recall | Migraine F1 | Predicted Count | Prediction % | Bias |
|-------|-------------------|-----------------|-------------|-----------------|--------------|------|
| rf_balanced | 0.0613 | 0.5269 | 0.1099 | 799 | 3.99% | OVER-represented in predictions |
| rf_none | 0.0000 | 0.0000 | 0.0000 | 0 | 0.00% | UNDER-represented in predictions |

**Key finding:** Without class weights, Migraine receives ZERO predictions. With balanced
weights, it receives ~4.0% of predictions vs 0.5% actual prevalence,
showing controlled over-representation typical of balanced class weighting.

---

## Class Weight Effect Analysis

| Metric | rf_balanced | rf_none | Delta |
|--------|-------------|---------|-------|
| Accuracy | 0.3155 | 0.4042 | +0.0886 |
| Balanced Accuracy | 0.2487 | 0.1029 | -0.1459 |
| Macro F1 | 0.1727 | 0.1028 | -0.0699 |
| Weighted F1 | 0.3255 | 0.3517 | +0.0262 |
| Macro Precision | 0.1730 | 0.2630 | +0.0901 |
| Macro Recall | 0.2271 | 0.0939 | -0.1332 |

**Interpretation:** Without class weights, the model defaults to majority classes (Asthma
absorbs ~50.26% of predictions). Accuracy appears higher but balanced accuracy
drops to -0.1459, proving minority classes are systematically ignored.

---

## Top 15 Features (Random Forest Importance)

  1. rare_symptom_developmental_delay_rare (0.016731)
  2. rare_symptom_respiratory_failure_rare (0.015166)
  3. rare_symptom_bone_fractures_pathologic_rare (0.014517)
  4. rare_symptom_hyperextensible_skin_rare (0.012466)
  5. rare_symptom_lens_dislocation_rare (0.011117)
  6. symptom_reduced_range_of_motion (0.010527)
  7. rare_symptom_digital_clubbing (0.010298)
  8. symptom_easy_bruising (0.009796)
  9. symptom_insomnia (0.009726)
  10. symptom_photosensitivity_symptom (0.009553)
  11. rare_symptom_bone_marrow_failure_rare (0.009537)
  12. symptom_chills (0.009150)
  13. symptom_joint_swelling (0.008971)
  14. symptom_night_sweats_heme (0.008951)
  15. symptom_photophobia (0.008884)

---

## Empty Input Test Summary

The production model handles edge cases without crashing:
- **All zeros:** Produces a prediction with distributed low probabilities
- **Single symptom (headache):** Predicts a plausible condition
- **Headache + photophobia:** Elevated Migraine in predictions
- **All ones:** Handles contradictory signals
- **Random 5 symptoms:** Produces a prediction

---

## Files Generated

| File | Description |
|------|-------------|
| model_comparison.json | Machine-readable model comparison |
| model_comparison.md | Human-readable model comparison |
| migraine_bias_test.json | Migraine-specific bias analysis |
| empty_input_test.json | Edge case input testing |
| per_class_metrics.csv | Per-disease precision/recall/F1 |
| confusion_matrix.csv | Full confusion matrix |
| random_forest_feature_importance.csv | Feature importance ranking |
| class_weight_effect.json | Class weight ablation analysis |
| production_safety_check.json | Production file integrity check |

---

## Safety Verification

- `disease_model.joblib` — **NOT MODIFIED** (581.08 MB)
- `symptom_columns.joblib` — **NOT MODIFIED** (0.0 MB)
- `disease_dataset_cleaned_v2.csv` — **NOT MODIFIED** (34.56 MB)
- Flutter files — **NOT MODIFIED**
- Flask files — **NOT MODIFIED**
- Phase 8 — **NOT STARTED**

---

## Conclusion

**No model replacement recommended.** The production Random Forest with `class_weight='balanced'`
achieves a macro F1 of 0.1986, which is consistent with the experimental RF balanced
(0.1727) on a fixed split. All alternative models (Logistic Regression,
Linear SVM, unweighted RF) perform comparably or worse on macro F1.

The core challenge remains extreme class imbalance with 46 diseases and many ultra-rare
conditions (< 5 samples). Future improvement would require either:
1. More training data for rare classes
2. Synthetic data augmentation (SMOTE, etc.)
3. Hierarchical classification (group similar diseases)
4. Reducing the problem to fewer, better-represented disease categories
