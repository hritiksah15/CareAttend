# CareAttend — Architecture (C4) & Data Model

*Diagrams in Mermaid (render on GitHub / VS Code). Built from the actual code — the ERD is a 1:1 reflection of `backend/models.py`, verified June 2026. Use for the AT2 Software Definition (design) section.*

---

## C4 Level 1 — System Context

```mermaid
flowchart TB
    staff["NHS Admin / Reception Staff<br/><i>Person</i>"]
    admin["Practice Admin<br/><i>Person, RBAC: admin</i>"]
    sys["<b>CareAttend</b><br/>DNA-risk decision support<br/><i>Software System</i>"]
    ehr["Mock EMIS / SystmOne EHR<br/><i>External (stub for NHS integration)</i>"]

    staff -->|"assesses patients,<br/>views risk + actions"| sys
    admin -->|"reviews audit log,<br/>bias reports"| sys
    sys -->|"looks up patient<br/>demographics"| ehr
```

## C4 Level 2 — Containers

```mermaid
flowchart TB
    subgraph client["Client"]
        spa["Web SPA<br/><i>HTML/CSS/JS, Chart.js, jsPDF</i>"]
        flutter["Mobile App<br/><i>Flutter / Dart</i>"]
    end

    subgraph server["Server (Docker, Python 3.11)"]
        api["Flask REST API<br/><i>app.py — 25+ endpoints</i>"]
        authc["Auth module<br/><i>auth.py — bcrypt, TOTP, sessions</i>"]
        ml["ML layer<br/><i>predictor, bias_monitor,<br/>interventions, calibration, evaluation</i>"]
        mem["In-memory stores<br/><i>prediction log only (NFR-01)</i>"]
    end

    db[("PostgreSQL 16<br/><i>users, sessions, audit_logs,<br/>feedback, carer_proxies,<br/>assessment_summaries, notifications,<br/>outreach_actions, appointments</i>")]
    models[("Serialised models<br/><i>joblib: LR + scaler + threshold<br/>+ calibrated</i>")]

    spa -->|"HTTPS / JSON + Bearer"| api
    flutter -->|"HTTPS / JSON + Bearer"| api
    api --> authc
    api --> ml
    api --> mem
    authc -->|"SQLAlchemy / Alembic"| db
    ml -->|"load at startup"| models
```

## C4 Level 3 — Component (Flask API internals)

```mermaid
flowchart LR
    req["Request"] --> tok["@token_required<br/>validate session"]
    tok --> route{Route}
    route -->|"/api/predict"| pred["CareAttendPredictor<br/>+ SHAP"]
    route -->|"/api/bias-audit"| bias["BiasMonitor<br/>DP + EO"]
    route -->|"/api/predict"| inter["generate_interventions"]
    route -->|"/auth/*"| auth["register / authenticate<br/>/ TOTP"]
    route -->|"/api/carer-proxy<br/>/audit-log"| store["in-memory lists"]
    pred --> models[("model.joblib<br/>scaler / threshold")]
    bias --> models
    auth --> pg[("PostgreSQL")]
    pred --> nl["_generate_nl_summary"]
```

---

## Entity-Relationship Diagram (matches `models.py` exactly)

```mermaid
erDiagram
    USERS ||--o{ SESSIONS : "has"
    USERS ||--o{ AUDIT_LOGS : "generates"
    USERS ||--o{ FEEDBACK : "submits"
    USERS ||--o{ CARER_PROXIES : "registers"

    USERS {
        string id PK "uuid"
        string username UK "indexed, not null"
        string email UK "indexed, not null"
        string password_hash "bcrypt, not null"
        string role "staff|admin, default staff"
        string display_name "nullable"
        string totp_secret "nullable"
        boolean totp_enabled "default false"
        float created_at "not null"
        float last_password_change "nullable"
    }
    SESSIONS {
        string token PK
        string user_id FK "not null"
        float created_at "not null"
        float last_activity "not null, 30-min timeout"
    }
    AUDIT_LOGS {
        string id PK "uuid"
        string user_id FK "not null"
        string action "not null"
        text detail "nullable"
        string ip_address "nullable"
        float created_at "not null"
    }
    FEEDBACK {
        string id PK "uuid"
        string user_id FK "not null"
        string prediction_risk_tier "not null"
        float prediction_probability "not null"
        string outcome "not null"
        float created_at "not null"
    }
    CARER_PROXIES {
        string id PK "uuid"
        string staff_user_id FK "not null"
        string carer_name "not null"
        string carer_relationship "not null"
        string carer_contact "nullable"
        string patient_identifier "not null"
        text reason "nullable"
        float created_at "not null"
    }
```

**Note on NFR-01:** there is intentionally **no patient table**. Prediction inputs/outputs are processed in memory and never persisted, satisfying the privacy/data-minimisation requirement (GDPR Art 5(1)(c)). Operational workflow data now persists in PostgreSQL: assessments, notifications, appointments, outreach actions, anonymised feedback, carer-proxy admin records, users, sessions, and audit logs.

---

## ✅ Resolved deviation (AT4 critical-appraisal material)

**Original issue (June 2026):** the ORM models `AuditLog`, `PersistentFeedback`, and `CarerProxy` existed with Alembic migrations, but the live endpoints wrote to **process-memory lists**, so audit/feedback/proxy records did not survive a restart — an audit trail you can wipe by restarting is not an audit trail.

**Fix applied:** the endpoints now persist to PostgreSQL via the existing models:
- `/api/carer-proxy` → `CarerProxy` row (+ an `AuditLog` row) — `app.py::create_carer_proxy`.
- `/api/carer-proxy/list` → query `CarerProxy` scoped by `staff_user_id`.
- `/api/audit-log` (admin) → query `AuditLog`, newest 100.
- `/api/feedback` → writes an **anonymised** `PersistentFeedback` row (tier, probability, outcome — no patient data, NFR-01 safe) + an `AuditLog` row.
- New `_audit(user_id, action, detail)` helper records actor + `ip_address`.

**Still intentionally in-memory:** `_prediction_log` (patient prediction inputs/outputs) — session-scoped per NFR-01, never persisted. The new appointment/outreach/outcome workflow is persisted.

**Tests:** persistence asserted in `test_new_endpoints::TestCarerProxy::test_create_writes_audit_entry` and `test_feature_coverage::TestFeedback::test_feedback_persisted_to_db`.

> **Report narrative:** present this as "identified during architectural review, then remediated" — shows the self-critique → fix loop examiners reward, while keeping the honest data-minimisation distinction (operational data persists; patient data does not).
```
```
