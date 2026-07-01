# Session Log — Final Submission Readiness

Date: 2026-06-29
**Superseded baseline note (2026-07-01):** use `master` at `5c9f741` for final
GitHub/source-zip/demo evidence. Older `app-worldclass-phase1` references below
are historical session context only.

Branch: `app-worldclass-phase1`
Latest pushed baseline at start of this log: `e4d69c1 Add AT3 QA evidence pack`

## Purpose

Preserve the final handover state for the CareAttend submission: what was
finished, what is already pushed, what should be committed, what should stay out
of Git/source zips, and what remains before AT3 recording.

## Current Repository State

- Branch is clean and synced with `origin/app-worldclass-phase1`.
- Latest pushed commits:
  - `e4d69c1` — AT3/QA evidence pack.
  - `7343a15` — dashboard workflow cards.
  - `73184cf` — completed-build evidence alignment.
  - `8c8515d` — FHIR boundary and safety evidence.
  - `a4a7549` — role-aware SUS evidence and access polish.
  - `d2ac4a5` — batch-compatible patient CSV uploads.
  - `01ae844` — batch upload CSV template workflow.

## Completed Work Saved in Repo

### Batch CSV

- Real batch template endpoint and `docs/sample_batch_upload.csv`.
- Web and Flutter "Download template CSV" actions.
- Chatbot link wired to real template download.
- Backend now gives actionable errors for wrong CSV shape.
- Field/Value report handling was finished rather than left half-written:
  single-patient report inputs can be converted when enough patient fields are
  present; report-only exports are rejected with a clear message.
- Tests cover wide CSV, Field/Value handling/rejection, template columns, and
  wrong-column messages.

### Dashboard Workflow

- Web dashboard now follows:
  dashboard module cards -> expandable result cards -> clickable detail rows.
- Flutter dashboard now has top-level module cards, expandable result cards,
  detail rows/actions, and dashboard module-card widget coverage.
- Dashboard workflow commit was pushed as `7343a15`.

### Evidence and Rubric Pack

- `docs/at3_viva_evidence_pack.md`:
  - AT3 rubric matrix.
  - 15-minute demo script.
  - code walkthrough route.
  - answers for technical, soft-skill, and entrepreneurial questions.
- `docs/final_qa_signoff_2026-06-28.md`:
  - current verification snapshot.
  - 246 backend test count.
  - 39 Flutter test count.
  - remaining evidence limits.
- `docs/screenshots/README.md`:
  - required screenshot names and acceptance rules.
  - now includes dashboard workflow and batch-template captures.
- `docs/feature_test_plan.md`:
  - now includes batch-template/wrong-report CSV scenarios.
  - now includes dashboard module/detail workflow scenario.

### FR-09 Risk Trajectory Closure

- Web risk history now records through `recordRiskHistory()` and keeps only the
  most recent five session assessments.
- Flutter risk history now records through `ApiService.recordRiskHistory()` and
  keeps only the most recent five session assessments.
- Flutter logic coverage verifies that seven recorded assessments are trimmed to
  the newest five.

### Flutter Admin User Management

- Flutter admin User Management now mirrors the web action model with approve,
  save-role, activity, delete, and refresh icon+label actions.
- Selecting a user exposes their login/logout and related audit activity, and
  the Login Session Log filters to that selected user.
- Flutter app package version bumped to `1.2.1+4`.

## Verification Snapshot

Most recent clean checks recorded in the docs pass:

- Backend `ruff check .` passed.
- Backend `pytest -q` passed with only existing sklearn deprecation warnings.
- Backend `pytest --collect-only -q` collected 246 tests.
- Web `node --check frontend/js/app.js` passed.
- Dashboard JavaScript smoke test passed.
- Flutter `flutter analyze --no-fatal-infos` passed.
- Flutter `flutter test` passed with 39 tests.
- Evidence-doc hygiene checks passed:
  - no stale old Flutter test-count references.
  - no tool-name attribution in docs.
  - `git diff --check` passed before the evidence commit.

## Files That Should Be Committed / Included

Include these in GitHub and final source zip:

- root project docs/config: `README.md`, `CHANGELOG.md`, `LICENSE`, `Makefile`,
  `start_all.sh`, `.github/`, `.pre-commit-config.yaml`, `.secrets.baseline`.
- `backend/` source, tests, migrations, model artefacts required by runtime,
  requirements and config.
- `frontend/` CSS, JS, templates, and vendored browser libraries.
- `care_attend_app/lib/`, `care_attend_app/test/`, `care_attend_app/assets/`,
  `care_attend_app/web/`, `pubspec.yaml`, `pubspec.lock`, and platform source.
- `docs/` evidence files, sample CSVs, OpenAPI, model card, architecture,
  screenshots once captured.
- `tools/` scripts, not installed dependencies.

## Files That Should Stay Out of Git / Zip

Exclude these:

- `.env`
- `.venv/`
- `.DS_Store`
- `Archive.zip`
- `submission 2/`
- `__pycache__/`, `*.pyc`
- `.pytest_cache/`, `.ruff_cache/`
- `*.db`, `*.sqlite`, `*.sqlite3`
- `data/`
- `care_attend_app/build/`
- `care_attend_app/.dart_tool/`
- `care_attend_app/.pub-cache/`, `care_attend_app/.pub/`
- `care_attend_app/coverage/`
- `tools/a11y/node_modules/`
- temporary exports, demo videos, and local generated archives.

## Already-Tracked Files To Consider Cleaning Before Final Zip

These are currently tracked but are local/generated Flutter files containing
machine-specific paths. For a cleaner final source package, remove them from
version control and ignore them:

- `care_attend_app/android/local.properties`
- `care_attend_app/ios/Flutter/Generated.xcconfig`
- `care_attend_app/ios/Flutter/flutter_export_environment.sh`
- `care_attend_app/ios/Flutter/ephemeral/`

Suggested ignore additions:

```gitignore
.pytest_cache/
.ruff_cache/
.coverage
htmlcov/
*.sqlite
*.sqlite3
*.log

care_attend_app/android/local.properties
care_attend_app/ios/Flutter/Generated.xcconfig
care_attend_app/ios/Flutter/flutter_export_environment.sh
care_attend_app/ios/Flutter/ephemeral/
care_attend_app/.flutter-plugins
care_attend_app/.flutter-plugins-dependencies

node_modules/
frontend/node_modules/
tools/a11y/node_modules/

*.zip
*.mp4
*.mov
```

## Final Source Zip Command

After any final cleanup commit, create the source zip from Git so ignored local
files are not included:

```bash
git archive --format=zip --output CareAttend-source.zip master
```

## Remaining Manual Task Before AT3

Capture real screenshots/video from the running app and web client:

- Follow `docs/screenshots/README.md`.
- Required new evidence includes dashboard workflow and batch-template upload.
- Do not claim screenshot evidence is complete until the actual image files are
  placed under `docs/screenshots/`.

## Handover Verdict

The codebase and evidence docs are ready for AT3 preparation. The only hard
remaining gap is visual proof from the executable app/web UI. For final
submission, avoid claiming real clinical validation; frame CareAttend as an
academic prototype with strong engineering, explainability, governance, and
traceable QA evidence.
