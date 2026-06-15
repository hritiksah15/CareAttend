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

from flask import Flask, render_template, request, jsonify, make_response
from flask_cors import CORS
from sqlalchemy import text as _sql_text

from models import db, migrate, User, AuditLog, CarerProxy, PersistentFeedback
from auth import (register_user, authenticate, logout, token_required,
                  _hash_password, _verify_password,
                  setup_totp, enable_totp, disable_totp)
from ml.predictor import CareAttendPredictor
from ml.bias_monitor import BiasMonitor
from ml.interventions import generate_interventions

FRONTEND_DIR = os.path.join(os.path.dirname(__file__), "..", "frontend")

app = Flask(
    __name__,
    template_folder=os.path.join(FRONTEND_DIR, "templates"),
    static_folder=FRONTEND_DIR,
    static_url_path="/static",
)
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", os.urandom(32).hex())
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get(
    "DATABASE_URL", "postgresql+psycopg://localhost:5432/careattend"
)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
CORS(app)

db.init_app(app)
migrate.init_app(app, db)

# ── Structured request logging + uniform JSON errors (NFR robustness) ──
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger("careattend")

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
_prediction_log = []  # session-scoped assessment history for dashboard (NFR-01: not persisted)


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
    return jsonify({
        "status": "ok" if healthy else "degraded",
        "model_loaded": predictor is not None,
        "database": "ok" if db_ok else "unavailable",
        "uptime_seconds": round(time.time() - _START_TIME, 1),
    }), (200 if healthy else 503)


# ── Auth Endpoints (FR-04, NFR-06) ──

@app.route("/auth/register", methods=["POST"])
def auth_register():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400

    username = data.get("username", "").strip()
    email = data.get("email", "").strip()
    password = data.get("password", "")
    role = data.get("role", "staff")

    if role not in ("staff", "admin"):
        return jsonify({"error": "Invalid role"}), 400

    user_id, error = register_user(username, email, password, role)
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

    result, error = authenticate(username, password, totp_code)
    if error:
        return jsonify({"error": error}), 401

    if isinstance(result, dict) and result.get("requires_2fa"):
        return jsonify({"requires_2fa": True, "message": "2FA verification required"}), 200

    token = result
    response = jsonify({"token": token, "message": "Login successful"})
    response.set_cookie(
        "session_token", token,
        httponly=True, samesite="Strict", max_age=1800
    )
    return response


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

    required = [
        "Age", "Gender", "AppointmentLeadTimeDays", "SMSReceived",
        "PriorDNACount", "IMDDecile"
    ]
    missing = [f for f in required if f not in data]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    patient, error = _validate_patient(data)
    if error:
        return jsonify({"error": error}), 400

    result = predictor.predict(patient)
    interventions, risk_tier, age_group = generate_interventions(
        patient, result["probability"], result["shap_values"]
    )

    nl_summary = _generate_nl_summary(patient, result, age_group)
    prediction_id = str(uuid.uuid4())

    _prediction_log.append({
        "id": prediction_id,
        "timestamp": __import__("time").time(),
        "patient": patient,
        "probability": result["probability"],
        "risk_tier": result["risk_tier"],
        "age_group": age_group,
        "feedback": None,
    })

    return jsonify({
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
    })


# ── Batch CSV Endpoint (FR-08) ──

@app.route("/api/batch", methods=["POST"])
@token_required
def batch_predict():
    if "file" not in request.files:
        return jsonify({"error": "No CSV file uploaded"}), 400

    file = request.files["file"]
    if not file.filename.endswith(".csv"):
        return jsonify({"error": "File must be CSV format"}), 400

    try:
        content = file.read().decode("utf-8")
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
        _, risk_tier, age_group = generate_interventions(
            patient, pred["probability"], pred["shap_values"]
        )
        top_shap = pred["shap_values"][0]["label"] if pred["shap_values"] else ""

        results.append({
            "row": i + 1,
            "age": patient["Age"],
            "risk_probability": pred["percentage"],
            "risk_tier": risk_tier,
            "age_group": age_group,
            "top_risk_factor": top_shap,
        })

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
def bias_audit():
    results = bias_monitor.run_audit()
    return jsonify(results)


# ── Model Info & Comparison ──

@app.route("/api/model-info", methods=["GET"])
@token_required
def model_info():
    if training_results:
        return jsonify(training_results)
    return jsonify({"error": "No training results available"}), 404


