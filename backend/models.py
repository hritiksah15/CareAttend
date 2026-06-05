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
