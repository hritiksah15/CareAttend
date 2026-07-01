# CareAttend Documentation Index

Use this folder as the marker-facing evidence pack for the project. The source code remains in the root application folders.

## Categories

- `assessment-evidence/` - AT2/AT3 audit notes, AT3 recording runbook, and viva evidence pack.
- `system-design/` - architecture, deployment, FHIR integration, and OpenAPI contract.
- `model-and-data/` - model card, accuracy report, and batch upload CSV examples.
- `testing-and-validation/` - feature test plan, accessibility, performance, SUS, and external validation notes.
- `governance-and-safety/` - traceability, QA sign-off, production readiness, DPIA/DCB0129, and NFR decisions.
- `project-management/` - master guide and literature sources.
- `screenshots/` - UX screenshot evidence referenced by the test plan and sign-off docs.

Local-only notes such as `docs/session-logs/`, `session-log-*.md`, supervisor
meeting briefs, and `*.screen.txt` files are ignored by Git and are not part of
the submission source zip.

## AT3 Source Zip Checklist

The COM668 handbook says AT3 requires a supported demo video plus a single source-code zip containing files you created, modified, or contributed to. Prepare a fresh zip from the current project root rather than reusing `Archive.zip`.

Include these project files and folders:

- `README.md`, `CHANGELOG.md`, `LICENSE`, `NOTICE`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`
- `.gitignore`, `.github/`, `Makefile`, `render.yaml`, `firebase.json`, `start_all.sh`
- `backend/`
- `frontend/`
- `care_attend_app/`
- `tools/`
- `docs/`

Exclude private, generated, or old submission material:

- `.git/`, `.venv/`, `node_modules/`, `.firebase/`, `.pytest_cache/`, `.ruff_cache/`
- `care_attend_app/build/`, `care_attend_app/.dart_tool/`, `care_attend_app/.idea/`
- `.env`, `backend/.secret_key`, local databases, logs, and caches
- `.codex/`, `docs/session-logs/`, `session-log-*.md`, `*.screen.txt`, and supervisor meeting briefs
- `Archive.zip`, any new `*.zip`, and video files such as `*.mp4`, `*.mov`, or `*.webm`
- `submission 2/`, module handbook/context PDFs, previous AT2 PDFs, and `.DS_Store`

For a 90%+ AT3 demonstration, make sure the video shows complete functionality, limitations, data effects, boundary/robustness examples, and a detailed code walkthrough proving ownership of the important backend, frontend, mobile, ML, testing, and safety decisions.
