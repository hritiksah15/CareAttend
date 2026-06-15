"""Integration tests closing the traceability-matrix gaps.

Covers the endpoints previously marked manual-only: practice dashboard (US-002),
mock EHR (Feature 10), feedback loop (Feature 12), NL summary (Feature 13),
multi-trust config (Feature 14), rigorous evaluation (Feature 15), NHSX ethics
mapping (Feature 19), and model info/comparison/export.

Goal: every Must requirement and shipped feature traces to an automated test.
"""

import json
import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

pytestmark = pytest.mark.skipif(
    not os.path.exists("models/model.joblib"),
    reason="Models not trained yet",
)

import app as app_module  # noqa: E402
from app import app as flask_app, load_models  # noqa: E402
from models import db  # noqa: E402


@pytest.fixture(scope="module")
def app():
    flask_app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///:memory:"
    flask_app.config["TESTING"] = True
    with flask_app.app_context():
        db.create_all()
        load_models()
        yield flask_app
        db.session.remove()
        db.drop_all()


@pytest.fixture
def client(app):
    with app.test_client() as c:
        yield c


@pytest.fixture(autouse=True)
def clean_state(app):
    with app.app_context():
        yield
        for table in ("carer_proxies", "audit_logs", "feedback", "sessions", "users"):
            db.session.execute(db.text(f"DELETE FROM {table}"))
        db.session.commit()
    app_module._prediction_log.clear()
    app_module._notification_queue.clear()


def login(client, username="test", role="staff"):
    client.post("/auth/register", json={
        "username": username, "email": f"{username}@nhs.uk",
        "password": "password123", "role": role,
    })
    res = client.post("/auth/login", json={
        "username": username, "password": "password123",
    })
    return json.loads(res.data)["token"]


def auth(token):
    return {"Authorization": f"Bearer {token}"}


HIGH_RISK_PATIENT = {
    "Age": 80, "Gender": 0, "AppointmentLeadTimeDays": 28,
    "SMSReceived": 0, "PriorDNACount": 6, "IMDDecile": 1, "Disability": 1,
}


def make_prediction(client, token, patient=None):
    res = client.post("/api/predict", headers=auth(token),
                      json=patient or HIGH_RISK_PATIENT)
    return json.loads(res.data)


# ── Practice Dashboard (US-002) ──

class TestDashboard:
    def test_requires_auth(self, client):
        assert client.get("/api/dashboard").status_code == 401

    def test_empty_state(self, client):
        token = login(client)
        res = client.get("/api/dashboard", headers=auth(token))
        assert res.status_code == 200
        assert json.loads(res.data)["total"] == 0

    def test_counts_after_prediction(self, client):
        token = login(client)
        make_prediction(client, token)
        res = client.get("/api/dashboard", headers=auth(token))
        data = json.loads(res.data)
        assert data["total"] == 1
        assert data["high_risk"] + data["medium_risk"] + data["low_risk"] == 1
        assert "age_breakdown" in data
        assert len(data["recent_assessments"]) == 1


# ── NL Summary (Feature 13) ──

class TestNLSummary:
    def test_summary_present_and_descriptive(self, client):
        token = login(client)
        data = make_prediction(client, token)
        assert "nl_summary" in data
        assert "80-year-old" in data["nl_summary"]
        assert "%" in data["nl_summary"]


# ── Feedback Loop (Feature 12) ──

