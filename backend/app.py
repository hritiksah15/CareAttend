#!/usr/bin/env python3
"""Care Attend - Flask REST API Backend.

Architecture: Flask REST API with JWT authentication, ML inference,
SHAP explainability, bias audit, and intervention engine.
Routes: /predict, /bias-audit, /auth/login, /auth/register, /batch
"""

import csv
import io
import json
import logging
import os
import time
import uuid
from datetime import date, datetime, timedelta

from flask import Flask, render_template, request, jsonify, make_response
from flask_cors import CORS
from sqlalchemy import text as _sql_text

from models import (
    db,
    migrate,
    User,
    AuditLog,
    CarerProxy,
    PersistentFeedback,
    ScheduledNotification,
    OutreachAction,
    AppointmentRecord,
    AssessmentSummary,
)
from auth import (
    register_user,
    authenticate,
    logout,
    token_required,
    role_required,
    VALID_ROLES,
    REMEMBER_TIMEOUT,
    _hash_password,
    _verify_password,
    validate_password,
    setup_totp,
    enable_totp,
    disable_totp,
    request_password_reset,
    reset_password,
)
from ml.predictor import CareAttendPredictor
from ml.bias_monitor import BiasMonitor
from ml.interventions import generate_interventions
from notification_provider import provider as notification_provider, VALID_CHANNELS

FRONTEND_DIR = os.path.join(os.path.dirname(__file__), "..", "frontend")

app = Flask(
    __name__,
    template_folder=os.path.join(FRONTEND_DIR, "templates"),
    static_folder=FRONTEND_DIR,
    static_url_path="/static",
)
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", os.urandom(32).hex())
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get("DATABASE_URL", "postgresql+psycopg://localhost:5432/careattend")
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

# CORS: restrict to an explicit allowlist in production via CORS_ORIGINS
# (comma-separated). Defaults to "*" for local/dev convenience only.
_cors_origins = os.environ.get("CORS_ORIGINS", "*").strip()
if _cors_origins and _cors_origins != "*":
    CORS(app, origins=[o.strip() for o in _cors_origins.split(",") if o.strip()], supports_credentials=True)
else:
    CORS(app)

db.init_app(app)
migrate.init_app(app, db)

# ── Structured request logging + uniform JSON errors (NFR robustness) ──
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger("careattend")

# Warn if running without a stable SECRET_KEY — sessions/signing break across
# multiple workers and restarts when a per-process random key is used.
if not os.environ.get("SECRET_KEY"):
    logger.warning("SECRET_KEY not set — using an ephemeral key. Set SECRET_KEY in production.")

_START_TIME = time.time()


@app.after_request
def _log_request(response):
    logger.info("%s %s -> %s", request.method, request.path, response.status_code)
    return response


@app.errorhandler(400)
def _err_400(e):
    return jsonify({"error": "Bad request", "detail": str(getattr(e, "description", e))}), 400


@app.errorhandler(404)
def _err_404(e):
    return jsonify({"error": "Not found", "path": request.path}), 404


@app.errorhandler(405)
def _err_405(e):
    return jsonify({"error": "Method not allowed", "method": request.method}), 405


@app.errorhandler(500)
def _err_500(e):
    logger.exception("Unhandled server error")
    return jsonify({"error": "Internal server error"}), 500


@app.errorhandler(Exception)
def _err_unhandled(e):
    # Let Flask's own HTTP exceptions (404/405/etc.) pass through to their handlers.
    from werkzeug.exceptions import HTTPException

    if isinstance(e, HTTPException):
        return e
    logger.exception("Unhandled exception")
    return jsonify({"error": "Internal server error"}), 500


predictor = None
bias_monitor = None
training_results = None


def load_models():
    global predictor, bias_monitor, training_results
    predictor = CareAttendPredictor(model_dir="models")
    bias_monitor = BiasMonitor(model_dir="models")
    results_path = "models/training_results.json"
    if os.path.exists(results_path):
        with open(results_path) as f:
            training_results = json.load(f)


# ── Pages ──


@app.route("/")
def index():
    return render_template("index.html")


# ── Health / readiness probe (no auth — for load balancers & Docker) ──


@app.route("/health", methods=["GET"])
def health():
    db_ok = True
    try:
        db.session.execute(_sql_text("SELECT 1"))
    except Exception:
        db_ok = False
    healthy = predictor is not None and db_ok
    return jsonify(
        {
            "status": "ok" if healthy else "degraded",
            "model_loaded": predictor is not None,
            "database": "ok" if db_ok else "unavailable",
            "uptime_seconds": round(time.time() - _START_TIME, 1),
        }
    ), (200 if healthy else 503)


# ── Auth Endpoints (FR-04, NFR-06) ──


@app.route("/auth/register", methods=["POST"])
def auth_register():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400

    username = data.get("username", "").strip()
    email = data.get("email", "").strip()
    password = data.get("password", "")

    # Public self-registration always creates the lowest-privilege role. Any
    # `role` in the request body is ignored to prevent privilege escalation —
    # admins elevate accounts via /api/admin/users/<id>/role.
    user_id, error = register_user(username, email, password, "user")
    if error:
        return jsonify({"error": error}), 400

    return jsonify({"userId": user_id, "message": "Registration successful"}), 201


@app.route("/auth/login", methods=["POST"])
def auth_login():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400

    username = data.get("username", "").strip()
    password = data.get("password", "")
    totp_code = data.get("totp_code")
    remember = bool(data.get("remember"))

    # Bound TOTP code length (6-digit codes); reject oversized input early.
    if totp_code is not None and len(str(totp_code)) > 10:
        return jsonify({"error": "Invalid 2FA code"}), 401

    result, error = authenticate(username, password, totp_code, remember)
    if error:
        return jsonify({"error": error}), 401

    if isinstance(result, dict) and result.get("requires_2fa"):
        return jsonify({"requires_2fa": True, "message": "2FA verification required"}), 200

    token = result
    response = jsonify({"token": token, "message": "Login successful"})
    response.set_cookie(
        "session_token", token, httponly=True, samesite="Strict", max_age=(REMEMBER_TIMEOUT if remember else 1800)
    )
    return response


@app.route("/auth/forgot-password", methods=["POST"])
def auth_forgot_password():
    data = request.get_json() or {}
    email = data.get("email", "").strip()
    if not email:
        return jsonify({"error": "Email is required"}), 400

    code, emailed = request_password_reset(email)
    # Never reveal whether the account exists.
    resp = {"message": "If that email is registered, a reset code has been sent."}
    # Dev convenience: when SMTP is not configured, return the code so the
    # reset flow is testable without an email server.
    if code and not emailed:
        resp["dev_code"] = code
        resp["note"] = "Email is not configured (SMTP_HOST unset); code returned for testing only."
    return jsonify(resp)


@app.route("/auth/reset-password", methods=["POST"])
def auth_reset_password():
    data = request.get_json() or {}
    email = data.get("email", "").strip()
    code = data.get("code", "").strip()
    new_password = data.get("newPassword", "")
    if not email or not code or not new_password:
        return jsonify({"error": "email, code and newPassword are required"}), 400

    error = reset_password(email, code, new_password)
    if error:
        return jsonify({"error": error}), 400
    return jsonify({"message": "Password reset successful. You can now log in."})


@app.route("/auth/logout", methods=["POST"])
def auth_logout():
    token = None
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        token = auth_header.split(" ")[1]
    if not token:
        token = request.cookies.get("session_token")
    if token:
        logout(token)
    response = jsonify({"message": "Logged out"})
    response.delete_cookie("session_token")
    return response


# ── Prediction Endpoint (FR-01, FR-02, FR-03) ──


