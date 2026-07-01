"""Tests for operational robustness: health probe + uniform JSON errors.

Evidence that the API fails safely (JSON, not HTML stack traces) and exposes a
readiness probe for Docker / load balancers (AT4 QA, production-grade signal).
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


class TestHealth:
    def test_health_no_auth_required(self, client):
        res = client.get("/health")
        assert res.status_code == 200

    def test_health_payload(self, client):
        data = json.loads(client.get("/health").data)
        assert data["status"] == "ok"
        assert data["model_loaded"] is True
        assert data["database"] == "ok"
        assert data["auth_tables"] == "ok"
        assert "uptime_seconds" in data

    def test_security_headers_present(self, client):
        res = client.get("/health")
        assert res.headers["X-Content-Type-Options"] == "nosniff"
        assert res.headers["X-Frame-Options"] == "DENY"
        assert res.headers["Referrer-Policy"] == "strict-origin-when-cross-origin"


class TestJSONErrors:
    def test_404_is_json(self, client):
        res = client.get("/api/nonexistent-route")
        assert res.status_code == 404
        assert res.is_json
        assert json.loads(res.data)["error"] == "Not found"

    def test_405_is_json(self, client):
        # /api/predict is POST-only; GET should be a JSON 405.
        res = client.get("/api/predict")
        assert res.status_code == 405
        assert res.is_json
        assert "Method not allowed" in json.loads(res.data)["error"]

    def test_bad_json_does_not_500(self, client):
        # Malformed body to a JSON endpoint must not leak an HTML 500.
        res = client.post("/auth/login", data="{not json", content_type="application/json")
        assert res.status_code in (400, 401)
        assert res.is_json
