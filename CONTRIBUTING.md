# Contributing to CareAttend

Thanks for your interest. CareAttend is an academic COM668 project; contributions
and review feedback are welcome.

## Project layout

| Path                | What |
|---------------------|------|
| `backend/`          | Flask REST API + ML pipeline (Python 3.12) |
| `frontend/`         | Static HTML/JS web client |
| `care_attend_app/`  | Flutter app (iOS / Android / web) |
| `docs/`             | Architecture, model card, OpenAPI, traceability |

## Local setup

```bash
# Backend
cd backend
python -m venv ../.venv && source ../.venv/bin/activate
pip install -r requirements.txt
cp .env.example .env          # then edit values
./run.sh                       # starts DB + API on :5000

# Flutter app
cd care_attend_app
flutter pub get
flutter run
```

## Before you push

```bash
# from repo root
pre-commit install             # one-time
pre-commit run --all-files     # ruff + detect-secrets + hygiene

# backend checks
cd backend && ruff check . && pytest -q     # 180 tests

# app check
cd care_attend_app && flutter analyze --no-fatal-infos && flutter test
```

Or use the Makefile: `make precommit`, `make lint`, `make test`.

## Conventions

- **Branches:** `feat/...`, `fix/...`, `chore/...`, `docs/...`.
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/) —
  e.g. `feat(backend): add slot optimisation endpoint`.
- **PRs:** open against `master`; fill in the PR template; CI must be green.
- **Never commit secrets.** Config goes in `.env` (gitignored); see `backend/.env.example`.

## Tests & CI

Every push runs lint, tests, a credential scan, dependency audit, frontend syntax
check, Flutter analyze/test, a Docker build, and CodeQL. Keep them green.
