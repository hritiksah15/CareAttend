"""Tests for the bias monitoring module (FR-07)."""

import pytest
import os

pytestmark = pytest.mark.skipif(not os.path.exists("models/model.joblib"), reason="Models not trained yet")

from ml.bias_monitor import BiasMonitor


@pytest.fixture(scope="module")
def monitor():
    return BiasMonitor(model_dir="models")


class TestBiasAudit:
    def test_audit_returns_all_groups(self, monitor):
        results = monitor.run_audit()
        assert "age_group" in results
        assert "gender" in results
        assert "imd_band" in results
        assert "overall_metrics" in results

    def test_age_group_structure(self, monitor):
        results = monitor.run_audit()
        age = results["age_group"]
        assert "groups" in age
        assert "demographic_parity_diff" in age
        assert "equalised_odds_diff" in age
        assert "dp_status" in age
        assert "eo_status" in age

    def test_dp_status_values(self, monitor):
        results = monitor.run_audit()
        for group_key in ["age_group", "gender", "imd_band"]:
            assert results[group_key]["dp_status"] in ("Pass", "Fail")
            assert results[group_key]["eo_status"] in ("Pass", "Fail")

    def test_overall_metrics_keys(self, monitor):
        results = monitor.run_audit()
        om = results["overall_metrics"]
        assert "precision" in om
        assert "recall" in om
        assert "f1_score" in om
        assert "confusion_matrix" in om
        assert "total_samples" in om

    def test_audit_reports_operating_threshold(self, monitor):
        results = monitor.run_audit()
        assert results["model_source"] in ("base", "calibrated")
        assert 0 < results["threshold"] < 1

    def test_metrics_in_valid_range(self, monitor):
        results = monitor.run_audit()
        om = results["overall_metrics"]
        assert 0 <= om["precision"] <= 1
        assert 0 <= om["recall"] <= 1
        assert 0 <= om["f1_score"] <= 1

    def test_gender_groups_present(self, monitor):
        results = monitor.run_audit()
        groups = results["gender"]["groups"]
        assert len(groups) == 2

    def test_dp_diff_non_negative(self, monitor):
        results = monitor.run_audit()
        for key in ["age_group", "gender", "imd_band"]:
            assert results[key]["demographic_parity_diff"] >= 0
            assert results[key]["equalised_odds_diff"] >= 0