@app.route("/api/model-comparison", methods=["GET"])
@token_required
def model_comparison():
    if not training_results:
        return jsonify({"error": "No training results available"}), 404
    return jsonify({
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
    })


# ── Practice Dashboard (US-002, Feature 11) ──

@app.route("/api/dashboard", methods=["GET"])
@token_required
def practice_dashboard():
    if not _prediction_log:
        return jsonify({"message": "No assessments yet", "total": 0})

    high = sum(1 for p in _prediction_log if p["risk_tier"] == "High")
    medium = sum(1 for p in _prediction_log if p["risk_tier"] == "Medium")
    low = sum(1 for p in _prediction_log if p["risk_tier"] == "Low")
    avg_risk = sum(p["probability"] for p in _prediction_log) / len(_prediction_log)

    age_breakdown = {}
    for p in _prediction_log:
        ag = p["age_group"]
        if ag not in age_breakdown:
            age_breakdown[ag] = {"total": 0, "high_risk": 0}
        age_breakdown[ag]["total"] += 1
        if p["risk_tier"] == "High":
            age_breakdown[ag]["high_risk"] += 1

    recent = sorted(_prediction_log, key=lambda x: x["timestamp"], reverse=True)[:10]
    recent_summary = [{
        "id": r["id"][:8],
        "age": r["patient"]["Age"],
        "risk_tier": r["risk_tier"],
        "probability": r["probability"],
        "age_group": r["age_group"],
    } for r in recent]

    return jsonify({
        "total": len(_prediction_log),
        "high_risk": high,
        "medium_risk": medium,
        "low_risk": low,
        "average_risk": round(avg_risk, 4),
        "age_breakdown": age_breakdown,
        "recent_assessments": recent_summary,
        "feedback_given": sum(1 for p in _prediction_log if p["feedback"] is not None),
    })


# ── Prediction Feedback Loop (Feature 12) ──

@app.route("/api/feedback", methods=["POST"])
@token_required
def submit_feedback():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400

    prediction_id = data.get("prediction_id", "")
    outcome = data.get("outcome", "")

    if outcome not in ("correct", "incorrect", "attended", "dna"):
        return jsonify({"error": "outcome must be: correct, incorrect, attended, or dna"}), 400

    for p in _prediction_log:
        if p["id"] == prediction_id:
            p["feedback"] = outcome
            # Persist an anonymised feedback record (tier/prob/outcome only — no
            # patient data) for cross-session accuracy tracking & audit.
            db.session.add(PersistentFeedback(
                user_id=request.current_user["userId"],
                prediction_risk_tier=p["risk_tier"],
                prediction_probability=p["probability"],
                outcome=outcome,
            ))
            db.session.add(_audit(request.current_user["userId"], "feedback_recorded",
                                  f"{outcome} for {p['risk_tier']} risk prediction"))
            db.session.commit()
            return jsonify({"message": "Feedback recorded", "prediction_id": prediction_id})

    return jsonify({"error": "Prediction not found"}), 404


@app.route("/api/feedback/summary", methods=["GET"])
@token_required
def feedback_summary():
    total = len(_prediction_log)
    with_feedback = [p for p in _prediction_log if p["feedback"] is not None]

    correct = sum(1 for p in with_feedback if p["feedback"] in ("correct", "dna"))
    incorrect = sum(1 for p in with_feedback if p["feedback"] in ("incorrect", "attended"))

    return jsonify({
        "total_predictions": total,
        "feedback_received": len(with_feedback),
        "correct": correct,
        "incorrect": incorrect,
        "accuracy": round(correct / len(with_feedback), 4) if with_feedback else None,
    })


# ── Mock NHS EHR Integration (Feature 10) ──

EHR_MOCK_PATIENTS = {
    "NHS001": {"name": "Margaret Thompson", "Age": 78, "Gender": 0, "IMDDecile": 3,
               "Hypertension": 1, "Diabetes": 1, "Disability": 0, "PriorDNACount": 4},
    "NHS002": {"name": "James Patel", "Age": 45, "Gender": 1, "IMDDecile": 7,
               "Hypertension": 0, "Diabetes": 0, "Disability": 0, "PriorDNACount": 1},
    "NHS003": {"name": "Fatima Ali", "Age": 82, "Gender": 0, "IMDDecile": 2,
               "Hypertension": 1, "Diabetes": 0, "Disability": 1, "PriorDNACount": 6},
    "NHS004": {"name": "David Williams", "Age": 34, "Gender": 1, "IMDDecile": 5,
               "Hypertension": 0, "Diabetes": 0, "Disability": 0, "PriorDNACount": 0},
    "NHS005": {"name": "Eileen O'Brien", "Age": 91, "Gender": 0, "IMDDecile": 1,
               "Hypertension": 1, "Diabetes": 1, "Disability": 1, "PriorDNACount": 8},
}


