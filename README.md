# CareAttend — NHS Predictive Risk Assessment for Missed Appointments

[![CI](https://github.com/hritiksah15/CareAttend/actions/workflows/ci.yml/badge.svg)](https://github.com/hritiksah15/CareAttend/actions/workflows/ci.yml)
[![CodeQL](https://github.com/hritiksah15/CareAttend/actions/workflows/codeql.yml/badge.svg)](https://github.com/hritiksah15/CareAttend/actions/workflows/codeql.yml)
[![Python](https://img.shields.io/badge/python-3.12-blue.svg)](https://www.python.org/)
[![Flutter](https://img.shields.io/badge/flutter-stable-blue.svg)](https://flutter.dev/)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

CareAttend predicts the likelihood that a patient will miss (**DNA — "Did Not Attend"**) an
NHS outpatient appointment, explains *why*, audits the model for demographic bias, and
recommends targeted interventions to reduce no-shows. It ships as a Flask REST API with a
web client and a cross-platform Flutter app sharing the same backend.

> Final-year BSc Computing dissertation project (**COM668**, Ulster University).

---

## Why it matters

Missed NHS appointments cost an estimated £216 per slot and waste clinical capacity. Rather
than a blunt overbooking policy, CareAttend produces a **calibrated per-patient risk score**
with a transparent, auditable rationale — so clinics can act on the patients who genuinely
need a reminder, a phone call, or a rescheduled slot, without entrenching bias against
already-disadvantaged groups.

## Features

- **DNA risk prediction** — calibrated probability + risk tier per patient.
- **Explainability** — per-prediction **SHAP** feature contributions and a plain-English summary.
- **Probability calibration** — isotonic/Platt-calibrated outputs (reliability reported).
- **Bias monitoring + governance gate** — fairness audit across age, gender, deprivation (IMD)
  with an aggregate PASS / ACTION_REQUIRED verdict and human-oversight actions (monitoring only;
  no protected-attribute thresholds).
- **Operational loop** — appointment clinic list → outreach actions → notification delivery
  (simulated provider, full send/retry lifecycle) → operational-outcomes dashboard.
- **Staff onboarding approval** — self-registrations land unprivileged; an admin approves to grant
  the staff role (admin seeded out-of-band via `flask create-admin`).
- **Intervention engine** — ranked, factor-driven nudges (SMS, call, transport, reminders).
- **Multilingual patient nudges** — generated reminder messaging.
- **Slot optimisation** — overbooking / expected-waste / recovery metrics.
- **Security & accounts** — bcrypt password hashing, strong-password policy, **TOTP 2FA**,
  role-based access control (User / Staff / Admin), DB-backed sessions with "remember me",
  OTP password reset, audit logging, GDPR-aligned privacy posture.
- **Three surfaces, one API** — Flask REST API · static JS web client · Flutter app.

## Architecture

```
┌──────────────┐     ┌──────────────┐        ┌─────────────────────────────┐
│  Web client  │     │ Flutter app  │        │        Flask REST API       │
│ (HTML/JS)    │────▶│ (iOS/Android │──────▶ │  auth · /api/predict ·      │
│              │     │  /web)       │  HTTPS  │  bias-audit · interventions │
└──────────────┘     └──────────────┘        └──────────────┬──────────────┘
                                                             │
                          ┌──────────────────────────────────┼───────────────────┐
                          ▼                                   ▼                   ▼
                  ┌───────────────┐                 ┌──────────────────┐  ┌──────────────┐
                  │ ML pipeline   │                 │ SHAP + bias      │  │ PostgreSQL   │
                  │ (predictor)   │                 │ monitor + calib. │  │ (SQLAlchemy) │
                  └───────────────┘                 └──────────────────┘  └──────────────┘
```

- **Backend** ([backend/](backend/)) — Flask app ([backend/app.py](backend/app.py), 38 routes),
  auth ([backend/auth.py](backend/auth.py)), SQLAlchemy models ([backend/models.py](backend/models.py)),
  Alembic migrations, and the ML package ([backend/ml/](backend/ml/): `predictor`, `pipeline`,
  `bias_monitor`, `calibration`, `interventions`, `data_generator`).
- **Production entrypoint** — [backend/wsgi.py](backend/wsgi.py) loads the models and ensures
  the schema at import, served by **gunicorn**.
- **Frontend** ([frontend/](frontend/)) — static HTML/JS client.
- **Flutter app** ([care_attend_app/](care_attend_app/)) — 14 screens at parity with the web client.

## Tech stack

| Layer        | Technology |
|--------------|------------|
| API          | Python 3.12, Flask, gunicorn |
| ML           | scikit-learn, XGBoost, LightGBM, imbalanced-learn, SHAP |
| Data / ORM   | PostgreSQL, SQLAlchemy, Flask-Migrate (Alembic) |
| Auth         | bcrypt, PyOTP (TOTP 2FA) |
| Web client   | HTML, vanilla JS |
| Mobile       | Flutter (Dart) |
| CI/CD        | GitHub Actions, Docker, GHCR |

The selected production model is **Logistic Regression** (chosen by F1 on a held-out split;
recall-prioritised threshold), kept deliberately simple and interpretable for a clinical
decision-support context.

## Getting started

### Backend (local)

```bash
cd backend
python -m venv ../.venv && source ../.venv/bin/activate
pip install -r requirements.txt

# One-shot launcher: starts PostgreSQL, creates the DB, applies migrations, runs the app
./run.sh
# → http://127.0.0.1:5000
```

Train/refresh the ML artifacts (optional — pre-trained models are committed):

```bash
python train.py
```

### Backend (Docker / production)

```bash
cd backend
docker build -t careattend-backend .
docker run -p 5000:5000 -e SECRET_KEY="$(openssl rand -hex 32)" -e FLASK_DEBUG=0 careattend-backend
```

The image runs gunicorn via `wsgi:app` as a non-root user with a `/health` healthcheck.

### Configuration

| Variable        | Purpose                                   | Default (dev) |
|-----------------|-------------------------------------------|---------------|
| `SECRET_KEY`    | Session/signing key — **set in production** | ephemeral (warns) |
| `DATABASE_URL`  | SQLAlchemy connection string              | local PostgreSQL |
| `CORS_ORIGINS`  | Comma-separated allowlist (or `*`)        | `*` |
| `FLASK_DEBUG`   | `1` enables the debugger (dev only)       | `0` |
| `RESET_DEV_CODE`| `1` returns password-reset OTPs in responses for local demos only | `0` |
| `PORT`          | Dev server port                           | `5000` |

### Flutter app

```bash
cd care_attend_app
flutter pub get
flutter run            # device/emulator
flutter build web      # release web build
```

## Deployment

Recommended prototype hosting:

- Render Blueprint for Flask + PostgreSQL: [`render.yaml`](render.yaml)
- Firebase Hosting for Flutter web: [`firebase.json`](firebase.json)
- Step-by-step runbook: [Render + Firebase deployment guide](docs/deployment_guide_render_firebase.md)

## Testing

```bash
cd backend
pytest -q              # 245 tests across 10 suites
ruff check .           # lint

cd ../care_attend_app
flutter analyze
flutter test           # 39 tests
```

Tests are forced onto a throwaway SQLite database (see
[backend/tests/conftest.py](backend/tests/conftest.py)) so they can never touch a real
PostgreSQL instance.

## CI/CD

GitHub Actions ([.github/workflows/](.github/workflows/)):

- **`ci.yml`** — backend lint (ruff) + tests + WSGI smoke + hardcoded-credential scan,
  dependency audit (pip-audit), frontend JS syntax check, Flutter analyze + test, Docker
  build, and a rendered CI summary. Runs on every push and on PRs to `master`.
- **`deploy.yml`** — builds the backend image, gates it behind a live health + smoke test,
  then publishes to **GHCR** (`ghcr.io/hritiksah15/careattend-backend`) on push to `master`.

## Documentation

In-depth project docs live in [`docs/`](docs/):

- [Architecture](docs/architecture.md) · [Model card](docs/model_card.md) ·
  [OpenAPI spec](docs/openapi.yaml) ·
  [FHIR integration architecture](docs/ehr_fhir_architecture.md)
- [Traceability matrix](docs/traceability_matrix.md) ·
  [AT3 viva evidence pack](docs/at3_viva_evidence_pack.md) ·
  [Final QA sign-off](docs/final_qa_signoff_2026-06-28.md) ·
  [Literature review sources](docs/literature_review_sources.md) ·
  [SUS testing template](docs/sus_testing_template.md) ·
  [SUS response sheet](docs/sus_responses_template.csv) ·
  [SUS results](docs/sus_results_2026-06-28.md) ·
  [Deployment guide](docs/deployment_guide_render_firebase.md)
- [DPIA/DCB0129 safety outline](docs/dpia_dcb0129_safety.md) ·
  [External validation plan](docs/external_validation_plan.md)

Contributing guidelines: [CONTRIBUTING.md](CONTRIBUTING.md) ·
Security policy: [.github/SECURITY.md](.github/SECURITY.md) ·
Changelog: [CHANGELOG.md](CHANGELOG.md)

## Project context

Built for **COM668 Computing Project**, BSc (Hons) Computing, Ulster University.
The work covers the full lifecycle: synthetic NHS-style data generation, model training and
calibration, fairness auditing, an explainable decision-support API, and multi-platform
clients — with production hardening and automated CI/CD.

## Author

**Hritik Kumar Sah** — B00923557 · Ulster University.

## License

Released under the [MIT License](LICENSE). Note: CareAttend is an academic COM668
demonstrator — **not certified or licensed for clinical, diagnostic, or commercial use**.
Its predictions must not drive real patient-care decisions. See [NOTICE](NOTICE).
