# Security Policy

## Reporting a vulnerability

CareAttend is an academic project. If you find a security issue, please report it
privately rather than opening a public issue:

- **Email:** hrithiksah651@gmail.com
- Include: a description, steps to reproduce, and the affected component
  (backend API, web client, or Flutter app).

Expect an acknowledgement within a few days. Please give reasonable time to
address the issue before any public disclosure.

## Supported scope

| Component        | Path                | In scope |
|------------------|---------------------|----------|
| Backend REST API | `backend/`          | ✅ |
| Web client       | `frontend/`         | ✅ |
| Flutter app      | `care_attend_app/`  | ✅ |

## Secret handling

- No secrets are committed to the repository. Configuration is supplied via
  environment variables — see [`backend/.env.example`](../backend/.env.example).
- `detect-secrets` runs as a pre-commit hook and the CI pipeline includes a
  hardcoded-credential scan to prevent accidental secret commits.
- If a secret is ever exposed, **revoke/rotate it immediately** — removing it
  from git history does not undo exposure.

## Data & privacy

CareAttend trains on synthetic, NHS-style data only — no real patient data is
used or stored. The system is a demonstrator and must not be used for real
clinical decisions.
