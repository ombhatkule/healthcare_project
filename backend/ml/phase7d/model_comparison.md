# Phase 7D — Model Comparison Report

**Date:** 2026-09-08

## Split Configuration

- Test size: 0.2
- Random state: 42
- Stratified: True
- Train rows: 79,999
- Test rows: 20,001
- Classes in test set: 42

## Models Ranked by Macro F1

| Rank | Model | Accuracy | Balanced Acc | Macro P | Macro R | Macro F1 | Weighted F1 | Train Time (s) |
|------|-------|----------|--------------|---------|---------|----------|-------------|----------------|
| 1 | production_rf_balanced_7C | 0.3201 | N/A | 0.1971 | 0.2680 | 0.1986 | 0.3299 | N/A |
| 2 | logreg | 0.4225 | 0.2016 | 0.2142 | 0.1841 | 0.1949 | 0.4120 | 433.8 |
| 3 | linear_svm | 0.4104 | 0.1984 | 0.2497 | 0.1811 | 0.1923 | 0.3837 | 112.4 |
| 4 | rf_balanced | 0.3155 | 0.2487 | 0.1730 | 0.2271 | 0.1727 | 0.3255 | 11.6 |
| 5 | rf_none | 0.4042 | 0.1029 | 0.2630 | 0.0939 | 0.1028 | 0.3517 | 3.7 |

## Key Findings

1. **No experimental model significantly outperforms the production baseline**
   in terms of macro F1, confirming that the Phase 7C model is a reasonable choice.

2. **Class weighting dramatically affects minority class recall.**
   Without class weights (rf_none), the model predicts mostly majority classes
   (Asthma absorbs 50%+ of predictions), while balanced weights spread predictions.

3. **Logistic Regression** achieves the highest overall accuracy and weighted F1
   but still has low macro F1, consistent with the extreme class imbalance.

4. **Linear SVM** performs similarly to Logistic Regression, confirming that
   linear models struggle equally with the 46-class imbalanced problem.

5. **All models show** near-zero performance on ultra-rare classes (support < 5).

## Conclusion

The production Random Forest with `class_weight='balanced'` remains the best
available model for this dataset. The fundamental limitation is extreme class
imbalance (46 classes, many with < 5 test samples), not the choice of algorithm.

No model replacement is recommended.