# CareAttend — NHS Predictive Risk Assessment for Missed Appointments

[![CI](https://github.com/hritiksah15/CareAttend/actions/workflows/ci.yml/badge.svg)](https://github.com/hritiksah15/CareAttend/actions/workflows/ci.yml)
[![Python](https://img.shields.io/badge/python-3.12-blue.svg)](https://www.python.org/)
[![Flutter](https://img.shields.io/badge/flutter-stable-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/license-Academic-lightgrey.svg)](#license)

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
- **Bias monitoring** — fairness audit across age, gender, deprivation (IMD), and disability.
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
- **Flutter app** ([care_attend_app/](care_attend_app/)) — 13 screens at parity with the web client.

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
| `PORT`          | Dev server port                           | `5000` |

### Flutter app

```bash
cd care_attend_app
flutter pub get
flutter run            # device/emulator
flutter build web      # release web build
```

## Testing

```bash
cd backend
pytest -q              # 180 tests across 10 suites
ruff check .           # lint
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

## Project context

Built for **COM668 Computing Project**, BSc (Hons) Computing, Ulster University.
The work covers the full lifecycle: synthetic NHS-style data generation, model training and
calibration, fairness auditing, an explainable decision-support API, and multi-platform
clients — with production hardening and automated CI/CD.

## Author

**Hritik Kumar Sah** — B00923557 · Ulster University.

## License

Academic project for COM668. Not licensed for clinical or commercial use.