@app.route("/api/predict", methods=["POST"])
@token_required
def predict():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400

    required = ["Age", "Gender", "AppointmentLeadTimeDays", "SMSReceived", "PriorDNACount", "IMDDecile"]
    missing = [f for f in required if f not in data]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    patient, error = _validate_patient(data)
    if error:
        return jsonify({"error": error}), 400

    result = predictor.predict(patient)
    interventions, risk_tier, age_group = generate_interventions(patient, result["probability"], result["shap_values"])

    nl_summary = _generate_nl_summary(patient, result, age_group)
    prediction_id = str(uuid.uuid4())

    db.session.add(
        AssessmentSummary(
            id=prediction_id,
            user_id=request.current_user["userId"],
            probability=result["probability"],
            risk_tier=result["risk_tier"],
            age_group=age_group,
        )
    )
    db.session.commit()

    return jsonify(
        {
            "sessionId": prediction_id,
            "probability": result["probability"],
            "percentage": result["percentage"],
            "risk_tier": result["risk_tier"],
            "shap_values": result["shap_values"],
            "interventions": interventions,
            "age_group": age_group,
            "model_used": result.get("model_used", "Random Forest"),
            "patient_summary": patient,
            "nl_summary": nl_summary,
        }
    )


# ── Batch CSV Endpoint (FR-08) ──


@app.route("/api/batch", methods=["POST"])
@token_required
@role_required("staff", "admin")
def batch_predict():
    if "file" not in request.files:
        return jsonify({"error": "No CSV file uploaded"}), 400

    file = request.files["file"]
    if not file.filename.endswith(".csv"):
        return jsonify({"error": "File must be CSV format"}), 400

    try:
        # utf-8-sig strips a UTF-8 BOM that Excel/Numbers prepend, which would
        # otherwise corrupt the first header (e.g. "﻿Age") and fail every row.
        content = file.read().decode("utf-8-sig")
        reader = csv.DictReader(io.StringIO(content))
        rows = list(reader)
    except Exception:
        return jsonify({"error": "Invalid CSV format"}), 400

    if len(rows) > 100:
        return jsonify({"error": "Maximum 100 records per batch"}), 400
    if len(rows) == 0:
        return jsonify({"error": "CSV file is empty"}), 400

    results = []
    for i, row in enumerate(rows):
        patient, error = _validate_patient(row)
        if error:
            results.append({"row": i + 1, "error": error})
            continue

        pred = predictor.predict(patient)
        _, risk_tier, age_group = generate_interventions(patient, pred["probability"], pred["shap_values"])
        top_shap = pred["shap_values"][0]["label"] if pred["shap_values"] else ""

        results.append(
            {
                "row": i + 1,
                "age": patient["Age"],
                "risk_probability": pred["percentage"],
                "risk_tier": risk_tier,
                "age_group": age_group,
                "top_risk_factor": top_shap,
            }
        )

    output = io.StringIO()
    if results:
        writer = csv.DictWriter(output, fieldnames=results[0].keys())
        writer.writeheader()
        writer.writerows(results)

    response = make_response(output.getvalue())
    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=batch_results.csv"
    return response


# ── Bias Audit Endpoint (FR-07) ──


@app.route("/api/bias-audit", methods=["GET"])
@token_required
@role_required("admin")
def bias_audit():
    results = bias_monitor.run_audit()
    governance = results.get("governance", {})
    if governance.get("verdict") == "ACTION_REQUIRED":
        detail = f"{governance.get('breach_count', 0)} fairness breach(es) flagged for review"
        # Dedup: this is a GET, so log the breach at most once per 24h per
        # distinct breach signature — otherwise repeated dashboard views would
        # flood the audit trail with identical rows.
        already_logged = AuditLog.query.filter(
            AuditLog.action == "bias_governance_breach",
            AuditLog.detail == detail,
            AuditLog.created_at >= time.time() - 86400,
        ).first()
        if not already_logged:
            db.session.add(_audit(request.current_user["userId"], "bias_governance_breach", detail))
            db.session.commit()
    return jsonify(results)


# ── Model Info & Comparison ──


@app.route("/api/model-info", methods=["GET"])
@token_required
@role_required("admin")
def model_info():
    if training_results:
        return jsonify(training_results)
    return jsonify({"error": "No training results available"}), 404


@app.route("/api/model-comparison", methods=["GET"])
@token_required
@role_required("admin")
def model_comparison():
    if not training_results:
        return jsonify({"error": "No training results available"}), 404
    return jsonify(
        {
            "selected_model": training_results.get("selected_model"),
            "threshold": training_results.get("best_metrics", {}).get("threshold"),
            "logistic_regression": training_results.get("lr_metrics"),
            "random_forest": training_results.get("rf_metrics"),
            "optimised_metrics": training_results.get("best_metrics"),
            "dataset": {
                "train_size": training_results.get("train_size"),
                "test_size": training_results.get("test_size"),
                "dna_rate": training_results.get("dna_rate"),
            },
        }
    )


# ── Practice Dashboard (US-002, Feature 11) ──


@app.route("/api/dashboard", methods=["GET"])
@token_required
@role_required("staff", "admin")
def practice_dashboard():
    # Practice-wide view (US-002): aggregate every staff member's assessments,
    # not just the caller's. Summaries are anonymised, so there is no PII leak.
    assessments = AssessmentSummary.query.order_by(AssessmentSummary.created_at.desc()).all()
    if not assessments:
        return jsonify({"message": "No assessments yet", "total": 0})

    high = sum(1 for p in assessments if p.risk_tier == "High")
    medium = sum(1 for p in assessments if p.risk_tier == "Medium")
    low = sum(1 for p in assessments if p.risk_tier == "Low")
    avg_risk = sum(p.probability for p in assessments) / len(assessments)

    age_breakdown = {}
    for p in assessments:
        ag = p.age_group
        if ag not in age_breakdown:
            age_breakdown[ag] = {"total": 0, "high_risk": 0}
        age_breakdown[ag]["total"] += 1
        if p.risk_tier == "High":
            age_breakdown[ag]["high_risk"] += 1

    recent_summary = [r.to_recent_dict() for r in assessments[:10]]

    return jsonify(
        {
            "total": len(assessments),
            "high_risk": high,
            "medium_risk": medium,
            "low_risk": low,
            "average_risk": round(avg_risk, 4),
            "age_breakdown": age_breakdown,
            "recent_assessments": recent_summary,
            "feedback_given": sum(1 for p in assessments if p.feedback_outcome is not None),
        }
    )


# ── Prediction Feedback Loop (Feature 12) ──


@app.route("/api/feedback", methods=["POST"])
@token_required
@role_required("staff", "admin")
def submit_feedback():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400

    prediction_id = data.get("prediction_id", "")
    outcome = data.get("outcome", "")

    if outcome not in ("correct", "incorrect", "attended", "dna"):
        return jsonify({"error": "outcome must be: correct, incorrect, attended, or dna"}), 400

    # Practice-wide: any staff member may record the outcome of any assessment.
    assessment = AssessmentSummary.query.filter_by(id=prediction_id).first()
    if not assessment:
        return jsonify({"error": "Prediction not found"}), 404

    assessment.feedback_outcome = outcome
    # Persist an anonymised feedback record (tier/prob/outcome only — no
    # patient data) for cross-session accuracy tracking & audit.
    db.session.add(
        PersistentFeedback(
            user_id=request.current_user["userId"],
            prediction_risk_tier=assessment.risk_tier,
            prediction_probability=assessment.probability,
            outcome=outcome,
        )
    )
    db.session.add(
        _audit(
            request.current_user["userId"], "feedback_recorded", f"{outcome} for {assessment.risk_tier} risk prediction"
        )
    )
    db.session.commit()
    return jsonify({"message": "Feedback recorded", "prediction_id": prediction_id})


@app.route("/api/feedback/summary", methods=["GET"])
@token_required
@role_required("staff", "admin")
def feedback_summary():
    assessments = AssessmentSummary.query.all()  # practice-wide accuracy
    total = len(assessments)
    with_feedback = [p for p in assessments if p.feedback_outcome is not None]

    correct = sum(1 for p in with_feedback if p.feedback_outcome in ("correct", "dna"))
    incorrect = sum(1 for p in with_feedback if p.feedback_outcome in ("incorrect", "attended"))

    return jsonify(
        {
            "total_predictions": total,
            "feedback_received": len(with_feedback),
            "correct": correct,
            "incorrect": incorrect,
            "accuracy": round(correct / len(with_feedback), 4) if with_feedback else None,
        }
    )


# ── Mock NHS EHR Integration (Feature 10) ──