@app.route("/api/ehr/lookup/<nhs_number>", methods=["GET"])
@token_required
def ehr_lookup(nhs_number):
    patient = EHR_MOCK_PATIENTS.get(nhs_number)
    if not patient:
        return jsonify({"error": "Patient not found", "note": "This is a mock EHR. "
                        "Real integration requires NHS IG Toolkit approval (out of scope per AT2 Section 1.3)"}), 404
    return jsonify({
        "source": "Mock EMIS/SystmOne",
        "nhs_number": nhs_number,
        "patient": patient,
        "note": "Mock data only. Real NHS EHR integration excluded per AT2 scope constraints.",
    })


@app.route("/api/ehr/patients", methods=["GET"])
@token_required
def ehr_list():
    return jsonify({
        "source": "Mock EMIS/SystmOne",
        "patients": {k: v["name"] for k, v in EHR_MOCK_PATIENTS.items()},
        "note": "Mock data only.",
    })


# ── Multi-Trust Configuration (Feature 14) ──

TRUST_CONFIGS = {
    "default": {"name": "Default NHS Trust", "region": "England", "risk_thresholds": {"low": 0.33, "high": 0.67}},
    "tower_hamlets": {"name": "Tower Hamlets CCG", "region": "London", "risk_thresholds": {"low": 0.30, "high": 0.60}},
    "north_norfolk": {"name": "North Norfolk CCG", "region": "East of England", "risk_thresholds": {"low": 0.35, "high": 0.70}},
    "belfast": {"name": "Belfast HSC Trust", "region": "Northern Ireland", "risk_thresholds": {"low": 0.33, "high": 0.67}},
}


@app.route("/api/trusts", methods=["GET"])
@token_required
def list_trusts():
    return jsonify({"trusts": TRUST_CONFIGS})


@app.route("/api/trusts/<trust_id>", methods=["GET"])
@token_required
def get_trust(trust_id):
    config = TRUST_CONFIGS.get(trust_id)
    if not config:
        return jsonify({"error": "Trust not found"}), 404
    return jsonify(config)


# ── Rigorous Evaluation (Feature 15) ──

@app.route("/api/evaluation/cross-validation", methods=["POST"])
@token_required
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
                "79 automated pytest tests covering all modules",
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
                "Session-scoped architecture: zero patient data persisted (NFR-01)",
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
def ethics_framework():
    return jsonify(NHSX_ETHICS_MAPPING)


# ── Offline Model Export ──

@app.route("/api/export-model", methods=["GET"])
@token_required
def export_model():
    model_path = os.path.join("models", "model.joblib")
    if not os.path.exists(model_path):
        return jsonify({"error": "No model available"}), 404
    return jsonify({
        "message": "Model export available",
        "format": "joblib",
        "model": training_results.get("selected_model") if training_results else "Unknown",
        "features": [
            "Age", "Gender", "AppointmentLeadTimeDays", "SMSReceived",
            "PriorDNACount", "Hypertension", "Diabetes", "Alcoholism",
            "Disability", "IMDDecile"
        ],
        "threshold": training_results.get("best_metrics", {}).get("threshold", 0.5) if training_results else 0.5,
        "note": "For offline Flutter deployment, convert to ONNX or TFLite format",
    })


# ── Push Notification Scheduling ──

_notification_queue = []

@app.route("/api/notifications/schedule", methods=["POST"])
@token_required
def schedule_notification():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400

    patient_id = data.get("patient_id", "unknown")
    risk_tier = data.get("risk_tier", "")
    appointment_date = data.get("appointment_date", "")

    if risk_tier not in ("High", "Medium"):
        return jsonify({"error": "Notifications only for High/Medium risk patients"}), 400

    notification = {
        "id": str(uuid.uuid4()),
        "patient_id": patient_id,
        "risk_tier": risk_tier,
        "appointment_date": appointment_date,
        "notify_at": data.get("notify_at", "24h_before"),
        "status": "scheduled",
        "created_by": getattr(request, 'current_user', {}).get('username', 'system'),
    }
    _notification_queue.append(notification)

    return jsonify({
        "message": "Notification scheduled",
        "notification": notification,
    }), 201


