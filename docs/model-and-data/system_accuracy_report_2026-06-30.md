# System Accuracy Report

Date: 2026-06-30

## Scope

This report verifies CareAttend's model accuracy on the shipped synthetic
evaluation artefacts. It does not claim clinical accuracy on real NHS data.
Real-world clinical validation remains a production gate.

## Commands Run

| Check | Result |
|---|---|
| `pytest tests/test_predictor.py tests/test_calibration.py -q` | 17 passed |
| `pytest tests/test_feature_coverage.py::TestEthicsFramework tests/test_predictor.py tests/test_calibration.py -q` | 19 passed |
| Cross-validation script over `backend/data/synthetic_dataset.csv` | Completed on 15,000 records |
| `python -m py_compile app.py` | Passed |

## Held-Out Test Metrics

Source: `backend/models/training_results.json`

Selected model: Logistic Regression

| Metric | Value |
|---|---:|
| Test records | 3,000 |
| Training records | 12,000 |
| DNA rate | 25.83% |
| Operating threshold | 0.600 |
| Accuracy | 0.8527 |
| F1 | 0.7241 |
| Recall | 0.7484 |
| Precision | 0.7013 |
| ROC-AUC | 0.9110 |

Confusion matrix at the selected operating threshold:

| | Predicted attend | Predicted DNA |
|---|---:|---:|
| Actual attend | 1,978 | 247 |
| Actual DNA | 195 | 580 |

## Five-Fold Cross-Validation

Source: `backend/ml/evaluation.py` run over the shipped synthetic dataset
(`15,000` records, DNA rate `25.83%`).

| Model | Mean F1 | Mean recall | Mean ROC-AUC |
|---|---:|---:|---:|
| Logistic Regression | 0.6992 | 0.8002 | 0.8977 |
| Random Forest | 0.6802 | 0.7333 | 0.8826 |
| MLP Neural Network | 0.6924 | 0.8005 | 0.8943 |

Logistic Regression remains the preferred model because its performance is
stable and comparable to the MLP while preserving explainability for SHAP-based
clinical audit.

## Calibration

Source: `backend/models/calibration_report.json`

| Calibration | Brier score | Log loss | Brier improvement |
|---|---:|---:|---:|
| Uncalibrated | 0.1168 | 0.3688 | - |
| Sigmoid | 0.1004 | 0.3201 | 14.06% |
| Isotonic | 0.1004 | 0.3302 | 14.07% |

Recommended calibrator: isotonic.

## Conclusion

CareAttend satisfies NFR-04 on the synthetic held-out evaluation: F1 is above
0.72 and recall is above 0.70 at the selected operating threshold. The correct
claim is that the model is accurate for the synthetic prototype dataset and
methodologically tested; it is not clinically validated for real NHS deployment.
