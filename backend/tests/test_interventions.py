"""Tests for the intervention engine (FR-05, FR-06)."""

import pytest
from ml.interventions import build_outreach_priority, generate_interventions, INTERVENTION_RULES


class TestInterventionGeneration:
    def test_returns_tuple(self):
        patient = {
            "Age": 72,
            "PriorDNACount": 3,
            "Disability": 0,
            "IMDDecile": 5,
            "AppointmentLeadTimeDays": 7,
            "SMSReceived": 1,
        }
        shap = [{"feature": "PriorDNACount", "value": 0.3}]
        result = generate_interventions(patient, 0.75, shap)
        assert len(result) == 3
        interventions, tier, age_group = result
        assert isinstance(interventions, list)
        assert tier in ("Low", "Medium", "High")
        assert isinstance(age_group, str)

    def test_high_prior_dna_triggers_phone(self):
        patient = {
            "Age": 40,
            "PriorDNACount": 5,
            "Disability": 0,
            "IMDDecile": 5,
            "AppointmentLeadTimeDays": 7,
            "SMSReceived": 1,
        }
        interventions, _, _ = generate_interventions(patient, 0.5, [])
        titles = [iv["title"] for iv in interventions]
        assert "Proactive Phone Reminder" in titles

    def test_elderly_triggers_transport(self):
        patient = {
            "Age": 70,
            "PriorDNACount": 0,
            "Disability": 0,
            "IMDDecile": 5,
            "AppointmentLeadTimeDays": 7,
            "SMSReceived": 1,
        }
        interventions, _, _ = generate_interventions(patient, 0.5, [])
        titles = [iv["title"] for iv in interventions]
        assert "Transport Assistance" in titles

    def test_85_plus_triggers_clinical_triage(self):
        patient = {
            "Age": 88,
            "PriorDNACount": 0,
            "Disability": 0,
            "IMDDecile": 5,
            "AppointmentLeadTimeDays": 7,
            "SMSReceived": 1,
        }
        interventions, _, age_group = generate_interventions(patient, 0.5, [])
        titles = [iv["title"] for iv in interventions]
        assert "Clinical Triage Escalation" in titles
        assert age_group == "85+"

    def test_disability_triggers_accessibility(self):
        patient = {
            "Age": 40,
            "PriorDNACount": 0,
            "Disability": 1,
            "IMDDecile": 5,
            "AppointmentLeadTimeDays": 7,
            "SMSReceived": 1,
        }
        interventions, _, _ = generate_interventions(patient, 0.5, [])
        titles = [iv["title"] for iv in interventions]
        assert "Accessibility Accommodation" in titles

    def test_deprived_triggers_social_support(self):
        patient = {
            "Age": 40,
            "PriorDNACount": 0,
            "Disability": 0,
            "IMDDecile": 2,
            "AppointmentLeadTimeDays": 7,
            "SMSReceived": 1,
        }
        interventions, _, _ = generate_interventions(patient, 0.5, [])
        titles = [iv["title"] for iv in interventions]
        assert "Social Support Referral" in titles

    def test_no_sms_triggers_followup(self):
        patient = {
            "Age": 40,
            "PriorDNACount": 0,
            "Disability": 0,
            "IMDDecile": 5,
            "AppointmentLeadTimeDays": 7,
            "SMSReceived": 0,
        }
        interventions, _, _ = generate_interventions(patient, 0.5, [])
        titles = [iv["title"] for iv in interventions]
        assert "Enhanced SMS Follow-up" in titles

    def test_max_five_interventions(self):
        patient = {
            "Age": 90,
            "PriorDNACount": 10,
            "Disability": 1,
            "IMDDecile": 1,
            "AppointmentLeadTimeDays": 30,
            "SMSReceived": 0,
        }
        interventions, _, _ = generate_interventions(patient, 0.9, [])
        assert len(interventions) <= 5

    def test_no_duplicates(self):
        patient = {
            "Age": 90,
            "PriorDNACount": 10,
            "Disability": 1,
            "IMDDecile": 1,
            "AppointmentLeadTimeDays": 30,
            "SMSReceived": 0,
        }
        interventions, _, _ = generate_interventions(patient, 0.9, [])
        titles = [iv["title"] for iv in interventions]
        assert len(titles) == len(set(titles))

    def test_sorted_by_priority(self):
        patient = {
            "Age": 90,
            "PriorDNACount": 10,
            "Disability": 1,
            "IMDDecile": 1,
            "AppointmentLeadTimeDays": 30,
            "SMSReceived": 0,
        }
        interventions, _, _ = generate_interventions(patient, 0.9, [])
        priorities = [iv["priority"] for iv in interventions]
        assert priorities == sorted(priorities)

    def test_age_and_condition_complexity_triggers_review(self):
        patient = {
            "Age": 66,
            "PriorDNACount": 0,
            "Diabetes": 1,
            "Hypertension": 0,
            "Alcoholism": 0,
            "Disability": 0,
            "IMDDecile": 5,
            "AppointmentLeadTimeDays": 7,
            "SMSReceived": 1,
        }
        interventions, _, _ = generate_interventions(patient, 0.5, [], "Medium")
        titles = [iv["title"] for iv in interventions]
        assert "Condition-Aware Outreach Review" in titles

    def test_outreach_priority_combines_risk_age_and_disease(self):
        patient = {
            "Age": 78,
            "PriorDNACount": 3,
            "Diabetes": 1,
            "Hypertension": 1,
            "Alcoholism": 0,
            "Disability": 0,
            "IMDDecile": 2,
            "AppointmentLeadTimeDays": 21,
            "SMSReceived": 0,
        }
        priority = build_outreach_priority(patient, "High")
        assert priority["level"] == "P1"
        assert priority["score"] >= 5
        assert "75-84 age group" in priority["drivers"]
        assert "diabetes" in priority["drivers"]

    def test_low_risk_without_age_or_disease_is_routine_priority(self):
        patient = {
            "Age": 40,
            "PriorDNACount": 0,
            "Diabetes": 0,
            "Hypertension": 0,
            "Alcoholism": 0,
            "Disability": 0,
            "IMDDecile": 8,
            "AppointmentLeadTimeDays": 3,
            "SMSReceived": 1,
        }
        priority = build_outreach_priority(patient, "Low")
        assert priority["level"] == "P3"
        assert priority["conditions"] == []