class TestFeedback:
    def test_requires_auth(self, client):
        assert client.post("/api/feedback", json={}).status_code == 401

    def test_invalid_outcome(self, client):
        token = login(client)
        res = client.post("/api/feedback", headers=auth(token),
                          json={"prediction_id": "x", "outcome": "maybe"})
        assert res.status_code == 400

    def test_unknown_prediction(self, client):
        token = login(client)
        res = client.post("/api/feedback", headers=auth(token),
                          json={"prediction_id": "does-not-exist", "outcome": "dna"})
        assert res.status_code == 404

    def test_record_and_summary(self, client):
        token = login(client)
        pred = make_prediction(client, token)
        rec = client.post("/api/feedback", headers=auth(token),
                          json={"prediction_id": pred["sessionId"], "outcome": "dna"})
        assert rec.status_code == 200
        summ = client.get("/api/feedback/summary", headers=auth(token))
        data = json.loads(summ.data)
        assert data["feedback_received"] == 1
        assert data["correct"] == 1
        assert data["accuracy"] == 1.0

    def test_feedback_persisted_to_db(self, client, app):
        token = login(client)
        pred = make_prediction(client, token)
        client.post("/api/feedback", headers=auth(token),
                    json={"prediction_id": pred["sessionId"], "outcome": "dna"})
        from models import PersistentFeedback
        with app.app_context():
            rows = PersistentFeedback.query.all()
            assert len(rows) == 1
            assert rows[0].outcome == "dna"


# ── Mock EHR (Feature 10) ──

class TestEHR:
    def test_requires_auth(self, client):
        assert client.get("/api/ehr/lookup/NHS001").status_code == 401

    def test_lookup_found(self, client):
        token = login(client)
        res = client.get("/api/ehr/lookup/NHS001", headers=auth(token))
        assert res.status_code == 200
        assert json.loads(res.data)["patient"]["Age"] == 78

    def test_lookup_not_found(self, client):
        token = login(client)
        res = client.get("/api/ehr/lookup/NHS999", headers=auth(token))
        assert res.status_code == 404

    def test_list_patients(self, client):
        token = login(client)
        res = client.get("/api/ehr/patients", headers=auth(token))
        assert "NHS001" in json.loads(res.data)["patients"]


# ── Multi-Trust Config (Feature 14) ──

class TestTrusts:
    def test_list(self, client):
        token = login(client)
        res = client.get("/api/trusts", headers=auth(token))
        assert "tower_hamlets" in json.loads(res.data)["trusts"]

    def test_get_one(self, client):
        token = login(client)
        res = client.get("/api/trusts/belfast", headers=auth(token))
        assert res.status_code == 200
        assert json.loads(res.data)["region"] == "Northern Ireland"

    def test_unknown_trust(self, client):
        token = login(client)
        assert client.get("/api/trusts/atlantis", headers=auth(token)).status_code == 404


# ── NHSX Ethics Mapping (Feature 19) ──

class TestEthicsFramework:
    def test_requires_auth(self, client):
        assert client.get("/api/ethics-framework").status_code == 401

    def test_six_principles(self, client):
        token = login(client)
        res = client.get("/api/ethics-framework", headers=auth(token))
        data = json.loads(res.data)
        assert len(data["principles"]) == 6
        assert all("evidence" in p for p in data["principles"])


# ── Model Info / Comparison / Export ──

class TestModelInfo:
    def test_model_info(self, client):
        token = login(client)
        res = client.get("/api/model-info", headers=auth(token))
        assert res.status_code in (200, 404)

    def test_model_comparison(self, client):
        token = login(client)
        res = client.get("/api/model-comparison", headers=auth(token))
        if res.status_code == 200:
            assert "selected_model" in json.loads(res.data)

    def test_export_model(self, client):
        token = login(client)
        res = client.get("/api/export-model", headers=auth(token))
        assert res.status_code == 200
        assert "features" in json.loads(res.data)


# ── Rigorous Evaluation / Cross-Validation (Feature 15) ──

class TestCrossValidation:
    @pytest.mark.skipif(
        not (os.path.exists("data/synthetic_dataset.csv")
             and os.path.exists("models/test_data.csv")),
        reason="Evaluation datasets not present",
    )
    def test_cv_runs(self, client):
        token = login(client)
        res = client.post("/api/evaluation/cross-validation", headers=auth(token))
        assert res.status_code == 200
        data = json.loads(res.data)
        assert isinstance(data, (dict, list))
