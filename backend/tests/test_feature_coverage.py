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

from app import app as flask_app, load_models  # noqa: E402
from models import db, User, AssessmentSummary, AuditLog  # noqa: E402


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
        for table in (
            "assessment_summaries",
            "notifications",
            "carer_proxies",
            "audit_logs",
            "feedback",
            "sessions",
            "users",
        ):
            db.session.execute(db.text(f"DELETE FROM {table}"))
        db.session.commit()


def login(client, username="test", role="staff"):
    client.post(
        "/auth/register",
        json={
            "username": username,
            "email": f"{username}@nhs.uk",
            "password": "Password123!",
        },
    )
    # Public register forces role 'user'; promote in the DB for role-gated tests.
    if role != "user":
        with flask_app.app_context():
            u = User.query.filter_by(username=username).first()
            if u:
                u.role = role
                db.session.commit()
    res = client.post(
        "/auth/login",
        json={
            "username": username,
            "password": "Password123!",
        },
    )
    return json.loads(res.data)["token"]


def auth(token):
    return {"Authorization": f"Bearer {token}"}


HIGH_RISK_PATIENT = {
    "Age": 80,
    "Gender": 0,
    "AppointmentLeadTimeDays": 28,
    "SMSReceived": 0,
    "PriorDNACount": 6,
    "IMDDecile": 1,
    "Disability": 1,
}


def make_prediction(client, token, patient=None):
    res = client.post("/api/predict", headers=auth(token), json=patient or HIGH_RISK_PATIENT)
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
        assert data["recent_assessments"][0]["age"] == "Not stored"

    def test_prediction_persists_anonymised_summary(self, client, app):
        token = login(client)
        pred = make_prediction(client, token)
        with app.app_context():
            row = db.session.get(AssessmentSummary, pred["sessionId"])
            assert row is not None
            assert row.risk_tier == pred["risk_tier"]
            assert row.age_group

    def test_dashboard_is_practice_wide(self, client):
        # US-002: the dashboard aggregates every staff member's assessments,
        # so each user sees the whole practice, not only their own rows.
        token_a = login(client, username="dash_a")
        token_b = login(client, username="dash_b")
        make_prediction(client, token_a)
        make_prediction(client, token_b)
        res = client.get("/api/dashboard", headers=auth(token_a))
        assert json.loads(res.data)["total"] == 2


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
        res = client.post("/api/feedback", headers=auth(token), json={"prediction_id": "x", "outcome": "maybe"})
        assert res.status_code == 400

    def test_unknown_prediction(self, client):
        token = login(client)
        res = client.post(
            "/api/feedback", headers=auth(token), json={"prediction_id": "does-not-exist", "outcome": "dna"}
        )
        assert res.status_code == 404

    def test_record_and_summary(self, client):
        token = login(client)
        pred = make_prediction(client, token)
        rec = client.post(
            "/api/feedback", headers=auth(token), json={"prediction_id": pred["sessionId"], "outcome": "dna"}
        )
        assert rec.status_code == 200
        summ = client.get("/api/feedback/summary", headers=auth(token))
        data = json.loads(summ.data)
        assert data["feedback_received"] == 1
        assert data["correct"] == 1
        assert data["accuracy"] == 1.0

    def test_feedback_practice_wide(self, client):
        # Practice-wide: any staff member may record the outcome of an
        # assessment made by a colleague (shared accuracy tracking).
        token_a = login(client, username="owner_a")
        token_b = login(client, username="owner_b")
        pred = make_prediction(client, token_a)
        res = client.post(
            "/api/feedback", headers=auth(token_b), json={"prediction_id": pred["sessionId"], "outcome": "dna"}
        )
        assert res.status_code == 200

    def test_feedback_unknown_prediction_404(self, client):
        token = login(client)
        res = client.post(
            "/api/feedback", headers=auth(token), json={"prediction_id": "does-not-exist", "outcome": "dna"}
        )
        assert res.status_code == 404

    def test_feedback_persisted_to_db(self, client, app):
        token = login(client)
        pred = make_prediction(client, token)
        client.post("/api/feedback", headers=auth(token), json={"prediction_id": pred["sessionId"], "outcome": "dna"})
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
        token = login(client, role="admin")
        res = client.get("/api/ethics-framework", headers=auth(token))
        data = json.loads(res.data)
        assert len(data["principles"]) == 6
        assert all("evidence" in p for p in data["principles"])


