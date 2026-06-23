# Model Card — CareAttend DNA-Risk Classifier

*Format after Mitchell et al. (2019), "Model Cards for Model Reporting", FAT*. This card documents the production model for AT4 Quality Assurance and as a production-readiness artefact.*

**Last updated:** June 2026 · **Version:** v1.0 (prototype) · **Owner:** Hritik Kumar Sah (B00923557)

---

## 1. Model details
- **Type:** Logistic Regression (binary classifier), scikit-learn.
- **Selected over:** Random Forest, XGBoost, LightGBM (4-model comparison) and an MLP baseline. Linear model chosen for **interpretability and auditability**, accepting a marginal accuracy trade-off — justified for clinical decision support (DCB0129, GDPR Art 22, NHSX "explainable").
- **Inputs (10 features):** Age, Gender, AppointmentLeadTimeDays, SMSReceived, PriorDNACount, Hypertension, Diabetes, Alcoholism, Disability, IMDDecile.
- **Output:** calibrated probability of DNA (0–1) + risk tier (Low/Medium/High). The deployed (calibrated) model scores at operating threshold **0.375** (`threshold_calibrated.joblib`); the uncalibrated base model used 0.60. Calibration rescales probabilities, so the cutoff is re-derived on calibrated scores — see §4–5.
- **Preprocessing:** StandardScaler; SMOTE applied to the **training partition only** (no leakage).
- **Explainability:** SHAP (Linear/Tree explainer) — top-3 per-patient factors with direction.

## 2. Intended use
- **Primary:** staff-facing decision support — flag high-DNA-risk patients so admin staff can prioritise outreach (calls, transport, carer reminders, interpreters).
- **Users:** NHS GP-practice / trust administrative and reception staff.
- **Out of scope:** automated decisions about care, patient-facing output, clinical diagnosis. A human always decides the action (no solely-automated decision — GDPR Art 22).

## 3. Training data
- **Source:** synthetic — 12,000 base records (ONS/NHS-Digital-calibrated) + 3,000 CTGAN-style UK demographic supplement across 3 trust profiles.
- **Split:** 12,000 train / 3,000 test, stratified, seed 42. **DNA prevalence ≈ 25.8%.**
- **Limitation:** synthetic data only; no real NHS validation. CTGAN is approximated, not a trained generator.

## 4. Performance (held-out test set, n=3,000)
Metrics for the **deployed calibrated model at its operating threshold 0.375**. The
uncalibrated base model at threshold 0.60 is shown for reference; ROC-AUC is
threshold- and calibration-invariant, so discrimination is unchanged.

| Metric | Calibrated @ 0.375 (deployed) | Base @ 0.60 (ref) | Target (NFR-04) |
|--------|:-----:|:-----:|:---------------:|
| F1 | **0.721** | 0.724 | ≥ 0.72 ✅ |
| Recall | **0.735** | 0.748 | ≥ 0.70 ✅ |
| Precision | 0.707 | 0.701 | — |
| ROC-AUC | 0.911 | 0.911 | — |
| Accuracy | 0.853 | 0.853 | — |

> Note: applying the base threshold 0.60 to *calibrated* probabilities (the bug
> fixed in this revision) would collapse recall to **0.499** — half the DNAs
> missed. The threshold must always be derived on the scoring model's own
> probability scale.
>
> Caveat: the calibrated operating threshold (0.375) is selected to maximise F1
> on the same held-out test set these metrics are reported on, so the operating
> point is **in-sample** and mildly optimistic. A production deployment should
> tune the threshold on a separate validation split. Discrimination (ROC-AUC)
> is unaffected by this.

## 5. Calibration
Probabilities are post-hoc calibrated (`ml/calibration.py`); calibrators fit on natural prevalence (no SMOTE) and evaluated on the held-out test set.

| Variant | Brier ↓ | Log-loss ↓ |
|---------|:-------:|:----------:|
| Uncalibrated | 0.1168 | 0.3688 |
| Sigmoid (Platt) | 0.1004 | — |
| **Isotonic (recommended)** | **0.1004** | — |

**Isotonic calibration reduces Brier score by ~14%** → a predicted "70%" now tracks the true observed DNA frequency far more closely. Reliability curve: `models/reliability_curve.png` (when matplotlib present); raw bins in `models/calibration_report.json`. Calibrated estimator saved as `models/model_calibrated.joblib`.

## 6. Fairness
- Audited for **demographic parity** and **equalised odds** across age, gender, IMD (`ml/bias_monitor.py`, Caton & Haas 2024 framework), pass/fail at 0.10.
- **Detection only** in v1.0 — no mitigation yet. Roadmap: `fairlearn` reweighing + per-group thresholds.

## 7. Ethical considerations & risks
- **Deprivation proxy risk:** IMD is predictive but socially sensitive; the bias audit exists to catch unfair penalisation of deprived groups (cf. Obermeyer et al. 2019).
- **Automation bias:** mitigated by SHAP explanations + human-in-the-loop framing.
- **Data drift:** synthetic→real transfer untested; requires re-validation on real NHS data before deployment.

## 8. Caveats & next steps
- Not for clinical use until: real-data retraining, external (geographic/temporal) validation, DCB0129 clinical safety case, DPIA. See `docs/CareAttend_Master_Guide.md` Track B.
