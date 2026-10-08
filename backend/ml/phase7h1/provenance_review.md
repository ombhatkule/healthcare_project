# Phase 7H.1 — Provenance Review

**Dataset:** SymbiPredict / Symptom-Disease Prediction Dataset (SDPD)
**Reviewed in:** Phase 7H.1 (manual-review gate after Phase 7H)

## 1. Source
- Mendeley Data — "SymbiPredict" record
- Published: 2024-04-02, Version 1 (per Mendeley record)
- Local source file: `backend/ml/phase7g/acquired/symbipredict_2022.csv`
- Local copy verified: 4,961 rows × 133 cols (132 symptom + `prognosis`), SHA-256 `9834c90dd48eb2fef1fa56282f8f016a6781b0e4ada878015dc34a81af8e9e1b`

## 2. DOI
`10.17632/dv5z3v2xyd.1`
(record: https://data.mendeley.com/datasets/dv5z3v2xyd/1)

## 3. License
**CC BY 4.0** (clear, re-usable with attribution). No license conflict found for research/educational use.

## 4. Data type
- Structured binary matrix: 132 symptom features (0/1) + `prognosis` (41 disease labels).
- 4,961 rows consisting of 304 unique symptom-vector/disease associations repeated to a uniform 121 rows per class.
- **Not patient-level data.** Records are curated symptom→disease associations.

## 5. Provenance confidence
**CONDITIONAL.**
Source documentation (Mendeley record description) states symptoms are drawn from "relevant symptoms sourced from reputable medical literature, clinical observations, and expert consensus." No independent verification of an underlying patient cohort, data-collection protocol, IRB/consent, or clinical validation was found in the available evidence.
Statement: *"Provenance verification is limited to the documented dataset source and metadata."*

## 6. Clinical-data status
**NOT established as a clinical patient cohort.**
Community-curated symptom-disease association dataset; not established as clinical patient data. Do not treat 4,961 rows as 4,961 patient records.

## 7. Known limitations
- Association-format: 304 unique symptom vectors; repeated rows are formatting repeats, not independent patients.
- No patient outcomes, severity, prevalence, or demographic information.
- No source documents verified the symptom lists against peer-reviewed clinical guidelines (only Mendeley description cites literature/observation/expert consensus as a sourcing approach).
- 41 classes but only 5–10 canonical vectors per class → small association sample.

## 8. Educational/research suitability
**Suitable for controlled, non-clinical educational/research disease-classification experimentation**, with explicit labels: exploratory, not clinically validated.

## 9. Production/clinical suitability
**NOT suitable** for production clinical diagnosis or any real-world clinical use. No medical-validity claim is supported by source documentation.

## 10. Final provenance status
**CONDITIONAL** (acceptable for controlled research/education; not clinical; verification limited to documented metadata). Do not mark PASS for clinical purposes.

---
*This review does not fabricate institutional endorsement, clinical validation, patient consent, or clinician review.*