EHR_MOCK_PATIENTS = {
    "NHS001": {
        "name": "Margaret Thompson",
        "Age": 78,
        "Gender": 0,
        "IMDDecile": 3,
        "Hypertension": 1,
        "Diabetes": 1,
        "Disability": 0,
        "PriorDNACount": 4,
    },
    "NHS002": {
        "name": "James Patel",
        "Age": 45,
        "Gender": 1,
        "IMDDecile": 7,
        "Hypertension": 0,
        "Diabetes": 0,
        "Disability": 0,
        "PriorDNACount": 1,
    },
    "NHS003": {
        "name": "Fatima Ali",
        "Age": 82,
        "Gender": 0,
        "IMDDecile": 2,
        "Hypertension": 1,
        "Diabetes": 0,
        "Disability": 1,
        "PriorDNACount": 6,
    },
    "NHS004": {
        "name": "David Williams",
        "Age": 34,
        "Gender": 1,
        "IMDDecile": 5,
        "Hypertension": 0,
        "Diabetes": 0,
        "Disability": 0,
        "PriorDNACount": 0,
    },
    "NHS005": {
        "name": "Eileen O'Brien",
        "Age": 91,
        "Gender": 0,
        "IMDDecile": 1,
        "Hypertension": 1,
        "Diabetes": 1,
        "Disability": 1,
        "PriorDNACount": 8,
    },
}


@app.route("/api/ehr/lookup/<nhs_number>", methods=["GET"])
@token_required
@role_required("staff", "admin")
def ehr_lookup(nhs_number):
    patient = EHR_MOCK_PATIENTS.get(nhs_number)
    if not patient:
        return jsonify(
            {
                "error": "Patient not found",
                "note": "This is a mock EHR. "
                "Real integration requires NHS IG Toolkit approval (out of scope per AT2 Section 1.3)",
            }
        ), 404
    return jsonify(
        {
            "source": "Mock EMIS/SystmOne",
            "nhs_number": nhs_number,
            "patient": patient,
            "note": "Mock data only. Real NHS EHR integration excluded per AT2 scope constraints.",
        }
    )


@app.route("/api/ehr/patients", methods=["GET"])
@token_required
@role_required("staff", "admin")
def ehr_list():
    return jsonify(
        {
            "source": "Mock EMIS/SystmOne",
            "patients": {k: v["name"] for k, v in EHR_MOCK_PATIENTS.items()},
            "note": "Mock data only.",
        }
    )


# ── Appointment Worklist ──

VALID_APPOINTMENT_STATUSES = {"scheduled", "confirmed", "attended", "dna", "cancelled", "rescheduled"}


@app.route("/api/appointments", methods=["POST"])
@token_required
@role_required("staff", "admin")
def create_appointments():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400

    raw_appointments = data.get("appointments") if isinstance(data.get("appointments"), list) else [data]
    if not raw_appointments or len(raw_appointments) > 100:
        return jsonify({"error": "Provide 1-100 appointments"}), 400

    created = []
    errors = []
    for i, item in enumerate(raw_appointments):
        if not isinstance(item, dict):
            errors.append({"row": i + 1, "error": "appointment row must be an object"})
            continue

        patient_id = str(item.get("patient_id", "")).strip()
        appointment_date = str(item.get("appointment_date", "")).strip()
        if not patient_id or not appointment_date:
            errors.append({"row": i + 1, "error": "patient_id and appointment_date are required"})
            continue
        if not _parse_iso_date(appointment_date):
            errors.append({"row": i + 1, "error": "appointment_date must be YYYY-MM-DD"})
            continue

        status = item.get("status", "scheduled")
        if status not in VALID_APPOINTMENT_STATUSES:
            errors.append(
                {"row": i + 1, "error": f"status must be one of: {', '.join(sorted(VALID_APPOINTMENT_STATUSES))}"}
            )
            continue

        patient, error = _appointment_patient_payload(item)
        if error:
            errors.append({"row": i + 1, "error": error})
            continue

        pred = predictor.predict(patient)
        _, _, age_group = generate_interventions(patient, pred["probability"], pred["shap_values"])
        appointment = AppointmentRecord(
            user_id=request.current_user["userId"],
            patient_id=patient_id,
            appointment_date=appointment_date,
            appointment_time=str(item.get("appointment_time", "")).strip() or None,
            clinic=str(item.get("clinic", "")).strip() or None,
            status=status,
            probability=pred["probability"],
            risk_tier=pred["risk_tier"],
            age_group=age_group,
        )
        db.session.add(appointment)
        created.append(appointment)

    if not created:
        return jsonify({"error": "No valid appointments", "errors": errors}), 400

    db.session.add(
        _audit(request.current_user["userId"], "appointments_created", f"{len(created)} appointment(s) imported")
    )
    db.session.commit()
    return jsonify(
        {"appointments": [appt.to_dict() for appt in created], "created": len(created), "errors": errors}
    ), 201


@app.route("/api/clinic-list", methods=["GET"])
@token_required
@role_required("staff", "admin")
def clinic_list():
    appointment_date = request.args.get("date") or (date.today() + timedelta(days=1)).isoformat()
    if not _parse_iso_date(appointment_date):
        return jsonify({"error": "date must be YYYY-MM-DD"}), 400

    appointments = (
        AppointmentRecord.query.filter_by(
            user_id=request.current_user["userId"],
            appointment_date=appointment_date,
        )
        .order_by(AppointmentRecord.appointment_time.asc(), AppointmentRecord.created_at.asc())
        .all()
    )
    patient_ids = [appt.patient_id for appt in appointments]

    actions = []
    notifications = []
    if patient_ids:
        actions = (
            OutreachAction.query.filter(
                OutreachAction.user_id == request.current_user["userId"],
                OutreachAction.patient_id.in_(patient_ids),
            )
            .order_by(OutreachAction.created_at.desc())
            .all()
        )
        notifications = (
            ScheduledNotification.query.filter(
                ScheduledNotification.user_id == request.current_user["userId"],
                ScheduledNotification.patient_id.in_(patient_ids),
            )
            .order_by(ScheduledNotification.created_at.desc())
            .all()
        )

    actions_by_patient = {}
    for action in actions:
        actions_by_patient.setdefault(action.patient_id, []).append(action)
    notifications_by_patient = {}
    for notification in notifications:
        notifications_by_patient.setdefault(notification.patient_id, []).append(notification)

    rows = []
    for appt in appointments:
        appt_actions = actions_by_patient.get(appt.patient_id, [])
        appt_notifications = notifications_by_patient.get(appt.patient_id, [])
        row = appt.to_dict()
        row.update(
            {
                "action_count": len(appt_actions),
                "notification_count": len(appt_notifications),
                "latest_action": appt_actions[0].to_dict() if appt_actions else None,
                "needs_action": appt.risk_tier in ("High", "Medium") and not appt_actions,
            }
        )
        rows.append(row)

    return jsonify(
        {
            "date": appointment_date,
            "appointments": rows,
            "summary": {
                "total": len(rows),
                "high_risk": sum(1 for appt in appointments if appt.risk_tier == "High"),
                "medium_risk": sum(1 for appt in appointments if appt.risk_tier == "Medium"),
                "low_risk": sum(1 for appt in appointments if appt.risk_tier == "Low"),
                "actioned": sum(1 for row in rows if row["action_count"] > 0),
                "needs_action": sum(1 for row in rows if row["needs_action"]),
            },
        }
    )


@app.route("/api/appointments/<appointment_id>/status", methods=["PATCH"])
@token_required
@role_required("staff", "admin")
def update_appointment_status(appointment_id):
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400
    status = data.get("status", "")
    if status not in VALID_APPOINTMENT_STATUSES:
        return jsonify({"error": f"status must be one of: {', '.join(sorted(VALID_APPOINTMENT_STATUSES))}"}), 400

    appointment = AppointmentRecord.query.filter_by(
        id=appointment_id,
        user_id=request.current_user["userId"],
    ).first()
    if not appointment:
        return jsonify({"error": "Appointment not found"}), 404

    appointment.status = status
    appointment.updated_at = time.time()
    db.session.add(
        _audit(request.current_user["userId"], "appointment_status_updated", f"{appointment.patient_id}: {status}")
    )
    db.session.commit()
    return jsonify({"message": "Appointment status updated", "appointment": appointment.to_dict()})