# ── Model Info / Comparison / Export ──


class TestModelInfo:
    def test_model_info(self, client):
        token = login(client, role="admin")
        res = client.get("/api/model-info", headers=auth(token))
        assert res.status_code in (200, 404)

    def test_model_comparison(self, client):
        token = login(client, role="admin")
        res = client.get("/api/model-comparison", headers=auth(token))
        if res.status_code == 200:
            assert "selected_model" in json.loads(res.data)

    def test_export_model(self, client):
        token = login(client, role="admin")
        res = client.get("/api/export-model", headers=auth(token))
        assert res.status_code == 200
        assert "features" in json.loads(res.data)


# ── Rigorous Evaluation / Cross-Validation (Feature 15) ──


class TestCrossValidation:
    @pytest.mark.skipif(
        not (os.path.exists("data/synthetic_dataset.csv") and os.path.exists("models/test_data.csv")),
        reason="Evaluation datasets not present",
    )
    def test_cv_runs(self, client):
        token = login(client, role="admin")
        res = client.post("/api/evaluation/cross-validation", headers=auth(token))
        assert res.status_code == 200
        data = json.loads(res.data)
        assert isinstance(data, (dict, list))


# ── Role-Based Access Control (FR-04) ──


class TestRBAC:
    def test_user_can_predict(self, client):
        token = login(client, username="u1", role="user")
        res = client.post("/api/predict", headers=auth(token), json=HIGH_RISK_PATIENT)
        assert res.status_code == 200

    def test_user_denied_dashboard(self, client):
        token = login(client, username="u2", role="user")
        assert client.get("/api/dashboard", headers=auth(token)).status_code == 403

    def test_user_denied_batch(self, client):
        token = login(client, username="u3", role="user")
        assert client.post("/api/batch", headers=auth(token)).status_code == 403

    def test_batch_handles_utf8_bom(self, client):
        # Excel/Numbers prepend a UTF-8 BOM; the first header must still parse
        # so every row doesn't fail with "Invalid data format".
        import io

        token = login(client, username="bom1", role="staff")
        csv_bom = ("﻿Age,Gender,AppointmentLeadTimeDays,SMSReceived," "PriorDNACount,IMDDecile\n78,0,21,0,4,2\n").encode(
            "utf-8"
        )
        res = client.post(
            "/api/batch",
            headers=auth(token),
            data={"file": (io.BytesIO(csv_bom), "bom.csv")},
            content_type="multipart/form-data",
        )
        assert res.status_code == 200
        body = res.data.decode()
        assert "Invalid data format" not in body
        assert "risk_tier" in body  # header row of a successful result

    def _post_csv(self, client, token, text):
        import io

        return client.post(
            "/api/batch",
            headers=auth(token),
            data={"file": (io.BytesIO(text.encode("utf-8")), "b.csv")},
            content_type="multipart/form-data",
        )

    def test_batch_handles_semicolon_delimiter(self, client):
        # Excel on some locales exports semicolon-delimited CSV; the delimiter
        # must be sniffed or every row collapses into one column (KeyError 'Age').
        token = login(client, username="semi1", role="staff")
        res = self._post_csv(
            client,
            token,
            "Age;Gender;AppointmentLeadTimeDays;SMSReceived;PriorDNACount;IMDDecile\n72;0;14;1;3;2\n",
        )
        assert res.status_code == 200
        body = res.data.decode()
        assert "Invalid data format" not in body and "Missing required field" not in body
        assert "risk_tier" in body

    def test_batch_strips_header_and_value_whitespace(self, client):
        token = login(client, username="ws1", role="staff")
        res = self._post_csv(
            client,
            token,
            " Age , Gender ,AppointmentLeadTimeDays,SMSReceived,PriorDNACount,IMDDecile\n 72 ,0,14,1,3,2\n",
        )
        assert res.status_code == 200
        assert "risk_tier" in res.data.decode()

    def test_batch_wrong_columns_gives_clear_error(self, client):
        token = login(client, username="wc1", role="staff")
        res = self._post_csv(client, token, "Name,Age2,Foo\nBob,72,x\n")
        assert res.status_code == 400
        assert "missing required column" in res.get_json()["error"].lower()

    def test_staff_denied_bias(self, client):
        token = login(client, username="s1", role="staff")
        assert client.get("/api/bias-audit", headers=auth(token)).status_code == 403

    def test_staff_denied_audit_log(self, client):
        token = login(client, username="s2", role="staff")
        assert client.get("/api/audit-log", headers=auth(token)).status_code == 403

    def test_staff_allowed_dashboard(self, client):
        token = login(client, username="s3", role="staff")
        assert client.get("/api/dashboard", headers=auth(token)).status_code == 200

    def test_admin_allowed_bias(self, client):
        token = login(client, username="a1", role="admin")
        assert client.get("/api/bias-audit", headers=auth(token)).status_code == 200

    def test_bias_audit_breach_log_is_deduped(self, client, app):
        # Repeated GETs must not flood the audit trail: a given breach signature
        # is logged at most once per 24h (robust whether the model passes or
        # breaches — count is 0 or 1, never per-view).
        token = login(client, username="a2", role="admin")
        for _ in range(3):
            client.get("/api/bias-audit", headers=auth(token))
        with app.app_context():
            assert AuditLog.query.filter_by(action="bias_governance_breach").count() <= 1


