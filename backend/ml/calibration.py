"""Probability calibration for the CareAttend DNA-risk model.

Why this matters: a clinician reads "82% risk" as a probability. If the model
is mis-calibrated, that number is meaningless and the decision support is
misleading. This module measures calibration (Brier score + reliability curve)
and fits post-hoc calibrators (Platt/sigmoid and isotonic) so a predicted
probability reflects the true observed DNA frequency.

Note: calibrators are fit on the NATURAL class distribution (no SMOTE). SMOTE
is used only to train the discriminative model; calibrating on resampled data
would distort the probabilities back towards 50%.

Run:  python -m ml.calibration
Outputs: models/calibration_report.json, models/model_calibrated.joblib,
         and (if matplotlib is available) models/reliability_curve.png
"""

import json
import os

import joblib
import numpy as np
import pandas as pd
from sklearn.base import clone
from sklearn.calibration import CalibratedClassifierCV, calibration_curve
from sklearn.metrics import brier_score_loss, log_loss
from sklearn.model_selection import train_test_split

from ml.data_generator import FEATURE_NAMES

DATA_PATH = "data/synthetic_dataset.csv"


def _load_split(model_dir, data_path):
    """Reconstruct the exact train/test split (seed 42) used in training."""
    df = pd.read_csv(data_path)
    X = df[FEATURE_NAMES].values
    y = df["NoShow"].values
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    scaler = joblib.load(os.path.join(model_dir, "scaler.joblib"))
    return (scaler.transform(X_train), y_train,
            scaler.transform(X_test), y_test)


def _reliability(y_true, y_prob, n_bins=10):
    frac_pos, mean_pred = calibration_curve(y_true, y_prob, n_bins=n_bins, strategy="uniform")
    return {
        "mean_predicted": [round(float(v), 4) for v in mean_pred],
        "fraction_positive": [round(float(v), 4) for v in frac_pos],
    }


def evaluate_calibration(model_dir="models", data_path=DATA_PATH, n_bins=10):
    """Measure baseline calibration and fit isotonic + sigmoid calibrators.

    Returns a report dict and writes it to models/calibration_report.json.
    Saves the best-calibrated estimator to models/model_calibrated.joblib.
    """
    X_train, y_train, X_test, y_test = _load_split(model_dir, data_path)
    base = joblib.load(os.path.join(model_dir, "model.joblib"))

    # Baseline (uncalibrated) probabilities on the held-out test set.
    p_base = base.predict_proba(X_test)[:, 1]
    brier_base = brier_score_loss(y_test, p_base)
    ll_base = log_loss(y_test, p_base)

    report = {
        "model": type(base).__name__,
        "n_test": int(len(y_test)),
        "uncalibrated": {
            "brier": round(float(brier_base), 5),
            "log_loss": round(float(ll_base), 5),
            "reliability": _reliability(y_test, p_base, n_bins),
        },
        "calibrated": {},
    }

    best_method, best_brier, best_estimator = None, brier_base, None
    for method in ("sigmoid", "isotonic"):
        cal = CalibratedClassifierCV(clone(base), method=method, cv=5)
        cal.fit(X_train, y_train)  # natural prevalence, no SMOTE
        p_cal = cal.predict_proba(X_test)[:, 1]
        brier = brier_score_loss(y_test, p_cal)
        report["calibrated"][method] = {
            "brier": round(float(brier), 5),
            "log_loss": round(float(log_loss(y_test, p_cal)), 5),
            "brier_improvement_pct": round(float((brier_base - brier) / brier_base * 100), 2),
            "reliability": _reliability(y_test, p_cal, n_bins),
        }
        if brier < best_brier:
            best_method, best_brier, best_estimator = method, brier, cal

    report["recommended"] = best_method or "uncalibrated (already well-calibrated)"

    if best_estimator is not None:
        joblib.dump(best_estimator, os.path.join(model_dir, "model_calibrated.joblib"))

    with open(os.path.join(model_dir, "calibration_report.json"), "w") as f:
        json.dump(report, f, indent=2)

    _maybe_plot(report, model_dir)
    return report


def _maybe_plot(report, model_dir):
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        return  # plotting is optional; JSON report is the source of truth

    fig, ax = plt.subplots(figsize=(6, 6))
    ax.plot([0, 1], [0, 1], "k:", label="Perfectly calibrated")
    u = report["uncalibrated"]["reliability"]
    ax.plot(u["mean_predicted"], u["fraction_positive"], "s-", label="Uncalibrated")
    for method, m in report["calibrated"].items():
        r = m["reliability"]
        ax.plot(r["mean_predicted"], r["fraction_positive"], "o-", label=f"Calibrated ({method})")
    ax.set_xlabel("Mean predicted probability")
    ax.set_ylabel("Observed DNA frequency")
    ax.set_title("Reliability curve — CareAttend DNA risk")
    ax.legend(loc="best")
    fig.tight_layout()
    fig.savefig(os.path.join(model_dir, "reliability_curve.png"), dpi=120)
    plt.close(fig)


if __name__ == "__main__":
    rep = evaluate_calibration()
    print(json.dumps({
        "model": rep["model"],
        "uncalibrated_brier": rep["uncalibrated"]["brier"],
        "calibrated": {k: v["brier"] for k, v in rep["calibrated"].items()},
        "recommended": rep["recommended"],
    }, indent=2))