@app.route("/api/operational-outcomes", methods=["GET"])
@token_required
@role_required("staff", "admin")
def operational_outcomes():
    start_date = request.args.get("from") or None
    end_date = request.args.get("to") or None
    if start_date and not _parse_iso_date(start_date):
        return jsonify({"error": "from must be YYYY-MM-DD"}), 400
    if end_date and not _parse_iso_date(end_date):
        return jsonify({"error": "to must be YYYY-MM-DD"}), 400

    appointments = AppointmentRecord.query.all()
    if start_date or end_date:
        appointments = [appt for appt in appointments if _appointment_in_period(appt, start_date, end_date)]

    completed_actions = OutreachAction.query.filter_by(status="completed").all()
    if start_date or end_date:
        completed_actions = [
            action for action in completed_actions if _date_in_period(action.appointment_date, start_date, end_date)
        ]
    # Match on (patient_id, appointment_date) only — NOT user_id. Outcomes are
    # practice-wide (every staff member's appointments), so an appointment booked
    # by one staff member and actioned by a colleague must still count as actioned.
    action_keys = {
        (action.patient_id, action.appointment_date)
        for action in completed_actions
        if action.patient_id and action.appointment_date
    }

    completed = [appt for appt in appointments if appt.status in ("attended", "dna")]
    actioned_completed = [appt for appt in completed if (appt.patient_id, appt.appointment_date) in action_keys]
    unactioned_completed = [appt for appt in completed if (appt.patient_id, appt.appointment_date) not in action_keys]

    actioned_stats = _appointment_outcome_stats(actioned_completed)
    unactioned_stats = _appointment_outcome_stats(unactioned_completed)
    dna_rate_gap = None
    if actioned_stats["total"] > 0 and unactioned_stats["total"] > 0:
        dna_rate_gap = round(unactioned_stats["dna_rate"] - actioned_stats["dna_rate"], 4)

    by_tier = {}
    for tier in ("High", "Medium", "Low"):
        by_tier[tier.lower()] = _appointment_outcome_stats([appt for appt in completed if appt.risk_tier == tier])

    return jsonify(
        {
            "period": {"from": start_date, "to": end_date},
            "appointments": {
                "total": len(appointments),
                "completed": len(completed),
                "awaiting_outcome": sum(
                    1 for appt in appointments if appt.status in ("scheduled", "confirmed", "rescheduled")
                ),
                "cancelled": sum(1 for appt in appointments if appt.status == "cancelled"),
            },
            "outcomes": _appointment_outcome_stats(completed),
            "by_risk_tier": by_tier,
            "interventions": {
                "completed_actions": len(completed_actions),
                "actioned_completed_appointments": actioned_stats,
                "unactioned_completed_appointments": unactioned_stats,
                "intervention_success_rate": actioned_stats["attended_rate"] if actioned_stats["total"] else None,
                "actioned_vs_unactioned_dna_gap": dna_rate_gap,
                "note": (
                    "Observational only — NOT a causal effect. Gap = unactioned DNA rate "
                    "minus actioned DNA rate for completed appointments. Confounded by "
                    "indication: high-risk patients are preferentially actioned, so the "
                    "actioned cohort differs systematically from the unactioned one. "
                    "Interpret alongside by_risk_tier."
                ),
            },
        }
    )


# ── Multi-Trust Configuration (Feature 14) ──

TRUST_CONFIGS = {
    "default": {"name": "Default NHS Trust", "region": "England", "risk_thresholds": {"low": 0.33, "high": 0.67}},
    "tower_hamlets": {"name": "Tower Hamlets CCG", "region": "London", "risk_thresholds": {"low": 0.30, "high": 0.60}},
    "north_norfolk": {
        "name": "North Norfolk CCG",
        "region": "East of England",
        "risk_thresholds": {"low": 0.35, "high": 0.70},
    },
    "belfast": {
        "name": "Belfast HSC Trust",
        "region": "Northern Ireland",
        "risk_thresholds": {"low": 0.33, "high": 0.67},
    },
}


@app.route("/api/trusts", methods=["GET"])
@token_required
@role_required("staff", "admin")
def list_trusts():
    return jsonify({"trusts": TRUST_CONFIGS})


@app.route("/api/trusts/<trust_id>", methods=["GET"])
@token_required
@role_required("staff", "admin")
def get_trust(trust_id):
    config = TRUST_CONFIGS.get(trust_id)
    if not config:
        return jsonify({"error": "Trust not found"}), 404
    return jsonify(config)


# ── Rigorous Evaluation (Feature 15) ──


@app.route("/api/evaluation/cross-validation", methods=["POST"])
@token_required
@role_required("admin")
def run_cv_evaluation():
    from ml.evaluation import run_cross_validation
    from sklearn.preprocessing import StandardScaler
    import pandas as pd
    from ml.data_generator import FEATURE_NAMES

    test_path = "models/test_data.csv"
    if not os.path.exists(test_path):
        return jsonify({"error": "Test data not available"}), 404

    data_path = "data/synthetic_dataset.csv"
    if not os.path.exists(data_path):
        return jsonify({"error": "Training data not available"}), 404

    df = pd.read_csv(data_path)
    X = df[FEATURE_NAMES].values
    y = df["NoShow"].values

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    results = run_cross_validation(X_scaled, y, n_splits=5)
    return jsonify(results)


# ── NHSX AI Ethics Framework Mapping (Feature 19) ──

NHSX_ETHICS_MAPPING = {
    "framework": "NHS England (2024) Guide to Good Practice for Digital and Data-Driven Health Technologies",
    "principles": [
        {
            "id": "P1",
            "principle": "Safe, effective and fit for purpose",
            "status": "Addressed",
            "evidence": [
                "F1 >= 0.72 and Recall >= 0.70 validated on held-out test set (NFR-04)",
                "4-model comparison (LR, RF, XGBoost, LightGBM) with threshold optimisation",
                "199 automated pytest tests covering all modules",
                "SMOTE applied to training partition only - no data leakage",
            ],
        },
        {
            "id": "P2",
            "principle": "Transparent and explainable",
            "status": "Addressed",
            "evidence": [
                "SHAP TreeExplainer/LinearExplainer provides per-prediction feature attribution (FR-03)",
                "Top 3 risk factors displayed with plain-English labels and direction of effect",
                "Natural language summaries generated from SHAP values (Feature 13)",
                "Model comparison metrics accessible via /api/model-comparison endpoint",
            ],
        },
        {
            "id": "P3",
            "principle": "Fair, inclusive and non-discriminatory",
            "status": "Addressed",
            "evidence": [
                "Demographic parity and equalised odds audited across age, gender, and IMD (FR-07)",
                "Threshold set at 0.10 per Caton and Haas (2024) fairness framework",
                "Traffic-light indicators for non-technical interpretation",
                "Plain-English bias summary generated for governance reporting",
                "PDF export available for NHS Trust governance committees (US-011)",
            ],
        },
        {
            "id": "P4",
            "principle": "Privacy and data protection",
            "status": "Addressed",
            "evidence": [
                "No raw patient inputs are persisted; only anonymised assessment summaries are stored for dashboard/feedback (NFR-01)",
                "All API communication designed for HTTPS (TLS 1.2+)",
                "Passwords hashed with bcrypt, session tokens expire after 30 minutes (NFR-06)",
                "Data Protection Notice displayed on first launch (GDPR Art 5(1)(c))",
                "No patient-identifiable data in model training (synthetic data only)",
            ],
        },
        {
            "id": "P5",
            "principle": "Accountable and governed",
            "status": "Partially Addressed",
            "evidence": [
                "Prediction feedback loop enables ongoing accuracy monitoring (Feature 12)",
                "Bias audit exportable as PDF for governance review",
                "Role-based authentication (admin/staff) for access control",
                "Limitation: no formal clinical governance sign-off (academic prototype scope)",
            ],
        },
        {
            "id": "P6",
            "principle": "Collaborative and open",
            "status": "Partially Addressed",
            "evidence": [
                "Open-source prototype with documented API endpoints",
                "Mock EHR integration demonstrates interoperability architecture",
                "Multi-trust configuration supports future collaborative deployment",
                "Limitation: no live NHS trust collaboration (academic scope)",
            ],
        },
    ],
}