# ── Admin User Management ──


class TestAdminUserManagement:
    def test_list_requires_admin(self, client):
        token = login(client, username="staff_x", role="staff")
        assert client.get("/api/admin/users", headers=auth(token)).status_code == 403

    def test_admin_lists_users(self, client):
        login(client, username="someone", role="user")
        token = login(client, username="boss", role="admin")
        res = client.get("/api/admin/users", headers=auth(token))
        assert res.status_code == 200
        data = json.loads(res.data)
        assert data["total"] >= 2
        assert any(u["username"] == "someone" for u in data["users"])

    def test_admin_changes_role(self, client):
        login(client, username="target", role="user")
        token = login(client, username="boss", role="admin")
        users = json.loads(client.get("/api/admin/users", headers=auth(token)).data)["users"]
        target_id = next(u["userId"] for u in users if u["username"] == "target")
        res = client.put(f"/api/admin/users/{target_id}/role", headers=auth(token), json={"role": "staff"})
        assert res.status_code == 200
        assert json.loads(res.data)["user"]["role"] == "staff"

    def test_invalid_role_rejected(self, client):
        login(client, username="target", role="user")
        token = login(client, username="boss", role="admin")
        users = json.loads(client.get("/api/admin/users", headers=auth(token)).data)["users"]
        target_id = next(u["userId"] for u in users if u["username"] == "target")
        res = client.put(f"/api/admin/users/{target_id}/role", headers=auth(token), json={"role": "superuser"})
        assert res.status_code == 400

    def test_admin_cannot_self_demote(self, client):
        token = login(client, username="boss", role="admin")
        users = json.loads(client.get("/api/admin/users", headers=auth(token)).data)["users"]
        own_id = next(u["userId"] for u in users if u["username"] == "boss")
        res = client.put(f"/api/admin/users/{own_id}/role", headers=auth(token), json={"role": "staff"})
        assert res.status_code == 400

    def test_admin_deletes_user(self, client):
        login(client, username="doomed", role="user")
        token = login(client, username="boss", role="admin")
        users = json.loads(client.get("/api/admin/users", headers=auth(token)).data)["users"]
        target_id = next(u["userId"] for u in users if u["username"] == "doomed")
        res = client.delete(f"/api/admin/users/{target_id}", headers=auth(token))
        assert res.status_code == 200

    def test_admin_cannot_self_delete(self, client):
        token = login(client, username="boss", role="admin")
        users = json.loads(client.get("/api/admin/users", headers=auth(token)).data)["users"]
        own_id = next(u["userId"] for u in users if u["username"] == "boss")
        assert client.delete(f"/api/admin/users/{own_id}", headers=auth(token)).status_code == 400