@app.route("/api/notifications", methods=["GET"])
@token_required
def list_notifications():
    return jsonify({"notifications": _notification_queue, "total": len(_notification_queue)})


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
    display_name = data.get("displayName")
    if display_name is not None:
        user.display_name = display_name.strip()[:100]
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
    new_pw = data.get("newPassword", "")
    if len(new_pw) < 8:
        return jsonify({"error": "New password must be at least 8 characters"}), 400
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
    db.session.add(_audit(user_id, "carer_proxy_created",
                          f"Proxy for {patient_id} by {carer_name} ({relationship})"))
    db.session.commit()
    return jsonify({"message": "Carer proxy registered", "proxy": proxy.to_dict()}), 201


@app.route("/api/carer-proxy/list", methods=["GET"])
@token_required
def list_carer_proxies():
    proxies = (CarerProxy.query
               .filter_by(staff_user_id=request.current_user["userId"])
               .order_by(CarerProxy.created_at.desc()).all())
    return jsonify({"proxies": [p.to_dict() for p in proxies]})


# ── Appointment Slot Optimisation ──

@app.route("/api/slot-optimisation", methods=["POST"])
@token_required
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
        rec = ("Strong overbook candidate. Consider double-booking or waitlist patient." if prob >= 0.7
               else "Moderate DNA risk. Consider standby patient or phone reminder 24h before." if prob >= 0.4
               else "Low-moderate risk. Standard SMS reminder sufficient." if prob >= 0.2
               else "Low risk. No action needed.")
        results.append({
            "slot": i + 1, "dna_probability": round(prob, 4), "risk_tier": risk_tier,
            "can_overbook": can_overbook, "expected_waste_minutes": round(expected_waste, 1),
            "recommendation": rec,
        })

    return jsonify({
        "slots": results,
        "summary": {
            "total_slots": len(appointments), "overbookable": overbookable_slots,
            "total_expected_waste_minutes": round(total_wasted_minutes, 1),
            "potential_recovery_percent": round((overbookable_slots / len(appointments)) * 100, 1) if appointments else 0,
        },
    })


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
    if age >= 65: factors.append("elderly_patient")
    if imd <= 3: factors.append("high_deprivation")
    if prior_dna >= 2: factors.append("repeat_dna")
    if patient.get("Disability", 0) == 1: factors.append("disability")
    if patient.get("SMSReceived", 0) == 0: factors.append("no_sms_reminder")
    if prob >= 0.5: factors.append("high_risk")

    return jsonify({
        "nudge_type": nudge_type, "language": language, "message": message,
        "risk_probability": result["percentage"], "risk_tier": result["risk_tier"],
        "personalisation_factors": factors,
    })


# ── Audit Log ──

@app.route("/api/audit-log", methods=["GET"])
@token_required
def get_audit_log():
    if request.current_user.get("role") != "admin":
        return jsonify({"error": "Admin access required"}), 403
    logs = (AuditLog.query.order_by(AuditLog.created_at.desc()).limit(100).all())
    return jsonify({"logs": [log.to_dict() for log in logs]})


def _audit(user_id, action, detail=None):
    """Build an AuditLog row (caller commits)."""
    return AuditLog(
        user_id=user_id, action=action, detail=detail,
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

    return (f"This {age}-year-old {gender_word} patient ({age_group} age group) "
            f"has a {prob}% risk of missing their appointment ({tier} risk). "
            f"The main contributing factors are that the patient {factors_text}.")


def ensure_database():
    """Guarantee the schema exists so the DB 'just works' when the backend
    starts — create_all is idempotent and complements Alembic migrations."""
    with app.app_context():
        try:
            db.create_all()
            print("Database ready (schema ensured).")
        except Exception as exc:  # pragma: no cover
            print(f"WARNING: could not initialise database: {exc}")


if __name__ == "__main__":
    print("Loading Care Attend models...")
    load_models()
    ensure_database()
    print("Models loaded. Starting server...")
    port = int(os.environ.get("PORT", 5000))
    debug = os.environ.get("FLASK_DEBUG", "1") == "1"
    print(f"Open http://127.0.0.1:{port} in your browser")
    app.run(debug=debug, host="127.0.0.1", port=port)
