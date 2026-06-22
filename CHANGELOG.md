# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres
to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
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
