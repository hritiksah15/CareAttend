"""Tests for the authentication module (FR-04, NFR-06)."""

import pytest
import time
from app import app as flask_app
from models import db, User, Session as DBSession  # noqa: F811
from auth import (
    register_user, authenticate, validate_token, logout,
    _hash_password, _verify_password, SESSION_TIMEOUT,
)


@pytest.fixture
def app():
    flask_app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///:memory:"
    flask_app.config["TESTING"] = True
    with flask_app.app_context():
        db.create_all()
        yield flask_app
        db.session.remove()
        db.drop_all()


@pytest.fixture
def ctx(app):
    with app.app_context():
        yield


class TestPasswordHashing:
    def test_hash_and_verify(self):
        hashed = _hash_password("testpass123")
        assert _verify_password("testpass123", hashed)

    def test_wrong_password_fails(self):
        hashed = _hash_password("testpass123")
        assert not _verify_password("wrongpass", hashed)

    def test_hash_not_plaintext(self):
        hashed = _hash_password("testpass123")
        assert hashed != "testpass123"


class TestRegistration:
    def test_register_success(self, ctx):
        uid, err = register_user("asha", "asha@nhs.uk", "password123")
        assert uid is not None
        assert err is None

    def test_register_missing_fields(self, ctx):
        uid, err = register_user("", "asha@nhs.uk", "password123")
        assert uid is None
        assert "required" in err.lower()

    def test_register_short_password(self, ctx):
        uid, err = register_user("asha", "asha@nhs.uk", "short")
        assert uid is None
        assert "8 characters" in err

    def test_register_duplicate_email(self, ctx):
        register_user("asha", "asha@nhs.uk", "password123")
        uid, err = register_user("mukesh", "asha@nhs.uk", "password456")
        assert uid is None
        assert "already" in err.lower()

    def test_register_duplicate_username(self, ctx):
        register_user("asha", "asha@nhs.uk", "password123")
        uid, err = register_user("asha", "other@nhs.uk", "password456")
        assert uid is None
        assert "already" in err.lower()

    def test_register_with_role(self, ctx):
        uid, _ = register_user("admin1", "admin@nhs.uk", "password123", role="admin")
        assert uid is not None
        user = User.query.filter_by(username="admin1").first()
        assert user.role == "admin"


class TestAuthentication:
    def test_login_success(self, ctx):
        register_user("asha", "asha@nhs.uk", "password123")
        token, err = authenticate("asha", "password123")
        assert token is not None
        assert err is None

    def test_login_wrong_password(self, ctx):
        register_user("asha", "asha@nhs.uk", "password123")
        token, err = authenticate("asha", "wrongpass")
        assert token is None
        assert "invalid" in err.lower()

    def test_login_nonexistent_user(self, ctx):
        token, err = authenticate("nobody", "password123")
        assert token is None

    def test_token_validation(self, ctx):
        register_user("asha", "asha@nhs.uk", "password123")
        token, _ = authenticate("asha", "password123")
        session = validate_token(token)
        assert session is not None
        assert session["username"] == "asha"

    def test_invalid_token(self, ctx):
        session = validate_token("fake-token-12345")
        assert session is None


class TestSessionManagement:
    def test_logout_clears_session(self, ctx):
        register_user("asha", "asha@nhs.uk", "password123")
        token, _ = authenticate("asha", "password123")
        logout(token)
        assert validate_token(token) is None

    def test_session_timeout(self, ctx):
        register_user("asha", "asha@nhs.uk", "password123")
        token, _ = authenticate("asha", "password123")
        session = db.session.get(DBSession, token)
        session.last_activity = time.time() - SESSION_TIMEOUT - 1
        db.session.commit()
        assert validate_token(token) is None

    def test_session_refresh_on_activity(self, ctx):
        register_user("asha", "asha@nhs.uk", "password123")
        token, _ = authenticate("asha", "password123")
        session = db.session.get(DBSession, token)
        old_time = session.last_activity
        time.sleep(0.01)
        validate_token(token)
        db.session.refresh(session)
        assert session.last_activity > old_time

    def test_timeout_constant(self):
        assert SESSION_TIMEOUT == 1800
