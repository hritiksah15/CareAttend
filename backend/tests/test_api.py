"""Integration tests for Flask API endpoints (FR-01 to FR-08, NFR-01, NFR-06)."""

import pytest
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

pytestmark = pytest.mark.skipif(not os.path.exists("models/model.joblib"), reason="Models not trained yet")

from app import app as flask_app, load_models, _clear_login_failures
from models import db, User


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
def clean_auth(app):
    with app.app_context():
        yield
        _clear_login_failures()
        db.session.execute(db.text("DELETE FROM assessment_summaries"))
        db.session.execute(db.text("DELETE FROM notifications"))
        db.session.execute(db.text("DELETE FROM sessions"))
        db.session.execute(db.text("DELETE FROM users"))
        db.session.commit()


def register_and_login(client, role="staff"):
    client.post("/auth/register", json={"username": "test", "email": "test@nhs.uk", "password": "Password123!"})
    # Public register always creates a 'user'; promote in the DB so role-gated
    # endpoint tests get the privilege they need (admins do this via the Admin tab).
    if role != "user":
        u = User.query.filter_by(username="test").first()
        u.role = role
        db.session.commit()
    res = client.post("/auth/login", json={"username": "test", "password": "Password123!"})
    return json.loads(res.data)["token"]


class TestAuthEndpoints:
    def test_register(self, client):
        res = client.post(
            "/auth/register", json={"username": "asha", "email": "asha@nhs.uk", "password": "Password123!"}
        )
        assert res.status_code == 201

    def test_register_forces_user_role(self, client):
        # Privilege-escalation guard: a 'role' in the body must be ignored.
        res = client.post(
            "/auth/register",
            json={"username": "sneaky", "email": "sneaky@nhs.uk", "password": "Password123!", "role": "admin"},
        )
        assert res.status_code == 201
        with client.application.app_context():
            assert User.query.filter_by(username="sneaky").first().role == "user"

    def test_register_missing_fields(self, client):
        res = client.post("/auth/register", json={"username": "", "email": "a@b.com", "password": "pass1234"})
        assert res.status_code == 400

    def test_login(self, client):
        client.post("/auth/register", json={"username": "asha", "email": "asha@nhs.uk", "password": "Password123!"})
        res = client.post("/auth/login", json={"username": "asha", "password": "Password123!"})
        assert res.status_code == 200
        data = json.loads(res.data)
        assert "token" in data

    def test_login_by_email(self, client):
        client.post("/auth/register", json={"username": "asha", "email": "asha@nhs.uk", "password": "Password123!"})
        res = client.post("/auth/login", json={"username": "asha@nhs.uk", "password": "Password123!"})
        assert res.status_code == 200
        assert "token" in json.loads(res.data)

    def test_update_profile_fields(self, client):
        token = register_and_login(client, role="user")
        res = client.put(
            "/api/profile",
            headers={"Authorization": f"Bearer {token}"},
            json={"jobTitle": "Practice Nurse", "department": "Cardiology", "pronouns": "she/her", "bio": "Hi"},
        )
        assert res.status_code == 200
        data = json.loads(res.data)
        assert data["jobTitle"] == "Practice Nurse"
        assert data["department"] == "Cardiology"
        assert data["pronouns"] == "she/her"

    def test_update_profile_rejects_bad_avatar(self, client):
        token = register_and_login(client, role="user")
        res = client.put("/api/profile", headers={"Authorization": f"Bearer {token}"}, json={"avatar": "not-an-image"})
        assert res.status_code == 400

    def test_login_rejects_oversized_totp(self, client):
        # Oversized 2FA code is rejected early (DoS guard), not passed to verifier.
        client.post("/auth/register", json={"username": "asha", "email": "asha@nhs.uk", "password": "Password123!"})
        res = client.post("/auth/login", json={"username": "asha", "password": "Password123!", "totp_code": "0" * 5000})
        assert res.status_code == 401

    def test_login_wrong_password(self, client):
        client.post("/auth/register", json={"username": "asha", "email": "asha@nhs.uk", "password": "Password123!"})
        res = client.post("/auth/login", json={"username": "asha", "password": "wrong"})
        assert res.status_code == 401

    def test_login_rate_limit_failed_attempts(self, client):
        client.post(
            "/auth/register",
            json={"username": "asha", "email": "asha@nhs.uk", "password": "Password123!"},
        )
        for _ in range(5):
            res = client.post("/auth/login", json={"username": "asha", "password": "wrong"})
            assert res.status_code == 401

        res = client.post("/auth/login", json={"username": "asha", "password": "wrong"})
        assert res.status_code == 429
        assert res.headers.get("Retry-After")

    def test_logout(self, client):
        token = register_and_login(client)
        res = client.post("/auth/logout", headers={"Authorization": f"Bearer {token}"})
        assert res.status_code == 200


class TestPredictEndpoint:
    def test_predict_requires_auth(self, client):
        res = client.post("/api/predict", json={"Age": 72})
        assert res.status_code == 401

    def test_predict_success(self, client):
        token = register_and_login(client)
        res = client.post(
            "/api/predict",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "Age": 72,
                "Gender": 0,
                "AppointmentLeadTimeDays": 14,
                "SMSReceived": 0,
                "PriorDNACount": 3,
                "IMDDecile": 2,
            },
        )
        assert res.status_code == 200
        data = json.loads(res.data)
        assert "probability" in data
        assert "risk_tier" in data
        assert "shap_values" in data
        assert "interventions" in data
        assert "age_group" in data
        assert "sessionId" in data

    def test_predict_missing_fields(self, client):
        token = register_and_login(client)
        res = client.post("/api/predict", headers={"Authorization": f"Bearer {token}"}, json={"Age": 72})
        assert res.status_code == 400

    def test_predict_invalid_age(self, client):
        token = register_and_login(client)
        res = client.post(
            "/api/predict",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "Age": 200,
                "Gender": 0,
                "AppointmentLeadTimeDays": 14,
                "SMSReceived": 0,
                "PriorDNACount": 3,
                "IMDDecile": 2,
            },
        )
        assert res.status_code == 400

    def test_predict_invalid_imd(self, client):
        token = register_and_login(client)
        res = client.post(
            "/api/predict",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "Age": 40,
                "Gender": 1,
                "AppointmentLeadTimeDays": 7,
                "SMSReceived": 1,
                "PriorDNACount": 0,
                "IMDDecile": 15,
            },
        )
        assert res.status_code == 400


class TestBiasEndpoint:
    def test_bias_requires_auth(self, client):
        res = client.get("/api/bias-audit")
        assert res.status_code == 401

    def test_bias_audit_success(self, client):
        token = register_and_login(client, role="admin")
        res = client.get("/api/bias-audit", headers={"Authorization": f"Bearer {token}"})
        assert res.status_code == 200
        data = json.loads(res.data)
        assert "age_group" in data
        assert "gender" in data
        assert "imd_band" in data
