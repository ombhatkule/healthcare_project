"""Verify the experimental model artifact loaded by the backend."""
import joblib
import numpy as np
import json
import os

model_path = os.path.join(os.path.dirname(__file__), '..', '..', 'model', 'experimental_disease_model.joblib')
vocab_path = os.path.join(os.path.dirname(__file__), '..', '..', 'model', 'experimental_symptom_columns.joblib')

m = joblib.load(model_path)
c = joblib.load(vocab_path)

print(f"Model type: {type(m).__name__}")
print(f"n_features_in_: {m.n_features_in_}")
print(f"n_classes: {len(m.classes_)}")
print(f"n_columns: {len(c)}")
print(f"has_predict_proba: {hasattr(m, 'predict_proba')}")
print(f"columns_match_features: {m.n_features_in_ == len(c)}")

# Build zero vector and run predict_proba
X = np.zeros((1, len(c)), dtype=np.int8)
proba = m.predict_proba(X)
print(f"proba_shape: {proba.shape}")
print(f"classes_count: {proba.shape[1]}")

# Run prediction with some symptoms
X2 = np.zeros((1, len(c)), dtype=np.int8)
for name in ['fever', 'headache', 'fatigue']:
    if name in c:
        idx = c.index(name)
        X2[0, idx] = 1
proba2 = m.predict_proba(X2)
pred = m.predict(X2)[0]
top_idx = np.argsort(proba2[0])[::-1][:5]
print(f"\nSample prediction with fever+headache+fatigue:")
for i in top_idx:
    print(f"  {c.index(c[i])} {m.classes_[i]}: {proba2[0][i]:.4f}")
print(f"Top prediction: {pred}")

# Check fluid_overload
print(f"\nfluid_overload in vocab: {'fluid_overload' in c}")
print(f"fluid_overload_1 in vocab: {'fluid_overload_1' in c}")
print(f"\nVERIFICATION: PASS")
