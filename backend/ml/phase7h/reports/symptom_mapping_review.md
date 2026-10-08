# Phase 7H — Symptom Semantic Mapping Review

The **SymbiPredict vocabulary is primary**. The current production v2 vocabulary is referenced
only to classify each candidate symptom. No synonym is auto-applied to the candidate dataset.

## Summary

| Classification | Count |
|---|---|
| EXACT | 20 |
| HIGH_CONFIDENCE_SYNONYM | 3 |
| NO_MATCH | 101 |
| POSSIBLE_SYNONYM | 8 |

## HIGH_CONFIDENCE_SYNONYM (proposed additions to candidate vocabulary)

| Candidate symptom | Proposed canonical term |
|---|---|
| stomach_pain | abdominal_pain |
| belly_pain | abdominal_pain |
| breathlessness | shortness_of_breath |

## POSSIBLE_SYNONYM (manual confirmation required)

| Candidate symptom | Candidate synonym |
|---|---|
| joint_pain | joint_pain_symptom |
| weight_gain | weight_gain_symptom |
| anxiety | anxiety_symptom |
| weight_loss | unintentional_weight_loss |
| high_fever | fever |
| back_pain | low_back_pain |
| mild_fever | fever |
| congestion | nasal_congestion |
| cramps | muscle_cramps_symptom |
| bruising | easy_bruising |
| drying_and_tingling_lips | tingling |

## NO_MATCH count
101 candidate symptoms are new vocabulary.

Machine data: `analysis/symptom_mapping_review.json`