@app.route("/api/ethics-framework", methods=["GET"])
@token_required
@role_required("admin")
def ethics_framework():
    return jsonify(NHSX_ETHICS_MAPPING)


# ── Offline Model Export ──


@app.route("/api/export-model", methods=["GET"])
@token_required
@role_required("admin")
def export_model():
    model_path = os.path.join("models", "model.joblib")
    if not os.path.exists(model_path):
        return jsonify({"error": "No model available"}), 404
    return jsonify(
        {
            "message": "Model export available",
            "format": "joblib",
            "model": training_results.get("selected_model") if training_results else "Unknown",
            "features": [
                "Age",
                "Gender",
                "AppointmentLeadTimeDays",
                "SMSReceived",
                "PriorDNACount",
                "Hypertension",
                "Diabetes",
                "Alcoholism",
                "Disability",
                "IMDDecile",
            ],
            "threshold": training_results.get("best_metrics", {}).get("threshold", 0.5) if training_results else 0.5,
            "note": "For offline Flutter deployment, convert to ONNX or TFLite format",
        }
    )


# ── Push Notification Scheduling ──

VALID_ACTION_TYPES = {"call", "sms", "letter", "transport", "carer_contact", "reschedule", "other"}
VALID_ACTION_STATUSES = {"planned", "in_progress", "completed", "cancelled"}
VALID_ACTION_OUTCOMES = {
    "answered",
    "left_message",
    "sms_sent",
    "transport_arranged",
    "carer_contacted",
    "rescheduled",
    "attended",
    "dna",
    "no_response",
    "not_needed",
}


@app.route("/api/notifications/schedule", methods=["POST"])
@token_required
@role_required("staff", "admin")
def schedule_notification():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400

    patient_id = data.get("patient_id", "unknown")
    risk_tier = data.get("risk_tier", "")
    appointment_date = data.get("appointment_date", "")

    if risk_tier not in ("High", "Medium"):
        return jsonify({"error": "Notifications only for High/Medium risk patients"}), 400

    notification = ScheduledNotification(
        user_id=request.current_user["userId"],
        patient_id=patient_id,
        risk_tier=risk_tier,
        appointment_date=appointment_date,
        notify_at=data.get("notify_at", "24h_before"),
        status="scheduled",
        created_by=getattr(request, "current_user", {}).get("username", "system"),
    )
    db.session.add(notification)
    db.session.add(
        _audit(request.current_user["userId"], "notification_scheduled", f"{risk_tier} reminder for {patient_id}")
    )
    db.session.commit()

    return jsonify(
        {
            "message": "Notification scheduled",
            "notification": notification.to_dict(),
        }
    ), 201


@app.route("/api/notifications", methods=["GET"])
@token_required
@role_required("staff", "admin")
def list_notifications():
    notifications = (
        ScheduledNotification.query.filter_by(user_id=request.current_user["userId"])
        .order_by(ScheduledNotification.created_at.desc())
        .all()
    )
    return jsonify(
        {
            "notifications": [n.to_dict() for n in notifications],
            "total": len(notifications),
        }
    )


@app.route("/api/notifications/<notification_id>/dispatch", methods=["POST"])
@token_required
@role_required("staff", "admin")
def dispatch_notification(notification_id):
    """Dispatch a scheduled reminder via the (simulated) delivery provider.

    Transitions delivery_status pending|failed -> sent|failed and records the
    attempt. No real message is sent — see notification_provider.py.
    """
    data = request.get_json(silent=True) or {}
    channel = data.get("channel", "sms")
    if channel not in VALID_CHANNELS:
        return jsonify({"error": f"channel must be one of: {', '.join(sorted(VALID_CHANNELS))}"}), 400

    notification = ScheduledNotification.query.filter_by(
        id=notification_id,
        user_id=request.current_user["userId"],
    ).first()
    if not notification:
        return jsonify({"error": "Notification not found"}), 404
    if notification.delivery_status == "sent":
        return jsonify({"error": "Notification already delivered"}), 400

    result = notification_provider.send(
        patient_id=notification.patient_id,
        channel=channel,
        force_failure=bool(data.get("simulate_failure")),
    )

    notification.delivery_channel = channel
    notification.delivery_attempts = (notification.delivery_attempts or 0) + 1
    notification.last_attempt_at = time.time()
    if result.success:
        notification.delivery_status = "sent"
        notification.provider_ref = result.provider_ref
        notification.failure_reason = None
        if notification.status == "scheduled":
            notification.status = "sent"
        audit_detail = (
            f"{channel} to {notification.patient_id} via {notification_provider.name} (ref {result.provider_ref})"
        )
        audit_action = "notification_dispatched"
    else:
        notification.delivery_status = "failed"
        notification.failure_reason = result.failure_reason
        audit_detail = f"{channel} to {notification.patient_id} failed: {result.failure_reason}"
        audit_action = "notification_dispatch_failed"

    db.session.add(_audit(request.current_user["userId"], audit_action, audit_detail))
    db.session.commit()

    status_code = 200 if result.success else 502
    return jsonify(
        {
            "message": "Notification delivered" if result.success else "Delivery failed (retryable)",
            "notification": notification.to_dict(),
        }
    ), status_code


# ── Operational Action Tracking ──


@app.route("/api/actions", methods=["POST"])
@token_required
@role_required("staff", "admin")
def create_outreach_action():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400

    action_type = data.get("action_type", "")
    status = data.get("status", "planned")
    outcome = data.get("outcome") or None
    notification_id = data.get("notification_id") or None
    patient_id = data.get("patient_id", "")

    if action_type not in VALID_ACTION_TYPES:
        return jsonify({"error": f"action_type must be one of: {', '.join(sorted(VALID_ACTION_TYPES))}"}), 400
    if status not in VALID_ACTION_STATUSES:
        return jsonify({"error": f"status must be one of: {', '.join(sorted(VALID_ACTION_STATUSES))}"}), 400
    if outcome and outcome not in VALID_ACTION_OUTCOMES:
        return jsonify({"error": f"outcome must be one of: {', '.join(sorted(VALID_ACTION_OUTCOMES))}"}), 400

    notification = None
    if notification_id:
        notification = ScheduledNotification.query.filter_by(
            id=notification_id,
            user_id=request.current_user["userId"],
        ).first()
        if not notification:
            return jsonify({"error": "Notification not found"}), 404
        patient_id = patient_id or notification.patient_id

    if not patient_id:
        return jsonify({"error": "patient_id is required"}), 400

    action = OutreachAction(
        user_id=request.current_user["userId"],
        notification_id=notification_id,
        patient_id=patient_id,
        action_type=action_type,
        risk_tier=data.get("risk_tier") or (notification.risk_tier if notification else None),
        appointment_date=data.get("appointment_date") or (notification.appointment_date if notification else None),
        status=status,
        outcome=outcome,
        notes=data.get("notes", ""),
        created_by=getattr(request, "current_user", {}).get("username", "system"),
        completed_at=time.time() if status == "completed" else None,
    )
    if notification and status == "completed":
        notification.status = "actioned"

    db.session.add(action)
    db.session.add(
        _audit(request.current_user["userId"], "outreach_action_created", f"{action_type} for {patient_id}: {status}")
    )
    db.session.commit()

    return jsonify({"message": "Action recorded", "action": action.to_dict()}), 201


@app.route("/api/actions", methods=["GET"])
@token_required
@role_required("staff", "admin")
def list_outreach_actions():
    query = OutreachAction.query.filter_by(user_id=request.current_user["userId"])
    status = request.args.get("status")
    patient_id = request.args.get("patient_id")
    if status:
        if status not in VALID_ACTION_STATUSES:
            return jsonify({"error": f"status must be one of: {', '.join(sorted(VALID_ACTION_STATUSES))}"}), 400
        query = query.filter_by(status=status)
    if patient_id:
        query = query.filter_by(patient_id=patient_id)

    actions = query.order_by(OutreachAction.created_at.desc()).limit(100).all()
    return jsonify({"actions": [a.to_dict() for a in actions], "total": len(actions)})


