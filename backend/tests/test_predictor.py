"""Tests for the prediction module (FR-02, FR-03, NFR-04)."""

import pytest
import os

# Skip if models not trained yet
pytestmark = pytest.mark.skipif(not os.path.exists("models/model.joblib"), reason="Models not trained yet")

from ml.predictor import CareAttendPredictor


@pytest.fixture(scope="module")
def predictor():
    return CareAttendPredictor(model_dir="models")


class TestPredictor:
    def test_prediction_returns_required_keys(self, predictor):
        patient = {
            "Age": 72,
            "Gender": 0,
            "AppointmentLeadTimeDays": 14,
            "SMSReceived": 0,
            "PriorDNACount": 3,
            "Hypertension": 1,
            "Diabetes": 0,
            "Alcoholism": 0,
            "Disability": 0,
            "IMDDecile": 2,
        }
        result = predictor.predict(patient)
        assert "probability" in result
        assert "percentage" in result
        assert "risk_tier" in result
        assert "shap_values" in result
        assert "model_source" in result
        assert "threshold" in result

    def test_uses_calibrated_model_when_available(self, predictor):
        if os.path.exists("models/model_calibrated.joblib"):
            assert predictor.model_source == "calibrated"
        else:
            assert predictor.model_source == "base"

    def test_explainer_uses_base_model(self, predictor):
        assert predictor.explanation_model is not predictor.model or predictor.model_source == "base"

    def test_probability_range(self, predictor):
        patient = {
            "Age": 45,
            "Gender": 1,
            "AppointmentLeadTimeDays": 7,
            "SMSReceived": 1,
            "PriorDNACount": 0,
            "Hypertension": 0,
            "Diabetes": 0,
            "Alcoholism": 0,
            "Disability": 0,
            "IMDDecile": 7,
        }
        result = predictor.predict(patient)
        assert 0.0 <= result["probability"] <= 1.0
        assert 0.0 <= result["percentage"] <= 100.0

    def test_risk_tier_values(self, predictor):
        patient = {
            "Age": 30,
            "Gender": 1,
            "AppointmentLeadTimeDays": 3,
            "SMSReceived": 1,
            "PriorDNACount": 0,
            "Hypertension": 0,
            "Diabetes": 0,
            "Alcoholism": 0,
            "Disability": 0,
            "IMDDecile": 8,
        }
        result = predictor.predict(patient)
        assert result["risk_tier"] in ("Low", "Medium", "High")

    def test_shap_values_structure(self, predictor):
        patient = {
            "Age": 80,
            "Gender": 0,
            "AppointmentLeadTimeDays": 21,
            "SMSReceived": 0,
            "PriorDNACount": 5,
            "Hypertension": 1,
            "Diabetes": 1,
            "Alcoholism": 0,
            "Disability": 1,
            "IMDDecile": 1,
        }
        result = predictor.predict(patient)
        shap = result["shap_values"]
        assert len(shap) >= 3
        for sv in shap:
            assert "feature" in sv
            assert "label" in sv
            assert "value" in sv
            assert "direction" in sv
            assert sv["direction"] in ("risk-increasing", "risk-reducing")

    def test_high_risk_patient(self, predictor):
        patient = {
            "Age": 85,
            "Gender": 0,
            "AppointmentLeadTimeDays": 30,
            "SMSReceived": 0,
            "PriorDNACount": 8,
            "Hypertension": 1,
            "Diabetes": 1,
            "Alcoholism": 1,
            "Disability": 1,
            "IMDDecile": 1,
        }
        result = predictor.predict(patient)
        assert result["probability"] > 0.5

    def test_low_risk_patient(self, predictor):
        patient = {
            "Age": 30,
            "Gender": 1,
            "AppointmentLeadTimeDays": 1,
            "SMSReceived": 1,
            "PriorDNACount": 0,
            "Hypertension": 0,
            "Diabetes": 0,
            "Alcoholism": 0,
            "Disability": 0,
            "IMDDecile": 10,
        }
        result = predictor.predict(patient)
        assert result["probability"] < 0.5

    def test_risk_tier_low(self):
        assert CareAttendPredictor._risk_tier(0.20) == "Low"

    def test_risk_tier_medium(self):
        assert CareAttendPredictor._risk_tier(0.50) == "Medium"

    def test_risk_tier_high(self):
        assert CareAttendPredictor._risk_tier(0.80) == "High"

    def test_risk_tier_uses_saved_high_threshold(self):
        assert CareAttendPredictor._risk_tier(0.59, high_threshold=0.60) == "Medium"
        assert CareAttendPredictor._risk_tier(0.60, high_threshold=0.60) == "High"
