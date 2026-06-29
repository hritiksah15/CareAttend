# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres
to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.1] — 2026-06-29

### Changed
- Flutter admin User Management now matches the web admin action model with
  visible icon+label actions for approval, saving role changes, viewing user
  activity, delete, and refreshing users/session logs.
- Flutter admin action buttons now use explicit contrast-safe styling so their
  icons and labels remain visible in light and dark themes.
- Admin role changes in the Flutter app now require an explicit Save Role action
  instead of applying immediately on dropdown selection.

### Added
- Flutter admin user activity panel showing login/logout and related audit
  actions for the selected account.
- Widget coverage for admin action controls, user-filtered login session logs,
  and user-linked audit activity rendering.

## [1.2.0] — 2026-06-24

### Added
- Fairness governance gate: per-attribute demographic-parity / equalised-odds
  aggregated into a PASS / ACTION_REQUIRED verdict (0.10 tolerance) with
  human-oversight actions; breaches audited (deduplicated per 24h).
- Staff approval flow: self-registered accounts start as `user` (no privileges);
  admin approves to `staff`/`admin` (`/api/admin/pending-users`, `/approve`).
  `flask create-admin` CLI seeds an admin out-of-band.
- Appointment worklist: import (1–100, EHR auto-fill, risk-scored), per-user
  clinic day list, status transitions, operational-outcomes analytics
  (anonymised attended/DNA rates by tier, actioned-vs-unactioned cohorts).
- Notification delivery lifecycle: simulated provider, dispatch endpoint with
  pending → sent / failed states (retryable, owner-scoped, audited).
- Outreach action tracking (`/api/actions` POST/GET/PATCH) with completion loop.
- Probability calibration (isotonic/sigmoid) + calibrated operating threshold;
  deployed calibrated model restores recall 0.735 / F1 0.721.
- DB persistence for assessments, notifications, appointments, feedback,
  outreach, carer proxies, audit logs (predictive feature vector stays
  session-scoped — NFR-01 honoured for patient data).
- Practice-wide dashboard + feedback summary; cross-validation evaluation
  endpoint; model comparison; mock EHR lookup; multi-trust config.
- Flutter app feature parity: dashboard, bias, batch, clinic, slots, nudge,
  ethics, profile, admin screens; dark mode; guided tour; chatbot.

### Changed
- SHAP attribution trimmed to top-3 (matches FR-03 acceptance criterion).
- `model_used` now reports the real algorithm (Logistic Regression, calibrated)
  instead of a hard-coded "Random Forest".

### Documentation
- AT2 conformance audit, NFR-01 persistence justification, traceability matrix,
  model card, OpenAPI spec, architecture (C4 + ERD), a11y + perf reports.

### Added (governance / tooling, prior)
- Repository governance: `LICENSE` (MIT + clinical disclaimer), `CONTRIBUTING.md`,
  `CODE_OF_CONDUCT.md`, `SECURITY.md`, issue/PR templates, `CHANGELOG.md`.
- Tooling: pre-commit (ruff + detect-secrets + hygiene), `.secrets.baseline`,
  `.editorconfig`, `Makefile`, `backend/pyproject.toml`, `backend/.env.example`.
- CI/CD: Dependabot, CodeQL workflow.

## [0.1.0] — 2026-06-22

### Added
- DNA (Did Not Attend) risk prediction API with calibrated probabilities.
- SHAP explainability, demographic bias monitoring, and an intervention engine.
- Authentication: bcrypt, strong-password policy, TOTP 2FA, RBAC, DB-backed
  sessions with "remember me", OTP password reset, audit logging.
- Static web client and a Flutter app (iOS/Android/web) at feature parity.
- Production backend: gunicorn WSGI entrypoint, Docker image, secure defaults.
- CI pipeline (lint, tests, WSGI smoke, credential scan, dependency audit,
  frontend syntax, Flutter analyze/test, Docker build) + GHCR publish workflow.
- 180 backend tests across 10 suites.
