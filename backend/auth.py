"""Authentication module for Care Attend.

Provides session-based authentication with bcrypt password hashing
backed by PostgreSQL via SQLAlchemy.
Maps to: FR-04, NFR-01, NFR-06 in Requirements Traceability Matrix.
"""

import time
import secrets
import hashlib
from functools import wraps

from flask import request, jsonify

from models import db, User, Session

try:
    import bcrypt
    USE_BCRYPT = True
except ImportError:
    USE_BCRYPT = False

try:
    import pyotp
    USE_PYOTP = True
except ImportError:
    USE_PYOTP = False

SESSION_TIMEOUT = 86400  # 24 hours in seconds


def _hash_password(password):
    if USE_BCRYPT:
        return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
    salt = secrets.token_hex(16)
    hashed = hashlib.sha256((salt + password).encode()).hexdigest()
    return f"{salt}${hashed}"


def _verify_password(password, stored_hash):
    if USE_BCRYPT:
        return bcrypt.checkpw(password.encode("utf-8"), stored_hash.encode("utf-8"))
    parts = stored_hash.split("$")
    if len(parts) != 2:
        return False
    salt, hashed = parts
    return hashlib.sha256((salt + password).encode()).hexdigest() == hashed


def register_user(username, email, password, role="staff"):
    if not username or not email or not password:
        return None, "All fields are required"
    if len(password) < 8:
        return None, "Password must be at least 8 characters"
    if User.query.filter_by(email=email).first():
        return None, "Email already registered"
    if User.query.filter_by(username=username).first():
        return None, "Username already taken"

    user = User(
        username=username,
        email=email,
        password_hash=_hash_password(password),
        role=role,
    )
    db.session.add(user)
    db.session.commit()
    return user.id, None


def authenticate(username, password, totp_code=None):
    user = User.query.filter_by(username=username).first()
    if not user:
        return None, "Invalid credentials"
    if not _verify_password(password, user.password_hash):
        return None, "Invalid credentials"

    if user.totp_enabled:
        if not totp_code:
            return {"requires_2fa": True, "user_id": user.id}, None
        if not verify_totp(user, totp_code):
            return None, "Invalid 2FA code"

    token = secrets.token_urlsafe(32)
    session = Session(
        token=token,
        user_id=user.id,
    )
    db.session.add(session)
    db.session.commit()
    return token, None


def validate_token(token):
    session = db.session.get(Session, token)
    if not session:
        return None
    if time.time() - session.last_activity > SESSION_TIMEOUT:
        db.session.delete(session)
        db.session.commit()
        return None
    session.last_activity = time.time()
    db.session.commit()
    return {
        "userId": session.user_id,
        "username": session.user.username,
        "role": session.user.role,
    }


def logout(token):
    session = db.session.get(Session, token)
    if session:
        db.session.delete(session)
        db.session.commit()


def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            token = auth_header.split(" ")[1]
        if not token:
            token = request.cookies.get("session_token")
        if not token:
            return jsonify({"error": "Authentication required"}), 401
        session = validate_token(token)
        if not session:
            return jsonify({"error": "Session expired or invalid"}), 401
        request.current_user = session
        return f(*args, **kwargs)
    return decorated


def get_role(token):
    session = validate_token(token)
    if session:
        return session.get("role")
    return None


def setup_totp(user_id):
    if not USE_PYOTP:
        return None, "2FA not available (pyotp not installed)"
    user = db.session.get(User, user_id)
    if not user:
        return None, "User not found"
    secret = pyotp.random_base32()
    user.totp_secret = secret
    db.session.commit()
    totp = pyotp.TOTP(secret)
    uri = totp.provisioning_uri(name=user.email or user.username, issuer_name="Care Attend")
    return {"secret": secret, "uri": uri}, None


def verify_totp(user, code):
    if not USE_PYOTP or not user.totp_secret:
        return False
    totp = pyotp.TOTP(user.totp_secret)
    return totp.verify(code, valid_window=1)


def enable_totp(user_id, code):
    user = db.session.get(User, user_id)
    if not user or not user.totp_secret:
        return "2FA not set up. Generate a secret first."
    if not verify_totp(user, code):
        return "Invalid verification code. Check your authenticator app."
    user.totp_enabled = True
    db.session.commit()
    return None


def disable_totp(user_id, password):
    user = db.session.get(User, user_id)
    if not user:
        return "User not found"
    if not _verify_password(password, user.password_hash):
        return "Incorrect password"
    user.totp_enabled = False
    user.totp_secret = None
    db.session.commit()
    return None
