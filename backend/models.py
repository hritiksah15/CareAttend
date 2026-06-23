"""SQLAlchemy models for Care Attend persistent storage.

User and Session models for authentication (FR-04, NFR-06).
ML prediction data stays session-scoped in memory per NFR-01.
"""

import uuid
import time

from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

db = SQLAlchemy()
migrate = Migrate()


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    username = db.Column(db.String(80), unique=True, nullable=False, index=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(256), nullable=False)
    role = db.Column(db.String(20), nullable=False, default="staff")
    display_name = db.Column(db.String(100), nullable=True)
    avatar = db.Column(db.Text, nullable=True)  # base64 data-URL (resized client-side)
    job_title = db.Column(db.String(100), nullable=True)
    department = db.Column(db.String(100), nullable=True)
    bio = db.Column(db.String(300), nullable=True)
    phone = db.Column(db.String(30), nullable=True)
    pronouns = db.Column(db.String(30), nullable=True)
    totp_secret = db.Column(db.String(32), nullable=True)
    totp_enabled = db.Column(db.Boolean, nullable=False, default=False)
    created_at = db.Column(db.Float, nullable=False, default=time.time)
    last_password_change = db.Column(db.Float, nullable=True)

    sessions = db.relationship("Session", backref="user", lazy=True, cascade="all, delete-orphan")

    def to_dict(self):
        return {
            "userId": self.id,
            "username": self.username,
            "email": self.email,
            "role": self.role,
            "displayName": self.display_name,
            "avatar": self.avatar,
            "jobTitle": self.job_title,
            "department": self.department,
            "bio": self.bio,
            "phone": self.phone,
            "pronouns": self.pronouns,
            "totpEnabled": self.totp_enabled,
            "createdAt": self.created_at,
            "lastPasswordChange": self.last_password_change,
        }


class Session(db.Model):
    __tablename__ = "sessions"

    token = db.Column(db.String(64), primary_key=True)
    user_id = db.Column(db.String(36), db.ForeignKey("users.id"), nullable=False)
    created_at = db.Column(db.Float, nullable=False, default=time.time)
    last_activity = db.Column(db.Float, nullable=False, default=time.time)
    remember = db.Column(db.Boolean, nullable=False, default=False)


class AuditLog(db.Model):
    __tablename__ = "audit_logs"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey("users.id"), nullable=False)
    action = db.Column(db.String(100), nullable=False)
    detail = db.Column(db.Text, nullable=True)
    ip_address = db.Column(db.String(45), nullable=True)
    created_at = db.Column(db.Float, nullable=False, default=time.time)

    user = db.relationship("User", backref=db.backref("audit_logs", lazy=True))

    def to_dict(self):
        return {
            "id": self.id,
            "userId": self.user_id,
            "action": self.action,
            "detail": self.detail,
            "ipAddress": self.ip_address,
            "createdAt": self.created_at,
        }


class PersistentFeedback(db.Model):
    __tablename__ = "feedback"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey("users.id"), nullable=False)
    prediction_risk_tier = db.Column(db.String(20), nullable=False)
    prediction_probability = db.Column(db.Float, nullable=False)
    outcome = db.Column(db.String(20), nullable=False)
    created_at = db.Column(db.Float, nullable=False, default=time.time)

    user = db.relationship("User", backref=db.backref("feedback_entries", lazy=True))

    def to_dict(self):
        return {
            "id": self.id,
            "userId": self.user_id,
            "riskTier": self.prediction_risk_tier,
            "probability": self.prediction_probability,
            "outcome": self.outcome,
            "createdAt": self.created_at,
        }


class CarerProxy(db.Model):
    __tablename__ = "carer_proxies"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    staff_user_id = db.Column(db.String(36), db.ForeignKey("users.id"), nullable=False)
    carer_name = db.Column(db.String(100), nullable=False)
    carer_relationship = db.Column(db.String(50), nullable=False)
    carer_contact = db.Column(db.String(120), nullable=True)
    patient_identifier = db.Column(db.String(50), nullable=False)
    reason = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.Float, nullable=False, default=time.time)

    staff_user = db.relationship("User", backref=db.backref("carer_proxies", lazy=True))

    def to_dict(self):
        return {
            "id": self.id,
            "staffUserId": self.staff_user_id,
            "carerName": self.carer_name,
            "carerRelationship": self.carer_relationship,
            "carerContact": self.carer_contact,
            "patientIdentifier": self.patient_identifier,
            "reason": self.reason,
            "createdAt": self.created_at,
        }


class ScheduledNotification(db.Model):
    __tablename__ = "notifications"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey("users.id"), nullable=False)
    patient_id = db.Column(db.String(80), nullable=False)
    risk_tier = db.Column(db.String(20), nullable=False)
    appointment_date = db.Column(db.String(30), nullable=True)
    notify_at = db.Column(db.String(50), nullable=False, default="24h_before")
    status = db.Column(db.String(20), nullable=False, default="scheduled")
    created_by = db.Column(db.String(80), nullable=False)
    created_at = db.Column(db.Float, nullable=False, default=time.time)

    user = db.relationship("User", backref=db.backref("notifications", lazy=True))

    def to_dict(self):
        return {
            "id": self.id,
            "patient_id": self.patient_id,
            "risk_tier": self.risk_tier,
            "appointment_date": self.appointment_date or "",
            "notify_at": self.notify_at,
            "status": self.status,
            "created_by": self.created_by,
            "created_at": self.created_at,
        }


class AssessmentSummary(db.Model):
    __tablename__ = "assessment_summaries"

    id = db.Column(db.String(36), primary_key=True)
    user_id = db.Column(db.String(36), db.ForeignKey("users.id"), nullable=False)
    probability = db.Column(db.Float, nullable=False)
    risk_tier = db.Column(db.String(20), nullable=False)
    age_group = db.Column(db.String(40), nullable=False)
    feedback_outcome = db.Column(db.String(20), nullable=True)
    created_at = db.Column(db.Float, nullable=False, default=time.time)

    user = db.relationship("User", backref=db.backref("assessment_summaries", lazy=True))

    def to_recent_dict(self):
        return {
            "id": self.id[:8],
            "age": "Not stored",
            "risk_tier": self.risk_tier,
            "probability": self.probability,
            "age_group": self.age_group,
        }