@app.route("/api/actions/<action_id>", methods=["PATCH"])
@token_required
@role_required("staff", "admin")
def update_outreach_action(action_id):
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400

    action = OutreachAction.query.filter_by(
        id=action_id,
        user_id=request.current_user["userId"],
    ).first()
    if not action:
        return jsonify({"error": "Action not found"}), 404

    if "status" in data:
        if data["status"] not in VALID_ACTION_STATUSES:
            return jsonify({"error": f"status must be one of: {', '.join(sorted(VALID_ACTION_STATUSES))}"}), 400
        action.status = data["status"]
        if action.status == "completed" and action.completed_at is None:
            action.completed_at = time.time()
    if "outcome" in data:
        outcome = data.get("outcome") or None
        if outcome and outcome not in VALID_ACTION_OUTCOMES:
            return jsonify({"error": f"outcome must be one of: {', '.join(sorted(VALID_ACTION_OUTCOMES))}"}), 400
        action.outcome = outcome
    if "notes" in data:
        action.notes = data.get("notes", "")

    if action.notification and action.status == "completed":
        action.notification.status = "actioned"

    db.session.add(
        _audit(
            request.current_user["userId"],
            "outreach_action_updated",
            f"{action.action_type} for {action.patient_id}: {action.status}",
        )
    )
    db.session.commit()

    return jsonify({"message": "Action updated", "action": action.to_dict()})


# ── Account Centre API ──


@app.route("/api/profile", methods=["GET"])
@token_required
def get_profile():
    user = db.session.get(User, request.current_user["userId"])
    if not user:
        return jsonify({"error": "User not found"}), 404
    return jsonify(user.to_dict())


@app.route("/api/profile", methods=["PUT"])
@token_required
def update_profile():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400
    user = db.session.get(User, request.current_user["userId"])
    if not user:
        return jsonify({"error": "User not found"}), 404

    # Simple text fields: trim + length-cap.
    _text_fields = {
        "displayName": ("display_name", 100),
        "jobTitle": ("job_title", 100),
        "department": ("department", 100),
        "bio": ("bio", 300),
        "phone": ("phone", 30),
        "pronouns": ("pronouns", 30),
    }
    for key, (attr, limit) in _text_fields.items():
        if key in data and data[key] is not None:
            setattr(user, attr, str(data[key]).strip()[:limit] or None)

    # Avatar: empty string clears it; otherwise must be a small image data-URL.
    if "avatar" in data:
        avatar = data["avatar"]
        if not avatar:
            user.avatar = None
        elif not (isinstance(avatar, str) and avatar.startswith("data:image/")):
            return jsonify({"error": "Avatar must be an image"}), 400
        elif len(avatar) > 2_000_000:
            return jsonify({"error": "Image too large — please choose a smaller photo"}), 400
        else:
            user.avatar = avatar

    db.session.commit()
    return jsonify(user.to_dict())


@app.route("/api/profile/change-password", methods=["POST"])
@token_required
def change_password():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400
    user = db.session.get(User, request.current_user["userId"])
    if not user:
        return jsonify({"error": "User not found"}), 404
    if not _verify_password(data.get("currentPassword", ""), user.password_hash):
        return jsonify({"error": "Current password is incorrect"}), 400
    current_pw = data.get("currentPassword", "")
    new_pw = data.get("newPassword", "")
    pw_error = validate_password(new_pw)
    if pw_error:
        return jsonify({"error": pw_error}), 400
    if new_pw == current_pw:
        return jsonify({"error": "New password must be different from the current password"}), 400
    user.password_hash = _hash_password(new_pw)
    user.last_password_change = __import__("time").time()
    db.session.commit()
    return jsonify({"message": "Password changed successfully"})


# ── 2FA Endpoints ──


@app.route("/api/profile/2fa/setup", methods=["POST"])
@token_required
def setup_2fa():
    result, error = setup_totp(request.current_user["userId"])
    if error:
        return jsonify({"error": error}), 400
    return jsonify(result)


@app.route("/api/profile/2fa/enable", methods=["POST"])
@token_required
def enable_2fa():
    data = request.get_json()
    if not data or not data.get("code"):
        return jsonify({"error": "Verification code required"}), 400
    error = enable_totp(request.current_user["userId"], data["code"])
    if error:
        return jsonify({"error": error}), 400
    return jsonify({"message": "2FA enabled successfully"})


@app.route("/api/profile/2fa/disable", methods=["POST"])
@token_required
def disable_2fa():
    data = request.get_json()
    if not data or not data.get("password"):
        return jsonify({"error": "Password required to disable 2FA"}), 400
    error = disable_totp(request.current_user["userId"], data["password"])
    if error:
        return jsonify({"error": error}), 400
    return jsonify({"message": "2FA disabled"})


# ── Carer / Family Proxy Mode (Digital Inclusion Bridge) ──


@app.route("/api/carer-proxy", methods=["POST"])
@token_required
@role_required("staff", "admin")
def create_carer_proxy():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400
    carer_name = data.get("carerName", "").strip()
    relationship = data.get("relationship", "").strip()
    patient_id = data.get("patientIdentifier", "").strip()
    if not carer_name or not relationship or not patient_id:
        return jsonify({"error": "carerName, relationship, and patientIdentifier required"}), 400
    if relationship not in ("family", "carer", "social_worker", "neighbour", "volunteer"):
        return jsonify({"error": "Invalid relationship type"}), 400

    user_id = request.current_user["userId"]
    proxy = CarerProxy(
        staff_user_id=user_id,
        carer_name=carer_name,
        carer_relationship=relationship,
        carer_contact=data.get("carerContact", "").strip() or None,
        patient_identifier=patient_id,
        reason=data.get("reason", "").strip() or None,
    )
    db.session.add(proxy)
    db.session.add(_audit(user_id, "carer_proxy_created", f"Proxy for {patient_id} by {carer_name} ({relationship})"))
    db.session.commit()
    return jsonify({"message": "Carer proxy registered", "proxy": proxy.to_dict()}), 201


@app.route("/api/carer-proxy/list", methods=["GET"])
@token_required
@role_required("staff", "admin")
def list_carer_proxies():
    proxies = (
        CarerProxy.query.filter_by(staff_user_id=request.current_user["userId"])
        .order_by(CarerProxy.created_at.desc())
        .all()
    )
    return jsonify({"proxies": [p.to_dict() for p in proxies]})


# ── Appointment Slot Optimisation ──


@app.route("/api/slot-optimisation", methods=["POST"])
@token_required
@role_required("staff", "admin")
def slot_optimisation():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400
    appointments = data.get("appointments", [])
    if not appointments or len(appointments) > 50:
        return jsonify({"error": "Provide 1-50 appointments"}), 400

    results = []
    total_wasted_minutes = 0
    overbookable_slots = 0

    for i, appt in enumerate(appointments):
        patient, error = _validate_patient(appt)
        if error:
            results.append({"slot": i + 1, "error": error})
            continue
        pred = predictor.predict(patient)
        prob = pred["probability"]
        risk_tier = pred["risk_tier"]
        slot_minutes = int(appt.get("slotMinutes", 15))
        can_overbook = prob >= 0.4
        if can_overbook:
            overbookable_slots += 1
        expected_waste = prob * slot_minutes
        total_wasted_minutes += expected_waste
        rec = (
            "Strong overbook candidate. Consider double-booking or waitlist patient."
            if prob >= 0.7
            else "Moderate DNA risk. Consider standby patient or phone reminder 24h before."
            if prob >= 0.4
            else "Low-moderate risk. Standard SMS reminder sufficient."
            if prob >= 0.2
            else "Low risk. No action needed."
        )
        results.append(
            {
                "slot": i + 1,
                "dna_probability": round(prob, 4),
                "risk_tier": risk_tier,
                "can_overbook": can_overbook,
                "expected_waste_minutes": round(expected_waste, 1),
                "recommendation": rec,
            }
        )

    return jsonify(
        {
            "slots": results,
            "summary": {
                "total_slots": len(appointments),
                "overbookable": overbookable_slots,
                "total_expected_waste_minutes": round(total_wasted_minutes, 1),
                "potential_recovery_percent": round((overbookable_slots / len(appointments)) * 100, 1)
                if appointments
                else 0,
            },
        }
    )


