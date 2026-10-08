# Phase 7F Step 6 — Hierarchical Classification Feasibility

## Question

Can a hierarchical (e.g., Level 1 category → Level 2 disease) architecture be statistically
justified from the CURRENT dataset?

## Analysis

A hierarchical classifier requires a defensible grouping of the 46 diseases into a smaller
set of meaningful super-categories. The grouping must either:
1. Already exist in dataset metadata/documentation, OR
2. Be objectively derivable from the existing disease labels.

### Finding

**No evidence-supported hierarchical grouping can be constructed from the current dataset.**

Reasons:
- **No metadata/documentation** exists that assigns diseases to clinical categories.
- The 46 class labels are flat identifiers (e.g., "Asthma", "Migraine", "Obesity") with no
  documented taxonomical hierarchy.
- Objectively deriving groupings purely from symptom-profile similarity would be circular:
  it would group diseases precisely because their symptoms overlap, which is a symptom of the
  separability problem, not a validated clinical categorization.
- The instruction explicitly prohibits manually inventing medical disease groupings.

### Conclusion

**Hierarchical classification is NOT statistically justifiable from the current dataset** without
external, documented medical taxonomy — which is not available. A future hierarchy would require
a medically-grounded ontology (e.g., ICD chapters) supplied by a validated source, which is out of
scope until a better dataset is obtained.
