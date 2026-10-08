# Phase 7F Step 12 — Can the Current Data Support a Reliable Task?

## Evidence

### Reduced-class learnability improves
- Macro F1: 0.21 (46) → 0.36 (19 classes, >=500)
- Balanced Accuracy: 0.27 (46) → 0.41 (19 classes)

### But separability does NOT improve meaningfully
- Avg pairwise cosine similarity gets **worse** with filtering:
  - Full: 0.694
  - >=100: 0.808
  - >=500: 0.824
- Removing rare classes leaves a set of high-support classes that are MORE similar to one
  another (they are the common, overlapping diseases).

### Fundamental limitation remains
- Even the best reduced problem (19 classes, >=500) has adjacency ~0.82 average similarity —
  many diseases remain statistically hard to separate from symptoms alone.
- The data is 'weakly structured' and consistent with synthetic-style generation.
- No external medical validation / provenance.

## Decision (choose one, best supported)

**Statement C — The current dataset is better suited for exploratory/demo classification
rather than reliable disease prediction.**

While restructuring improves macro metrics and classes >=100 (23 classes, Macro F1 0.35)
become substantially more learnable, the persistent high class similarity, weak feature
discrimination, unknown provenance, and inability to separate many common conditions mean the
data does not support *reliable* (medically interpretable) disease prediction. It is adequate
for demonstration/educational purposes only.
