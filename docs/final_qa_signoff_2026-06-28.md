# Final QA Sign-Off Snapshot

Date: 2026-06-28
Branch: `app-worldclass-phase1`
Latest pushed commit checked: `7343a15 Add dashboard workflow cards`

## Executive Status

CareAttend is in a stable, defensible state for AT3 recording and final report
evidence. Backend, web JavaScript, Flutter analysis, Flutter tests, batch CSV
handling, and dashboard workflow checks are green. The main remaining evidence
gap is visual proof: real screenshots/video must still be captured from the
running web and Flutter apps because the in-app browser backend was unavailable
in this automation session.

## Automated Verification

| Area | Command / check | Result |
|---|---|---|
| Backend lint | `ruff check .` in `backend/` | Passed |
| Backend tests | `pytest -q` in `backend/` | Passed; only existing sklearn deprecation warnings |
| Backend collection | `pytest --collect-only -q` | 241 tests collected across 10 files |
| Web syntax | `node --check frontend/js/app.js` | Passed |
| Web dashboard smoke | Direct JS runtime smoke against dashboard DOM stubs | Passed: module cards, batch module, expandable detail row, row toggle, outcomes, icon refresh |
| Flutter static analysis | `flutter analyze --no-fatal-infos` | No issues |
| Flutter tests | `flutter test` | Passed; 29 tests |
| Git state before docs pass | `git status --short --branch` | Clean after pushing `7343a15` |

## Current Automated Test Counts

Backend pytest collection:

| Test file | Count |
|---|---:|
| `tests/test_api.py` | 18 |
| `tests/test_auth.py` | 27 |
| `tests/test_bias_monitor.py` | 13 |
| `tests/test_calibration.py` | 5 |
| `tests/test_data_generator.py` | 23 |
| `tests/test_feature_coverage.py` | 50 |
| `tests/test_interventions.py` | 10 |
| `tests/test_new_endpoints.py` | 78 |
| `tests/test_predictor.py` | 12 |
| `tests/test_robustness.py` | 5 |
| **Total** | **241** |

Flutter test coverage count: 29 tests across logic, widgets, accessibility,
dashboard module cards, batch template button, notifications, app boot, and
admin session-log widgets.

## Feature Sign-Off

| Area | Status | Evidence |
|---|---|---|
| Single assessment | Pass | `/api/predict`, calibrated model, SHAP top factors, interventions, result export controls. |
| Batch CSV | Pass | Template endpoint, web/app template buttons, required-column tests, wide CSV happy path, Field/Value report handling/rejection message. |
| Dashboard workflow | Pass | Web module cards + expandable result cards + clickable recent detail rows; Flutter module-card grid + expandable cards; widget test added. |
| Clinic/outcomes workflow | Pass | Appointment records, action tracking, status updates, operational outcomes aggregation. |
| Auth/RBAC | Pass | Opaque sessions, role gates, admin approval, 2FA, rate limiting, audit logs. |
| Governance | Pass | Bias monitor, trained threshold use, ethics framework, audit trail. |
| Accessibility/usability | Pass with evidence caveat | WCAG/a11y and SUS docs exist; final screenshot proof still pending. |
| Documentation | Pass with final proofreading caveat | Architecture, OpenAPI, traceability, model card, safety/FHIR/external validation docs, AT2 and AT3 evidence packs. |

## Known Limitations

| Limitation | Why it is acceptable for AT3 | Required wording |
|---|---|---|
| No real NHS data validation | Real data requires data-sharing approval and ethics/IG governance. | "Metrics validate the synthetic-data prototype and pipeline, not clinical effectiveness." |
| No live EHR connector | EMIS/SystmOne/Spine integration needs contracts, security review, and deployment approvals. | "FHIR adapter is a prototype boundary, not a live NHS connector." |
| DPIA/DCB0129 are not signed | Academic prototype can outline safety governance but cannot sign deployment approval. | "Safety documents are production-readiness outlines." |
| Browser screenshots not captured in this session | In-app browser backend unavailable; source and tests still verified. | "Screenshots must be captured manually before final submission." |
| Some frontend flows are UAT-evidence rather than unit-tested | Export/print and visual layout are best verified with screenshots/video. | "Use the feature test plan and screenshot manifest for final proof." |

## Manual QA Still Required Before Recording

Use `docs/feature_test_plan.md` and `docs/screenshots/README.md`.

Minimum manual pass:

| ID | Required recording/screenshot proof |
|---|---|
| M1 | Staff/admin login shows role-appropriate dashboard, clinic, batch, and admin/bias tabs. |
| M2 | Single assessment produces result, SHAP, interventions, and export row. |
| M3 | Batch upload uses the downloaded wide CSV template and returns a result CSV. |
| M4 | Wrong Field/Value report CSV shows the targeted actionable message. |
| M5 | Dashboard top module cards navigate correctly. |
| M6 | Dashboard recent assessment row expands to detailed record/actions. |
| M7 | Clinic action/status updates feed the operational outcomes dashboard. |
| M8 | Admin approval/session-log rows render in web and Flutter. |
| M9 | Bias/ethics screens are readable in light/dark mode. |
| M10 | Mobile width does not hide content behind the bottom nav. |

## Final Go/No-Go

| Gate | Status |
|---|---|
| Code builds/tests | Go |
| AT3 technical story | Go |
| Rubric alignment | Go |
| Screenshot evidence | No-go until captured manually |
| Clinical deployment claim | No-go; must remain prototype-only |

Final recommendation: record AT3 after manually capturing the screenshot/video
evidence. The codebase itself is ready; the remaining risk is presentation and
evidence, not core implementation.
