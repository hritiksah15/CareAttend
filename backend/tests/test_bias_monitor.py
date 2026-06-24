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


class TestGovernanceGate:
    def test_governance_block_present(self, monitor):
        gov = monitor.run_audit()["governance"]
        assert gov["verdict"] in ("PASS", "ACTION_REQUIRED")
        assert "breaches" in gov and "recommended_actions" in gov
        assert gov["breach_count"] == len(gov["breaches"])

    def test_verdict_matches_breaches(self, monitor):
        gov = monitor.run_audit()["governance"]
        if gov["breach_count"] == 0:
            assert gov["verdict"] == "PASS"
        else:
            assert gov["verdict"] == "ACTION_REQUIRED"

    def test_breach_consistency_with_group_status(self, monitor):
        from ml.bias_monitor import FAIRNESS_TOLERANCE

        results = monitor.run_audit()
        # Every breach must correspond to a metric actually over tolerance.
        for b in results["governance"]["breaches"]:
            assert b["value"] > FAIRNESS_TOLERANCE
            assert b["metric"] in ("demographic_parity", "equalised_odds")

    def test_flag_breach_when_tolerance_exceeded(self, monitor):
        # Synthetic audit dict with a forced disparity -> must flag ACTION_REQUIRED.
        fake = {
            "age_group": {"demographic_parity_diff": 0.30, "equalised_odds_diff": 0.05},
            "gender": {"demographic_parity_diff": 0.02, "equalised_odds_diff": 0.02},
            "imd_band": {"demographic_parity_diff": 0.01, "equalised_odds_diff": 0.01},
        }
        gov = monitor._governance_summary(fake)
        assert gov["verdict"] == "ACTION_REQUIRED"
        assert gov["breach_count"] == 1
        assert gov["breaches"][0]["attribute"] == "Age group"

    def test_pass_when_all_within_tolerance(self, monitor):
        fake = {
            "age_group": {"demographic_parity_diff": 0.05, "equalised_odds_diff": 0.05},
            "gender": {"demographic_parity_diff": 0.02, "equalised_odds_diff": 0.02},
            "imd_band": {"demographic_parity_diff": 0.01, "equalised_odds_diff": 0.01},
        }
        gov = monitor._governance_summary(fake)
        assert gov["verdict"] == "PASS"
        assert gov["breach_count"] == 0
