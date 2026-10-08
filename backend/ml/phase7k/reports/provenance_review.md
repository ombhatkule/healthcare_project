# Phase 7K — Provenance Review

This is a non-clinical research/educational evaluation.
Results do not establish medical diagnostic accuracy, clinical validity, or suitability for patient care.

## Evaluated: Columbia University Disease-Symptom Knowledge Database (COL-001)

| Field | Value |
|-------|-------|
| Name | Columbia University Disease-Symptom Knowledge Database |
| Institution | Columbia University, Department of Biomedical Informatics (DBMI) |
| Contributor | Prof. Carol Friedman (contact: friedman@dbmi.columbia.edu) |
| URL | https://impact.dbmi.columbia.edu/~friedma/Projects/DiseaseSymptomKB/index.html |
| Reference | AMIA Annual Symposium Proceedings 2008; PubMed Central PMC2656103 (~90% recall / ~92% precision reported) |
| Method | MedLEE NLP extraction of disease–symptom associations from 25,074 New York-Presbyterian hospital discharge summaries (2004) |
| Coding | Diseases and symptoms coded to UMLS concepts; symptoms include UMLS concept IDs |
| Format | Association rows: `disease, count_of_disease_occurrence, symptom`; counts = number of notes in which the association was found |
| License | **UNKNOWN — no explicit license statement found on the source page; manual review required** |
| Data date | 2004 discharge summaries; KB compiled/published ~2008 |

## Verdict on provenance
- **Strengths:** Strongest clinical provenance of any candidate — extracted automatically from real hospital discharge notes
  (a genuinely different source and extraction pipeline than the community-curated SymbiPredict KB). UMLS coding is explicit and auditable. Peer-reviewed (AMIA 2008).
- **Blocking weaknesses:**
  1. No explicit license → cannot legally or ethically treat it as licensed validation data (Phase 7G marked it
     "CONDITIONALLY APPROVED — license manual review required"; that review has not been granted).
  2. Association-count format → observation unit is "disease–symptom association with note count", not an individual patient case.
  3. Content independence confirmed, but vocabulary/coverage overlap with the Phase 7I 131-feature space is low.

## Other candidates — provenance summary
- **SymbiPredict / SDPD (Mendeley DOI 10.17632/dv5z3v2xyd.1):** CC BY 4.0, peer-reviewed methodology; community-curated
  symptom→disease associations (not patients); this is the **Phase 7I training source** — not usable for external validation.
- **Kaushil268 (Kaggle):** Apache-2.0; undocumented derivative of the same canonical family (mirror).
- **"Disease & Symptoms" Kaggle variants (800+/773 diseases):** license "Other (specified in description)"/unspecified; same canonical family; no indexed citation.
- **Mendeley "Disease and symptoms dataset 2023" (DOI 10.17632/2cxccsxydc.1):** CC BY 4.0; **self-declared artificially generated** rows.
- **DDXPlus (figshare 20043374):** research license described in NeurIPS 2022 paper; **synthetic** (Synthea + proprietary KB); not real clinical observations.
- **Brazil SINAN (PMC12819417):** CC BY; real dengue/chikungunya case notifications; single disease.
- **HCMC dengue (OUCRU, PMC9992802):** real cohort; access-restricted; single disease.
- **MIMIC-III (PhysioNet):** credentialed DUA; real EHR; lacks ready symptom-presence matrix.
- **symptoms2Disease (Kaggle):** unspecified license; paraphrase-derived from the same canonical family.

## Conclusion
No candidate had a combination of (a) documented and usable license, (b) case/patient-level observation type,
(c) adequate disease-label overlap, and (d) adequate feature overlap. The only clinically-sourced independent dataset
(Columbia KB) is blocked by license-pending status and coverage limits.

## Outcome
C — INSUFFICIENT_EXTERNAL_DATA (license + coverage + observation-type gaps; no credible independent dataset obtained).