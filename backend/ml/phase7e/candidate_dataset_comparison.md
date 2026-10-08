# Candidate Dataset Comparison

**Date:** 2026-09-08
**Scoring:** 0-5 per criterion (5=excellent). Overall = % of maximum.

> **IMPORTANT CAVEAT:** All information is from web documentation (Kaggle/UCI/IEEE data cards).
> No dataset was downloaded or directly inspected during this phase.
> Any final selection MUST be manually downloaded, inspected, and verified before integration.

## Comparison Table

| Candidate | Provenance | Rows | Features | Classes | Total Score | Recommendation |
|-----------|------------|------|----------|---------|-------------|----------------|
| UCI 'Early Stage Diabetes Risk Prediction' (ID 529) | Direct questionnaires from Sylhet Diabet... | 520 | 16 binary symptom features + age/gender ... | 2 (diabetes positive/negative) | 76.0% | Candidate needing manual review |
| UCI 'CDC Diabetes Health Indicators' (ID 891) | CDC Behavioral Risk Factor Surveillance ... | Large (CDC survey) | 35 features (demographics + survey answe... | 3 (no diabetes / prediabetes / diabetes) | 72.0% | Candidate needing manual review |
| Kaggle 'Disease Prediction Using Machine Learning' (Kaushil268) | Community-submitted; claims symptom/dise... | ~4920 train + small test | 132 binary symptom columns + prognosis t... | ~42 diseases | 64.0% | Candidate needing manual review |
| IEEE DataPort 'Disease Prediction Dataset' (Ayush Nautiyal et al.) | Referenced from MedLinePlus; 1325 sympto... | Unknown (training/testing CSVs) | Many binary symptom columns... | 391 diseases | 62.0% | Candidate needing manual review |
| Kaggle 'Symptom2Disease' (Niyarr Barman) | Community-sourced; 24 diseases x 50 symp... | 1,200 | 2 columns: 'label' (disease) + 'text' (n... | 24 diseases | 54.0% | Requires manual verification â€” weak |
| Kaggle 'Community Healthcare MultiSymptoms-Disease Dataset' (arjunnairedu) | Stated as 'simulated' patient records; 1... | 100,000 (simulated) | 174 binary symptoms + disease target... | 46 diseases | 54.0% | Requires manual verification â€” weak |
| Kaggle 'Symptom to Disease Descriptions (820_Cleaned)' | Community; 820 diseases, 654 symptoms; i... | 190,672 (row-level binary matrix) + text descriptions | 654 binary symptoms + disease target; pl... | 820 diseases | 46.0% | Requires manual verification â€” weak |
| Kaggle 'Disease and Symptoms dataset' (Mohamed Medhat AZZAZY) | Community; 378 columns, ~773 records vis... | ~773 (partial view) | 378 columns (symptoms)... | Unknown (likely many) | 38.0% | Rejected |

## Score Breakdown

### UCI 'Early Stage Diabetes Risk Prediction' (ID 529) â€” 76.0%

| Criterion | Score |
|-----------|-------|
| Provenance | 5/5 |
| Documentation | 4/5 |
| Class support | 3/5 |
| Class balance | 4/5 |
| Symptom relevance | 3/5 |
| Feature interpretability | 4/5 |
| Disease separability evidence | 4/5 |
| License/usage clarity | 5/5 |
| Integration feasibility | 3/5 |
| Overall suitability | 3/5 |

**Provenance:** Direct questionnaires from Sylhet Diabetes Hospital, Bangladesh; approved by a doctor
**Rows/Features/Classes:** 520 / 16 binary symptom features + age/gender + binary class / 2 (diabetes positive/negative)
**Target:** class (binary)
**License:** UCI open
**Access:** Free (ucimlrepo / UCI)
**Verification:** Documented via web; medically sourced (doctor-approved questionnaires); small
**Known limitations:** Only diabetes (2 classes); 520 rows; not a general disease-symptom dataset
**Recommendation:** Candidate needing manual review

### UCI 'CDC Diabetes Health Indicators' (ID 891) â€” 72.0%

| Criterion | Score |
|-----------|-------|
| Provenance | 5/5 |
| Documentation | 4/5 |
| Class support | 5/5 |
| Class balance | 3/5 |
| Symptom relevance | 2/5 |
| Feature interpretability | 3/5 |
| Disease separability evidence | 3/5 |
| License/usage clarity | 5/5 |
| Integration feasibility | 3/5 |
| Overall suitability | 3/5 |

**Provenance:** CDC Behavioral Risk Factor Surveillance System (BRFSS) survey data
**Rows/Features/Classes:** Large (CDC survey) / 35 features (demographics + survey answers) / 3 (no diabetes / prediabetes / diabetes)
**Target:** Diabetes_binary
**License:** UCI open
**Access:** Free (ucimlrepo / UCI)
**Verification:** Documented via web; CDC-sourced, real survey data
**Known limitations:** Only 3 diabetes classes; features are survey-style, not symptom-based; not a disease-symptom prediction dataset
**Recommendation:** Candidate needing manual review

### Kaggle 'Disease Prediction Using Machine Learning' (Kaushil268) â€” 64.0%

| Criterion | Score |
|-----------|-------|
| Provenance | 2/5 |
| Documentation | 3/5 |
| Class support | 3/5 |
| Class balance | 2/5 |
| Symptom relevance | 5/5 |
| Feature interpretability | 4/5 |
| Disease separability evidence | 3/5 |
| License/usage clarity | 3/5 |
| Integration feasibility | 4/5 |
| Overall suitability | 3/5 |

**Provenance:** Community-submitted; claims symptom/disease mapping; ~42 diseases, 132 binary symptoms
**Rows/Features/Classes:** ~4920 train + small test / 132 binary symptom columns + prognosis target / ~42 diseases
**Target:** prognosis (last column)
**License:** Open Database / Contents (ODC) per Kaggle
**Access:** Kaggle (free account/API)
**Verification:** Documented via web search only; NOT downloaded/inspected
**Known limitations:** Very small total records (~5000); 42 classes with 132 features; reported 100% train accuracy is likely overfitting
**Recommendation:** Candidate needing manual review

### IEEE DataPort 'Disease Prediction Dataset' (Ayush Nautiyal et al.) â€” 62.0%

| Criterion | Score |
|-----------|-------|
| Provenance | 4/5 |
| Documentation | 3/5 |
| Class support | 2/5 |
| Class balance | 2/5 |
| Symptom relevance | 5/5 |
| Feature interpretability | 4/5 |
| Disease separability evidence | 2/5 |
| License/usage clarity | 3/5 |
| Integration feasibility | 3/5 |
| Overall suitability | 3/5 |

**Provenance:** Referenced from MedLinePlus; 1325 symptoms, 391 diseases; academic submission with DOI
**Rows/Features/Classes:** Unknown (training/testing CSVs) / Many binary symptom columns / 391 diseases
**Target:** disease/prognosis
**License:** IEEE DataPort terms; free access noted
**Access:** IEEE DataPort or Kaggle mirror (free)
**Verification:** Documented via web search; medical reference cited; NOT inspected directly
**Known limitations:** Very large class count (391); most likely tiny per-class support; MedLinePlus-referenced but assembled by students
**Recommendation:** Candidate needing manual review

### Kaggle 'Symptom2Disease' (Niyarr Barman) â€” 54.0%

| Criterion | Score |
|-----------|-------|
| Provenance | 2/5 |
| Documentation | 3/5 |
| Class support | 3/5 |
| Class balance | 5/5 |
| Symptom relevance | 4/5 |
| Feature interpretability | 2/5 |
| Disease separability evidence | 2/5 |
| License/usage clarity | 2/5 |
| Integration feasibility | 2/5 |
| Overall suitability | 2/5 |

**Provenance:** Community-sourced; 24 diseases x 50 symptom descriptions = 1200 rows
**Rows/Features/Classes:** 1,200 / 2 columns: 'label' (disease) + 'text' (natural-language symptom description) / 24 diseases
**Target:** label column
**License:** Kaggle default
**Access:** Kaggle (free)
**Verification:** Documented via web search only; NOT downloaded
**Known limitations:** Requires NLP processing (natural text); 24 diseases only; 1200 rows is small
**Recommendation:** Requires manual verification â€” weak

### Kaggle 'Community Healthcare MultiSymptoms-Disease Dataset' (arjunnairedu) â€” 54.0%

| Criterion | Score |
|-----------|-------|
| Provenance | 2/5 |
| Documentation | 2/5 |
| Class support | 2/5 |
| Class balance | 2/5 |
| Symptom relevance | 5/5 |
| Feature interpretability | 4/5 |
| Disease separability evidence | 2/5 |
| License/usage clarity | 2/5 |
| Integration feasibility | 4/5 |
| Overall suitability | 2/5 |

**Provenance:** Stated as 'simulated' patient records; 174 symptoms, 46 diseases; matches project's structure
**Rows/Features/Classes:** 100,000 (simulated) / 174 binary symptoms + disease target / 46 diseases
**Target:** disease
**License:** Kaggle default
**Access:** Kaggle (free)
**Verification:** Documented via web search only; NOT downloaded
**Known limitations:** SIMULATED data â€” not real clinical records; 46 diseases / 174 symptoms EXACTLY matches the project, suggesting it may be the same or a sibling synthetic-style dataset
**Recommendation:** Requires manual verification â€” weak

### Kaggle 'Symptom to Disease Descriptions (820_Cleaned)' â€” 46.0%

| Criterion | Score |
|-----------|-------|
| Provenance | 2/5 |
| Documentation | 2/5 |
| Class support | 1/5 |
| Class balance | 1/5 |
| Symptom relevance | 5/5 |
| Feature interpretability | 4/5 |
| Disease separability evidence | 2/5 |
| License/usage clarity | 2/5 |
| Integration feasibility | 2/5 |
| Overall suitability | 2/5 |

**Provenance:** Community; 820 diseases, 654 symptoms; includes column-level and text data
**Rows/Features/Classes:** 190,672 (row-level binary matrix) + text descriptions / 654 binary symptoms + disease target; plus descriptive text / 820 diseases
**Target:** disease
**License:** Kaggle default
**Access:** Kaggle (free)
**Verification:** Documented via web; NOT inspected
**Known limitations:** 820 classes is far too many for meaningful multiclass evaluation; likely tiny per-class support
**Recommendation:** Requires manual verification â€” weak

### Kaggle 'Disease and Symptoms dataset' (Mohamed Medhat AZZAZY) â€” 38.0%

| Criterion | Score |
|-----------|-------|
| Provenance | 2/5 |
| Documentation | 1/5 |
| Class support | 1/5 |
| Class balance | 1/5 |
| Symptom relevance | 5/5 |
| Feature interpretability | 3/5 |
| Disease separability evidence | 2/5 |
| License/usage clarity | 2/5 |
| Integration feasibility | 1/5 |
| Overall suitability | 1/5 |

**Provenance:** Community; 378 columns, ~773 records visible
**Rows/Features/Classes:** ~773 (partial view) / 378 columns (symptoms) / Unknown (likely many)
**Target:** diseases
**License:** Kaggle default
**Access:** Kaggle (free)
**Verification:** Documented via web; NOT inspected
**Known limitations:** Very wide (378 cols) with few rows; unclear; likely overkill/unmanageable
**Recommendation:** Rejected
