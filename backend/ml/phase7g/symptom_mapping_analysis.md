# Phase 7G — Symptom-Vocabulary Mapping

Mapping of acquired candidate symptoms against the CURRENT vocab (`disease_dataset_cleaned_v2.csv`, 174 `symptom_*` features).
Purpose: quantify clinical-vocabulary intersection and confirm a new feature vocabulary will be required; `symptom_columns.joblib` is **not** modified.

## SymbiPredict (primary candidate) — 132 binary symptom features

| Category | Count | Notes |
|---|---|---|
| Exact match (current vocab) | **17** | e.g. `chills`, `vomiting`, `cough`, `constipation`, `abdominal_pain`, `chest_pain`, `neck_pain`, `dizziness`, `muscle_weakness`, `loss_of_smell`, `fatigue`, `headache`, `nausea`, `loss_of_appetite`, `runny_nose`, `high_fever→fever(loose)` |
| Possible / synonym (manual review) | **11** | `joint_pain→joint_pain_symptom`, `weight_gain`, `anxiety`, `weight_loss→unintentional_weight_loss`, `high_fever→fever`, `back_pain→low_back_pain`, `mild_fever→fever`, `congestion→nasal_congestion`, `cramps`, `bruising→easy_bruising`, `drying_and_tingling_lips→tingling` |
| No match (new vocabulary) | **104** | e.g. `nodal_skin_eruptions`, `burning_micturition`, `sunken_eyes`, `yellowish_skin`, `toxic_look_(typhos)`, etc. |
| Non-symptom | 0 | all 132 are symptom-like |

Conservative manual-confirmation subset flagged for Phase 7H: `stomach_pain/belly_pain → abdominal_pain`, `breathlessness → shortness_of_breath`.

## Columbia KB (alternative candidate) — 401 UMLS-coded symptoms

| Category | Count | Notes |
|---|---|---|
| Exact match (current vocab) | **33** | e.g. fever, headache, cough, nausea, vomiting, diarrhea, chest pain, dizziness … |
| Possible (manual review) | ~60–80 | synonym / UMLS variant → current feature    |
| No match (new vocabulary) | ~250 | UMLS MedLEE surface forms, incl. some fine-grained terms    |
| Non-symptom noise at high threshold | ~10 | e.g. gender/risk terms excluded in practice |

## Cleanup observed in SymbiPredict column names (parsing note)
- Messy tokens (spaces/parens/dots): `foul_smell_of urine`, `spotting_ urination`, `toxic_look_(typhos)`, `dischromic _patches`, `fluid_overload.1`. These required normalization for mapping and should be normalized in Phase 7H cleaning.

## Implication
- Approx. **104–118 symptom names × 41 diseases are NOT present in the current 174-feature vocabulary** → the new dataset requires a **new feature vocabulary** (132 features) and a new `symptom_columns` reference for Phase 7H; current `symptom_columns.joblib` must **not** be reused with the candidate.
- A `symptom_mapping_data.json` per-candidate mapping is stored in `backend/ml/phase7g/` (SymbiPredict + earlier Kaushil passes).