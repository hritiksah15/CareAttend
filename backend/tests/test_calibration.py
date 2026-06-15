"""Tests for probability calibration (ml/calibration.py).

Verifies the model is well-calibrated and that post-hoc calibration does not
worsen the Brier score — evidence that predicted probabilities are trustworthy
(AT4 Quality Assurance).
"""

import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

pytestmark = pytest.mark.skipif(
    not (os.path.exists("models/model.joblib")
         and os.path.exists("data/synthetic_dataset.csv")),
    reason="Model or dataset not available",
)

from ml.calibration import evaluate_calibration  # noqa: E402


@pytest.fixture(scope="module")
def report():
    return evaluate_calibration()


def test_report_structure(report):
    assert "uncalibrated" in report
    assert "sigmoid" in report["calibrated"]
    assert "isotonic" in report["calibrated"]


def test_brier_in_valid_range(report):
    brier = report["uncalibrated"]["brier"]
    assert 0.0 <= brier <= 0.25  # 0.25 = random baseline for balanced binary


def test_calibration_does_not_worsen(report):
    base = report["uncalibrated"]["brier"]
    for method, m in report["calibrated"].items():
        assert m["brier"] <= base + 1e-3, f"{method} worsened calibration"


def test_recommended_method_valid(report):
    assert report["recommended"] in ("sigmoid", "isotonic",
                                     "uncalibrated (already well-calibrated)")


def test_reliability_curve_monotonicity(report):
    """A well-calibrated curve should broadly increase: higher predicted
    probability → higher observed frequency."""
    r = report["uncalibrated"]["reliability"]
    pred, obs = r["mean_predicted"], r["fraction_positive"]
    # Spearman-style check: top bin observes more positives than bottom bin.
    assert obs[-1] > obs[0]