# ── Patient Nudge Message Generator ──

NUDGE_TEMPLATES = {
    "transport": {
        "en": "We understand getting to appointments can be difficult. Would a hospital transport service or phone/video consultation work better for you?",
        "cy": "Rydym yn deall y gall cyrraedd apwyntiadau fod yn anodd. A fyddai gwasanaeth cludiant ysbyty neu ymgynghoriad ffôn/fideo yn gweithio'n well i chi?",
        "ur": "ہم سمجتے ہیں کہ اپائنٹمنٹ تک پہنچنا مشکل ہو سکتا ہے۔ کیا ہسپتال کی نقل و حمل کی سروس یا فون/ویڈیو مشاورت آپ کے لیے بہتر ہوگی؟",
        "pl": "Rozumiemy, że dotarcie na wizyty może być trudne. Czy transport szpitalny lub konsultacja telefoniczna/wideo byłyby dla Ciebie lepsze?",
    },
    "reminder": {
        "en": "Just a friendly reminder about your upcoming appointment. If you need to reschedule, please call us — we're happy to find a time that works for you.",
        "cy": "Nodyn cyfeillgar am eich apwyntiad sydd ar y gweill. Os oes angen aildrefnu, ffoniwch ni.",
        "ur": "آپ کی آنے والی اپائنٹمنٹ کے بارے میں ایک دوستانہ یاد دہانی۔",
        "pl": "Przyjazne przypomnienie o nadchodzącej wizycie. Jeśli musisz przełożyć termin, zadzwoń do nas.",
    },
    "support": {
        "en": "We noticed you may face barriers to attending appointments. Our social prescribing team can help with transport, childcare, or other support. Would you like a referral?",
        "cy": "Rydym wedi sylwi y gallech wynebu rhwystrau i fynychu apwyntiadau. Gall ein tîm presgripsiynu cymdeithasol helpu.",
        "ur": "ہم نے محسوس کیا ہے کہ آپ کو اپائنٹمنٹ میں شرکت کرنے میں رکاوٹوں کا سامنا ہو سکتا ہے۔",
        "pl": "Zauważyliśmy, że możesz napotykać bariery w uczęszczaniu na wizyty. Nasz zespół może pomóc.",
    },
    "gentle": {
        "en": "We haven't seen you in a while and want to make sure you're okay. Your health matters to us. Please get in touch if there's anything we can do to help.",
        "cy": "Nid ydym wedi eich gweld ers tro ac eisiau gwneud yn siŵr eich bod yn iawn. Mae eich iechyd yn bwysig i ni.",
        "ur": "ہم نے آپ کو کچھ عرصے سے نہیں دیکھا اور یہ یقینی بنانا چاہتے ہیں کہ آپ ٹھیک ہیں۔",
        "pl": "Nie widzieliśmy Cię od jakiegoś czasu i chcemy się upewnić, że wszystko w porządku.",
    },
}


@app.route("/api/patient-nudge", methods=["POST"])
@token_required
@role_required("staff", "admin")
def generate_patient_nudge():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400
    patient_data = data.get("patient")
    if not patient_data:
        return jsonify({"error": "patient data required"}), 400
    patient, error = _validate_patient(patient_data)
    if error:
        return jsonify({"error": error}), 400

    language = data.get("language", "en")
    if language not in ("en", "cy", "ur", "pl"):
        language = "en"

    result = predictor.predict(patient)
    prob = result["probability"]
    age = patient.get("Age", 0)
    imd = patient.get("IMDDecile", 10)
    prior_dna = patient.get("PriorDNACount", 0)

    if age >= 65 or patient.get("Disability", 0) == 1:
        nudge_type = "transport"
    elif imd <= 3:
        nudge_type = "support"
    elif prior_dna >= 3:
        nudge_type = "gentle"
    else:
        nudge_type = "reminder"

    template = NUDGE_TEMPLATES.get(nudge_type, NUDGE_TEMPLATES["reminder"])
    message = template.get(language, template["en"])
    patient_name = data.get("patientName", "")
    if patient_name:
        message = f"Dear {patient_name}, {message[0].lower()}{message[1:]}"

    factors = []
    if age >= 65:
        factors.append("elderly_patient")
    if imd <= 3:
        factors.append("high_deprivation")
    if prior_dna >= 2:
        factors.append("repeat_dna")
    if patient.get("Disability", 0) == 1:
        factors.append("disability")
    if patient.get("SMSReceived", 0) == 0:
        factors.append("no_sms_reminder")
    if prob >= 0.5:
        factors.append("high_risk")

    return jsonify(
        {
            "nudge_type": nudge_type,
            "language": language,
            "message": message,
            "risk_probability": result["percentage"],
            "risk_tier": result["risk_tier"],
            "personalisation_factors": factors,
        }
    )


# ── Audit Log ──


@app.route("/api/audit-log", methods=["GET"])
@token_required
@role_required("admin")
def get_audit_log():
    logs = AuditLog.query.order_by(AuditLog.created_at.desc()).limit(100).all()
    return jsonify({"logs": [log.to_dict() for log in logs]})


# ── Admin User Management (admin-only RBAC, FR-04) ──


@app.route("/api/admin/users", methods=["GET"])
@token_required
@role_required("admin")
def admin_list_users():
    users = User.query.order_by(User.created_at.desc()).all()
    return jsonify({"users": [u.to_dict() for u in users], "total": len(users)})


@app.route("/api/admin/users/<user_id>/role", methods=["PUT"])
@token_required
@role_required("admin")
def admin_set_role(user_id):
    data = request.get_json() or {}
    new_role = data.get("role", "")
    if new_role not in VALID_ROLES:
        return jsonify({"error": f"role must be one of: {', '.join(sorted(VALID_ROLES))}"}), 400

    target = db.session.get(User, user_id)
    if not target:
        return jsonify({"error": "User not found"}), 404

    # Guard: do not let an admin demote themselves (avoids self-lockout).
    if target.id == request.current_user["userId"] and new_role != "admin":
        return jsonify({"error": "You cannot change your own admin role"}), 400

    old_role = target.role
    target.role = new_role
    db.session.add(
        _audit(request.current_user["userId"], "role_changed", f"{target.username}: {old_role} -> {new_role}")
    )
    db.session.commit()
    return jsonify({"message": "Role updated", "user": target.to_dict()})


@app.route("/api/admin/pending-users", methods=["GET"])
@token_required
@role_required("admin")
def admin_pending_users():
    """Onboarding queue: self-registered accounts (role 'user') awaiting
    approval. Approving one elevates it to an operational role."""
    pending = User.query.filter_by(role="user").order_by(User.created_at.asc()).all()
    return jsonify({"pending": [u.to_dict() for u in pending], "total": len(pending)})


@app.route("/api/admin/users/<user_id>/approve", methods=["POST"])
@token_required
@role_required("admin")
def admin_approve_user(user_id):
    """Approve a pending registration, granting an operational role.

    Approval target defaults to 'staff'; an admin may grant 'admin'. Approving
    is idempotent-safe: a user already at staff/admin is reported as such.
    """
    data = request.get_json() or {}
    grant_role = data.get("role", "staff")
    if grant_role not in ("staff", "admin"):
        return jsonify({"error": "Approval role must be 'staff' or 'admin'"}), 400

    target = db.session.get(User, user_id)
    if not target:
        return jsonify({"error": "User not found"}), 404
    if target.role != "user":
        return jsonify({"error": f"User already approved (role: {target.role})"}), 400

    target.role = grant_role
    db.session.add(_audit(request.current_user["userId"], "user_approved", f"{target.username}: user -> {grant_role}"))
    db.session.commit()
    return jsonify({"message": f"User approved as {grant_role}", "user": target.to_dict()})


