"""Integration tests for the advanced endpoints added in Sprint 3.

Covers: carer/family proxy mode, appointment slot optimisation, patient nudge
generator, TOTP 2FA lifecycle, admin audit log, push-notification scheduling,
and account-centre profile management.

Maps to AT4 Quality Assurance evidence and NFR-06 (security) — closes the
"new endpoints only tested manually" gap noted in the project summary.
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
from auth import setup_totp  # noqa: E402
from models import db, User, ScheduledNotification, OutreachAction, AuditLog  # noqa: E402

try:
    import pyotp

    HAS_PYOTP = True
except ImportError:
    HAS_PYOTP = False


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
    """Reset DB rows between tests."""
    with app.app_context():
        yield
        for table in (
            "assessment_summaries",
            "outreach_actions",
            "notifications",
            "carer_proxies",
            "audit_logs",
            "feedback",
            "sessions",
            "users",
        ):
            db.session.execute(db.text(f"DELETE FROM {table}"))
        db.session.commit()


# ── Helpers ──


def _register(client, username="test", role="staff"):
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


def login(client, username="test", role="staff"):
    """Register (if needed) and return a Bearer token for the user."""
    _register(client, username, role)
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


SAMPLE_PATIENT = {
    "Age": 78,
    "Gender": 0,
    "AppointmentLeadTimeDays": 21,
    "SMSReceived": 0,
    "PriorDNACount": 4,
    "IMDDecile": 2,
    "Disability": 1,
}


# ── Carer / Family Proxy Mode ──


class TestCarerProxy:
    def test_requires_auth(self, client):
        res = client.post("/api/carer-proxy", json={})
        assert res.status_code == 401

    def test_create_success(self, client):
        token = login(client)
        res = client.post(
            "/api/carer-proxy",
            headers=auth(token),
            json={
                "carerName": "Jane Doe",
                "relationship": "family",
                "patientIdentifier": "NHS001",
                "carerContact": "07700900000",
                "reason": "Patient has no smartphone",
            },
        )
        assert res.status_code == 201
        data = json.loads(res.data)
        assert data["proxy"]["carerName"] == "Jane Doe"
        assert data["proxy"]["carerRelationship"] == "family"
        assert "id" in data["proxy"]

    def test_missing_fields(self, client):
        token = login(client)
        res = client.post(
            "/api/carer-proxy",
            headers=auth(token),
            json={
                "carerName": "Jane Doe",
            },
        )
        assert res.status_code == 400

    def test_invalid_relationship(self, client):
        token = login(client)
        res = client.post(
            "/api/carer-proxy",
            headers=auth(token),
            json={
                "carerName": "Jane Doe",
                "relationship": "stranger",
                "patientIdentifier": "NHS001",
            },
        )
        assert res.status_code == 400

    def test_list_scoped_to_user(self, client):
        token = login(client)
        client.post(
            "/api/carer-proxy",
            headers=auth(token),
            json={
                "carerName": "Jane Doe",
                "relationship": "carer",
                "patientIdentifier": "NHS003",
            },
        )
        res = client.get("/api/carer-proxy/list", headers=auth(token))
        assert res.status_code == 200
        proxies = json.loads(res.data)["proxies"]
        assert len(proxies) == 1
        assert proxies[0]["patientIdentifier"] == "NHS003"

    def test_create_writes_audit_entry(self, client, app):
        token = login(client)
        client.post(
            "/api/carer-proxy",
            headers=auth(token),
            json={
                "carerName": "Jane Doe",
                "relationship": "social_worker",
                "patientIdentifier": "NHS002",
            },
        )
        from models import AuditLog

        with app.app_context():
            assert AuditLog.query.filter_by(action="carer_proxy_created").count() == 1


# ── Appointment Slot Optimisation ──


class TestSlotOptimisation:
    def test_requires_auth(self, client):
        res = client.post("/api/slot-optimisation", json={"appointments": []})
        assert res.status_code == 401

    def test_success(self, client):
        token = login(client)
        res = client.post(
            "/api/slot-optimisation",
            headers=auth(token),
            json={
                "appointments": [
                    {**SAMPLE_PATIENT, "slotMinutes": 15},
                    {
                        "Age": 30,
                        "Gender": 1,
                        "AppointmentLeadTimeDays": 3,
                        "SMSReceived": 1,
                        "PriorDNACount": 0,
                        "IMDDecile": 8,
                        "slotMinutes": 15,
                    },
                ],
            },
        )
        assert res.status_code == 200
        data = json.loads(res.data)
        assert len(data["slots"]) == 2
        assert data["summary"]["total_slots"] == 2
        assert "potential_recovery_percent" in data["summary"]
        for slot in data["slots"]:
            assert "dna_probability" in slot
            assert "recommendation" in slot

    def test_empty_rejected(self, client):
        token = login(client)
        res = client.post("/api/slot-optimisation", headers=auth(token), json={"appointments": []})
        assert res.status_code == 400

    def test_too_many_rejected(self, client):
        token = login(client)
        res = client.post("/api/slot-optimisation", headers=auth(token), json={"appointments": [SAMPLE_PATIENT] * 51})
        assert res.status_code == 400

    def test_invalid_row_reported_not_fatal(self, client):
        token = login(client)
        res = client.post(
            "/api/slot-optimisation",
            headers=auth(token),
            json={
                "appointments": [{"Age": 999}],
            },
        )
        assert res.status_code == 200
        assert "error" in json.loads(res.data)["slots"][0]


# ── Patient Nudge Generator ──


class TestPatientNudge:
    def test_requires_auth(self, client):
        res = client.post("/api/patient-nudge", json={})
        assert res.status_code == 401

    def test_missing_patient(self, client):
        token = login(client)
        res = client.post("/api/patient-nudge", headers=auth(token), json={})
        assert res.status_code == 400

    def test_elderly_gets_transport_nudge(self, client):
        token = login(client)
        res = client.post(
            "/api/patient-nudge",
            headers=auth(token),
            json={
                "patient": SAMPLE_PATIENT,
                "language": "en",
            },
        )
        assert res.status_code == 200
        data = json.loads(res.data)
        assert data["nudge_type"] == "transport"
        assert "elderly_patient" in data["personalisation_factors"]

    def test_unknown_language_falls_back_to_en(self, client):
        token = login(client)
        res = client.post(
            "/api/patient-nudge",
            headers=auth(token),
            json={
                "patient": SAMPLE_PATIENT,
                "language": "zz",
            },
        )
        assert res.status_code == 200
        assert json.loads(res.data)["language"] == "en"

    def test_welsh_message_returned(self, client):
        token = login(client)
        res = client.post(
            "/api/patient-nudge",
            headers=auth(token),
            json={
                "patient": SAMPLE_PATIENT,
                "language": "cy",
            },
        )
        data = json.loads(res.data)
        assert data["language"] == "cy"
        assert len(data["message"]) > 0

    def test_patient_name_personalisation(self, client):
        token = login(client)
        res = client.post(
            "/api/patient-nudge",
            headers=auth(token),
            json={
                "patient": SAMPLE_PATIENT,
                "patientName": "Margaret",
            },
        )
        assert json.loads(res.data)["message"].startswith("Dear Margaret,")


# ── 2FA / TOTP Lifecycle ──


class TestTwoFactor:
    def test_setup_requires_auth(self, client):
        res = client.post("/api/profile/2fa/setup")
        assert res.status_code == 401

    @pytest.mark.skipif(not HAS_PYOTP, reason="pyotp not installed")
    def test_setup_returns_secret(self, client):
        token = login(client)
        res = client.post("/api/profile/2fa/setup", headers=auth(token))
        assert res.status_code == 200
        data = json.loads(res.data)
        assert "secret" in data
        assert "uri" in data

    def test_enable_requires_code(self, client):
        token = login(client)
        res = client.post("/api/profile/2fa/enable", headers=auth(token), json={})
        assert res.status_code == 400

    def test_enable_rejects_bad_code(self, client):
        token = login(client)
        client.post("/api/profile/2fa/setup", headers=auth(token))
        res = client.post("/api/profile/2fa/enable", headers=auth(token), json={"code": "000000"})
        assert res.status_code == 400

    @pytest.mark.skipif(not HAS_PYOTP, reason="pyotp not installed")
    def test_full_cycle_enable_login_disable(self, client, app):
        token = login(client)
        with app.app_context():
            user = User.query.filter_by(username="test").first()
            secret_info, _ = setup_totp(user.id)
        valid_code = pyotp.TOTP(secret_info["secret"]).now()

        enable = client.post("/api/profile/2fa/enable", headers=auth(token), json={"code": valid_code})
        assert enable.status_code == 200

        # Login now demands the second factor.
        step1 = client.post(
            "/auth/login",
            json={
                "username": "test",
                "password": "Password123!",
            },
        )
        assert json.loads(step1.data).get("requires_2fa") is True

        step2 = client.post(
            "/auth/login",
            json={
                "username": "test",
                "password": "Password123!",
                "totp_code": pyotp.TOTP(secret_info["secret"]).now(),
            },
        )
        assert "token" in json.loads(step2.data)

        # Disabling needs the password, not the code.
        disable = client.post("/api/profile/2fa/disable", headers=auth(token), json={"password": "Password123!"})
        assert disable.status_code == 200

    def test_disable_requires_password(self, client):
        token = login(client)
        res = client.post("/api/profile/2fa/disable", headers=auth(token), json={})
        assert res.status_code == 400


# ── Admin Audit Log ──


class TestAuditLog:
    def test_requires_auth(self, client):
        res = client.get("/api/audit-log")
        assert res.status_code == 401

    def test_staff_forbidden(self, client):
        token = login(client, username="clerk", role="staff")
        res = client.get("/api/audit-log", headers=auth(token))
        assert res.status_code == 403

    def test_admin_allowed(self, client):
        token = login(client, username="boss", role="admin")
        res = client.get("/api/audit-log", headers=auth(token))
        assert res.status_code == 200
        assert "logs" in json.loads(res.data)

    def test_admin_sees_proxy_events(self, client):
        staff = login(client, username="clerk", role="staff")
        client.post(
            "/api/carer-proxy",
            headers=auth(staff),
            json={
                "carerName": "Jane",
                "relationship": "family",
                "patientIdentifier": "NHS001",
            },
        )
        admin = login(client, username="boss", role="admin")
        res = client.get("/api/audit-log", headers=auth(admin))
        logs = json.loads(res.data)["logs"]
        assert any(log["action"] == "carer_proxy_created" for log in logs)


# ── Forgot / Reset Password ──


class TestPasswordReset:
    def test_forgot_unknown_email_no_leak(self, client):
        # Should not reveal that the account does not exist, and no dev_code.
        res = client.post("/auth/forgot-password", json={"email": "nobody@nhs.uk"})
        assert res.status_code == 200
        assert "dev_code" not in json.loads(res.data)

    def test_forgot_missing_email(self, client):
        res = client.post("/auth/forgot-password", json={})
        assert res.status_code == 400

    def test_full_reset_flow(self, client):
        login(client, username="resetme")  # registers resetme@nhs.uk
        forgot = client.post("/auth/forgot-password", json={"email": "resetme@nhs.uk"})
        code = json.loads(forgot.data)["dev_code"]  # SMTP unset in tests
        reset = client.post(
            "/auth/reset-password",
            json={
                "email": "resetme@nhs.uk",
                "code": code,
                "newPassword": "Brandnew123!",
            },
        )
        assert reset.status_code == 200
        # Old password rejected, new password works.
        old = client.post("/auth/login", json={"username": "resetme", "password": "Password123!"})
        assert old.status_code == 401
        new = client.post("/auth/login", json={"username": "resetme", "password": "Brandnew123!"})
        assert "token" in json.loads(new.data)

    def test_reset_wrong_code(self, client):
        login(client, username="resetme2")
        client.post("/auth/forgot-password", json={"email": "resetme2@nhs.uk"})
        res = client.post(
            "/auth/reset-password",
            json={
                "email": "resetme2@nhs.uk",
                "code": "000000",
                "newPassword": "Brandnew123!",
            },
        )
        assert res.status_code == 400

    def test_reset_short_password(self, client):
        login(client, username="resetme3")
        code = json.loads(client.post("/auth/forgot-password", json={"email": "resetme3@nhs.uk"}).data)["dev_code"]
        res = client.post(
            "/auth/reset-password",
            json={
                "email": "resetme3@nhs.uk",
                "code": code,
                "newPassword": "short",
            },
        )
        assert res.status_code == 400


# ── Push Notification Scheduling ──


class TestNotifications:
    def test_requires_auth(self, client):
        res = client.post("/api/notifications/schedule", json={})
        assert res.status_code == 401

    def test_schedule_high_risk(self, client):
        token = login(client)
        res = client.post(
            "/api/notifications/schedule",
            headers=auth(token),
            json={
                "patient_id": "NHS001",
                "risk_tier": "High",
                "appointment_date": "2026-07-01",
            },
        )
        assert res.status_code == 201
        assert json.loads(res.data)["notification"]["status"] == "scheduled"

    def test_schedule_persists_and_audits(self, client, app):
        token = login(client)
        client.post(
            "/api/notifications/schedule",
            headers=auth(token),
            json={
                "patient_id": "NHS001",
                "risk_tier": "High",
                "appointment_date": "2026-07-01",
            },
        )
        with app.app_context():
            assert ScheduledNotification.query.filter_by(patient_id="NHS001").count() == 1
            assert AuditLog.query.filter_by(action="notification_scheduled").count() == 1

    def test_reject_low_risk(self, client):
        token = login(client)
        res = client.post(
            "/api/notifications/schedule",
            headers=auth(token),
            json={
                "patient_id": "NHS001",
                "risk_tier": "Low",
            },
        )
        assert res.status_code == 400

    def test_list(self, client):
        token = login(client)
        client.post(
            "/api/notifications/schedule",
            headers=auth(token),
            json={
                "patient_id": "NHS001",
                "risk_tier": "Medium",
            },
        )
        res = client.get("/api/notifications", headers=auth(token))
        assert json.loads(res.data)["total"] == 1

    def test_list_scoped_to_user(self, client):
        token_a = login(client, username="staffa")
        token_b = login(client, username="staffb")
        client.post(
            "/api/notifications/schedule",
            headers=auth(token_a),
            json={
                "patient_id": "NHS001",
                "risk_tier": "Medium",
            },
        )
        client.post(
            "/api/notifications/schedule",
            headers=auth(token_b),
            json={
                "patient_id": "NHS002",
                "risk_tier": "High",
            },
        )
        res = client.get("/api/notifications", headers=auth(token_a))
        data = json.loads(res.data)
        assert data["total"] == 1
        assert data["notifications"][0]["patient_id"] == "NHS001"


# ── Operational Action Tracking ──


class TestOutreachActions:
    def test_requires_auth(self, client):
        res = client.post("/api/actions", json={})
        assert res.status_code == 401

    def test_user_forbidden(self, client):
        token = login(client, username="patientuser", role="user")
        res = client.post("/api/actions", headers=auth(token), json={"patient_id": "NHS001", "action_type": "call"})
        assert res.status_code == 403

    def test_create_standalone_action(self, client, app):
        token = login(client)
        res = client.post(
            "/api/actions",
            headers=auth(token),
            json={
                "patient_id": "NHS001",
                "action_type": "transport",
                "risk_tier": "High",
                "status": "completed",
                "outcome": "transport_arranged",
                "notes": "Booked community transport",
            },
        )
        assert res.status_code == 201
        action = json.loads(res.data)["action"]
        assert action["status"] == "completed"
        assert action["completed_at"] is not None
        with app.app_context():
            assert OutreachAction.query.filter_by(patient_id="NHS001").count() == 1
            assert AuditLog.query.filter_by(action="outreach_action_created").count() == 1

    def test_create_action_from_notification(self, client, app):
        token = login(client)
        scheduled = client.post(
            "/api/notifications/schedule",
            headers=auth(token),
            json={"patient_id": "NHS001", "risk_tier": "High", "appointment_date": "2026-07-01"},
        )
        notification_id = json.loads(scheduled.data)["notification"]["id"]
        res = client.post(
            "/api/actions",
            headers=auth(token),
            json={"notification_id": notification_id, "action_type": "call", "status": "completed"},
        )
        assert res.status_code == 201
        action = json.loads(res.data)["action"]
        assert action["patient_id"] == "NHS001"
        assert action["risk_tier"] == "High"
        with app.app_context():
            assert db.session.get(ScheduledNotification, notification_id).status == "actioned"

    def test_notification_scoped_to_owner(self, client):
        token_a = login(client, username="staffa")
        token_b = login(client, username="staffb")
        scheduled = client.post(
            "/api/notifications/schedule",
            headers=auth(token_a),
            json={"patient_id": "NHS001", "risk_tier": "Medium"},
        )
        notification_id = json.loads(scheduled.data)["notification"]["id"]
        res = client.post(
            "/api/actions",
            headers=auth(token_b),
            json={"notification_id": notification_id, "action_type": "sms"},
        )
        assert res.status_code == 404

    def test_list_and_filter_actions(self, client):
        token = login(client)
        client.post("/api/actions", headers=auth(token), json={"patient_id": "NHS001", "action_type": "sms"})
        client.post(
            "/api/actions",
            headers=auth(token),
            json={"patient_id": "NHS002", "action_type": "call", "status": "completed", "outcome": "answered"},
        )
        res = client.get("/api/actions?status=completed", headers=auth(token))
        data = json.loads(res.data)
        assert data["total"] == 1
        assert data["actions"][0]["patient_id"] == "NHS002"

    def test_update_action(self, client, app):
        token = login(client)
        created = client.post("/api/actions", headers=auth(token), json={"patient_id": "NHS001", "action_type": "sms"})
        action_id = json.loads(created.data)["action"]["id"]
        res = client.patch(
            f"/api/actions/{action_id}",
            headers=auth(token),
            json={"status": "completed", "outcome": "sms_sent", "notes": "Reminder sent"},
        )
        assert res.status_code == 200
        action = json.loads(res.data)["action"]
        assert action["outcome"] == "sms_sent"
        assert action["completed_at"] is not None
        with app.app_context():
            assert AuditLog.query.filter_by(action="outreach_action_updated").count() == 1

    def test_invalid_action_type_rejected(self, client):
        token = login(client)
        res = client.post(
            "/api/actions",
            headers=auth(token),
            json={"patient_id": "NHS001", "action_type": "fax"},
        )
        assert res.status_code == 400


# ── Account Centre / Profile ──


class TestProfile:
    def test_requires_auth(self, client):
        res = client.get("/api/profile")
        assert res.status_code == 401

    def test_get_profile(self, client):
        token = login(client)
        res = client.get("/api/profile", headers=auth(token))
        assert res.status_code == 200
        assert json.loads(res.data)["username"] == "test"

    def test_update_display_name(self, client):
        token = login(client)
        res = client.put("/api/profile", headers=auth(token), json={"displayName": "Asha Patel"})
        assert res.status_code == 200
        assert json.loads(res.data)["displayName"] == "Asha Patel"

    def test_change_password_wrong_current(self, client):
        token = login(client)
        res = client.post(
            "/api/profile/change-password",
            headers=auth(token),
            json={
                "currentPassword": "wrong",
                "newPassword": "newPassword123!",
            },
        )
        assert res.status_code == 400

    def test_change_password_too_short(self, client):
        token = login(client)
        res = client.post(
            "/api/profile/change-password",
            headers=auth(token),
            json={
                "currentPassword": "Password123!",
                "newPassword": "short",
            },
        )
        assert res.status_code == 400

    def test_change_password_success(self, client):
        token = login(client)
        res = client.post(
            "/api/profile/change-password",
            headers=auth(token),
            json={
                "currentPassword": "Password123!",
                "newPassword": "Brandnewpass123!",
            },
        )
        assert res.status_code == 200

    def test_change_password_rejects_same(self, client):
        token = login(client)
        res = client.post(
            "/api/profile/change-password",
            headers=auth(token),
            json={
                "currentPassword": "Password123!",
                "newPassword": "Password123!",
            },
        )
        assert res.status_code == 400
        assert "different" in json.loads(res.data)["error"].lower()