@app.route("/api/admin/users/<user_id>", methods=["DELETE"])
@token_required
@role_required("admin")
def admin_delete_user(user_id):
    if user_id == request.current_user["userId"]:
        return jsonify({"error": "You cannot delete your own account"}), 400
    target = db.session.get(User, user_id)
    if not target:
        return jsonify({"error": "User not found"}), 404
    username = target.username
    db.session.delete(target)
    db.session.add(_audit(request.current_user["userId"], "user_deleted", username))
    db.session.commit()
    return jsonify({"message": f"User {username} deleted"})


def _audit(user_id, action, detail=None):
    """Build an AuditLog row (caller commits)."""
    return AuditLog(
        user_id=user_id,
        action=action,
        detail=detail,
        ip_address=request.remote_addr,
    )


# ── Helpers ──


def _validate_patient(data):
    try:
        patient = {
            "Age": int(data["Age"]),
            "Gender": int(data["Gender"]),
            "AppointmentLeadTimeDays": int(data["AppointmentLeadTimeDays"]),
            "SMSReceived": int(data["SMSReceived"]),
            "PriorDNACount": int(data["PriorDNACount"]),
            "Hypertension": int(data.get("Hypertension", 0)),
            "Diabetes": int(data.get("Diabetes", 0)),
            "Alcoholism": int(data.get("Alcoholism", 0)),
            "Disability": int(data.get("Disability", 0)),
            "IMDDecile": int(data["IMDDecile"]),
        }
    except (ValueError, TypeError, KeyError) as e:
        return None, f"Invalid data format: {e}"

    if not (0 <= patient["Age"] <= 120):
        return None, "Age must be between 0 and 120"
    if not (1 <= patient["IMDDecile"] <= 10):
        return None, "IMD Decile must be between 1 and 10"

    return patient, None


def _parse_iso_date(value):
    try:
        return datetime.strptime(str(value), "%Y-%m-%d").date()
    except (TypeError, ValueError):
        return None


def _date_in_period(value, start_date=None, end_date=None):
    parsed = _parse_iso_date(value)
    if not parsed:
        return False
    if start_date and parsed < _parse_iso_date(start_date):
        return False
    if end_date and parsed > _parse_iso_date(end_date):
        return False
    return True


def _appointment_in_period(appointment, start_date=None, end_date=None):
    return _date_in_period(appointment.appointment_date, start_date, end_date)


def _appointment_outcome_stats(appointments):
    total = len(appointments)
    attended = sum(1 for appt in appointments if appt.status == "attended")
    dna = sum(1 for appt in appointments if appt.status == "dna")
    return {
        "total": total,
        "attended": attended,
        "dna": dna,
        "attended_rate": round(attended / total, 4) if total else 0,
        "dna_rate": round(dna / total, 4) if total else 0,
    }


def _appointment_lead_time_days(appointment_date):
    parsed = _parse_iso_date(appointment_date)
    if not parsed:
        return 0
    return max((parsed - date.today()).days, 0)


def _appointment_patient_payload(item):
    patient_id = str(item.get("patient_id", "")).strip()
    payload = {}
    if patient_id in EHR_MOCK_PATIENTS:
        payload.update({k: v for k, v in EHR_MOCK_PATIENTS[patient_id].items() if k != "name"})
    payload.update(item.get("patient") or item.get("patient_data") or {})

    for field in (
        "Age",
        "Gender",
        "AppointmentLeadTimeDays",
        "SMSReceived",
        "PriorDNACount",
        "Hypertension",
        "Diabetes",
        "Alcoholism",
        "Disability",
        "IMDDecile",
    ):
        if field in item:
            payload[field] = item[field]

    payload.setdefault("AppointmentLeadTimeDays", _appointment_lead_time_days(item.get("appointment_date")))
    payload.setdefault("SMSReceived", 1)
    return _validate_patient(payload)


def _generate_nl_summary(patient, result, age_group):
    prob = result["percentage"]
    tier = result["risk_tier"]
    shap = result["shap_values"]
    age = patient["Age"]

    gender_word = "male" if patient["Gender"] == 1 else "female"
    top_factors = []

    for sv in shap[:3]:
        if sv["direction"] == "risk-increasing":
            feat = sv["feature"]
            if feat == "PriorDNACount":
                top_factors.append(f"has missed {patient['PriorDNACount']} previous appointments")
            elif feat == "Age":
                top_factors.append(f"is {age} years old (age group {age_group})")
            elif feat == "IMDDecile":
                lvl = "high" if patient["IMDDecile"] <= 3 else "moderate"
                top_factors.append(f"lives in an area with {lvl} deprivation (IMD {patient['IMDDecile']})")
            elif feat == "AppointmentLeadTimeDays":
                top_factors.append(f"has a {patient['AppointmentLeadTimeDays']}-day wait before the appointment")
            elif feat == "SMSReceived":
                top_factors.append("has not received an SMS reminder")
            elif feat == "Hypertension":
                top_factors.append("has a hypertension diagnosis")
            elif feat == "Diabetes":
                top_factors.append("has a diabetes diagnosis")
            elif feat == "Alcoholism":
                top_factors.append("has alcohol dependency")
            elif feat == "Disability":
                top_factors.append("has a registered disability")
            else:
                top_factors.append(f"{sv['label'].lower()} is a contributing factor")

    if not top_factors:
        return f"This {age}-year-old {gender_word} patient has a {prob}% DNA risk ({tier})."

    factors_text = top_factors[0]
    if len(top_factors) == 2:
        factors_text = f"{top_factors[0]} and {top_factors[1]}"
    elif len(top_factors) >= 3:
        factors_text = f"{', '.join(top_factors[:-1])}, and {top_factors[-1]}"

    return (
        f"This {age}-year-old {gender_word} patient ({age_group} age group) "
        f"has a {prob}% risk of missing their appointment ({tier} risk). "
        f"The main contributing factors are that the patient {factors_text}."
    )


def ensure_database():
    """Guarantee the schema exists so the DB 'just works' when the backend
    starts — create_all is idempotent and complements Alembic migrations."""
    with app.app_context():
        try:
            db.create_all()
            print("Database ready (schema ensured).")
        except Exception as exc:  # pragma: no cover
            print(f"WARNING: could not initialise database: {exc}")


@app.cli.command("create-admin")
def create_admin_command():
    """Seed/promote an admin account OUT-OF-BAND (never via the public route).

    Public /auth/register can only create unprivileged 'user' accounts; the
    first admin must be created here. Credentials come from the environment so
    they are never hard-coded:
        CAREATTEND_ADMIN_USER, CAREATTEND_ADMIN_EMAIL, CAREATTEND_ADMIN_PASSWORD
    Run: `flask --app app create-admin`. Idempotent — promotes if user exists.
    """
    username = os.environ.get("CAREATTEND_ADMIN_USER")
    email = os.environ.get("CAREATTEND_ADMIN_EMAIL")
    password = os.environ.get("CAREATTEND_ADMIN_PASSWORD")
    if not (username and email and password):
        print("Set CAREATTEND_ADMIN_USER, CAREATTEND_ADMIN_EMAIL and CAREATTEND_ADMIN_PASSWORD first.")
        return

    db.create_all()
    existing = User.query.filter((User.username == username) | (User.email == email)).first()
    if existing:
        existing.role = "admin"
        db.session.commit()
        print(f"Promoted existing account '{existing.username}' to admin.")
        return

    _, error = register_user(username, email, password, "admin")
    if error:
        # Note: 'error' is a static validation message (e.g. the password rule),
        # never the credential itself — but keep it out of the printed line so
        # no value derived from the password call reaches stdout.
        print("Could not create admin — check the username/email/password meet the rules.")
        return
    print(f"Admin account '{username}' created.")


if __name__ == "__main__":
    print("Loading Care Attend models...")
    load_models()
    ensure_database()
    print("Models loaded. Starting server...")
    port = int(os.environ.get("PORT", 5000))
    # Secure by default: debug off unless explicitly opted in (Werkzeug's
    # interactive debugger is an RCE vector if exposed).
    debug = os.environ.get("FLASK_DEBUG", "0") == "1"
    print(f"Open http://127.0.0.1:{port} in your browser")
    app.run(debug=debug, host="127.0.0.1", port=port)
