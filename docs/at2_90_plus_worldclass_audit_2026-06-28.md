# CareAttend AT2 / 90%+ World-Class Audit

Audit date: 2026-06-28
Scope: backend, web frontend, Flutter app, local documentation, automated tests.
Rubric source: local `docs/CareAttend_Master_Guide.md` AT2 matrix because it
captures the module-handbook weighting used in this workspace.

## Executive Verdict

CareAttend is now a strong distinction-level academic prototype. The codebase
implements the AT2 fundamentals and goes far beyond them: calibrated DNA risk
prediction, SHAP explanations, fairness governance, RBAC, 2FA, audit logs,
operational workflow, Flutter app, web client, CI/CD evidence, and extensive
tests.

Current realistic mark position:

| Area | Weight | Current evidence judgement | Likely band |
|---|---:|---|---:|
| Problem Definition | 20% | Clear aim, bounded NHS/GDPR scope, SMART-style implementation evidence. Needs final quantified problem-impact paragraph in the submitted report. | 17-18/20 |
| Context Investigation | 20% | Strong health-AI/fairness/context docs and competitor positioning. Needs synthesis phrasing and final source alignment. | 16-17/20 |
| Software Definition | 40% | Strongest area: implemented FR/NFRs, RTM, C4/ERD docs, OpenAPI, app/web/backend, 234 backend tests, 26 Flutter tests. | 37-39/40 |
| Planning | 15% | Sprint/session logs, risk framing, evidence of fix-and-verify loops. Needs final deviation/reflection log in report prose. | 12-14/15 |
| Communication | 5% | README, model card, architecture, traceability, production review. Needs final proofread, captions, Harvard consistency. | 4/5 |

Estimated current defensible range: 86-92 depending on final report quality.
Estimated 90%+ path: achievable if the remaining evidence gaps below are closed
and the dissertation/demo language avoids overclaiming real-world clinical
validity.

## What Fully Satisfies AT2 / Handbook Criteria

| Criterion | Satisfied evidence |
|---|---|
| Clear healthcare problem | NHS missed-appointment / DNA problem is specific, bounded, and operationally meaningful. |
| Scope control | Real NHS integration and real patient data are explicitly out of scope; mock EHR and synthetic data are labelled. |
| Functional requirements | Core FRs implemented: assessment, risk score, traffic-light tier, SHAP, interventions, bias audit, batch, session trajectory, auth/RBAC. |
| Non-functional requirements | Privacy-minimised prediction path, performance benchmark, WCAG/a11y evidence, model quality threshold, documentation, security. |
| Traceability | `docs/traceability_matrix.md` links FR/NFR/features to implementation and tests. |
| Architecture | `docs/architecture.md`, backend models, migrations, route structure, OpenAPI, Docker/CI evidence. |
| ML credibility for academic scope | Calibrated model, threshold persistence, SHAP background, bias monitoring, model card, calibration tests. |
| Ethics and governance | NHSX-style ethics framework, bias dashboard, fairness governance gate, human oversight wording. |
| Security | bcrypt, strong-password policy, TOTP, opaque DB-backed sessions, RBAC, admin approval flow, audit log, self-lockout protections. |
| Operational value | Clinic list, appointment status, notifications, delivery lifecycle, outreach actions, outcomes dashboard, slots, patient nudges. |
| App/web parity | Flutter app now includes styled AppCard surfaces, bottom-nav overlap fix, colorful ethics/bias views, admin session log. Web admin also has session log. |
| Testing evidence | Backend suite collected 234 tests and passed; Flutter analyze is clean; Flutter test passes 26 tests; JS syntax and Python compile checks pass. |
| Professional communication | Root README, app README, architecture, model card, production-readiness review, session logs, feature plan, SUS template. |

## Current Weaknesses That Could Lose Marks

| Risk | Why it matters | Required action |
|---|---|---|
| Synthetic-data overclaiming | Biggest academic risk. Metrics fit the generator, not real NHS populations. | In report/demo, state metrics are synthetic-fit only and real-world validation is out of scope. Use the paragraph in `docs/production-readiness-review.md`. |
| Human usability evidence now documented | WCAG automation is strong, and the 5-person role-adjusted SUS study adds human usability evidence. | Reference `docs/sus_results_2026-06-28.md`: mean SUS 74.0/100 with three reported findings. |
| UAT evidence for export/admin/session-log | Some frontend features are verified by build/tests but not human scenario evidence. | Capture a short scenario table: login, admin session log, assessment, result export, bias/ethics, mobile nav. |
| Requirement wording drift | Older docs had stale counts and old NFR-01 wording. Some FR numbering differs between report/table. | Before submission, align exact FR/NFR wording in the report and RTM. Keep 234 backend tests / 26 Flutter tests consistent. |
| App visual evidence missing from report | The app has been fixed, but markers cannot infer that from code. | Include screenshots of app home, results, admin session log, ethics/bias color, mobile bottom-nav spacing. |
| Production hardening not complete | External pentest, DPIA/DCB0129, FHIR connectors are not expected for AT2 but matter for "real NHS product". | Frame as future work, not missing AT2 scope. |

## App Version Audit

| Area | Status | Notes |
|---|---|---|
| Hover style | Satisfied on desktop/web pointer surfaces through `AppCard` `MouseRegion`. Not expected on Chrome mobile emulation/touch; touch devices do not produce hover. |
| Bottom navigation hiding content | Fixed in Flutter by removing body extension behind the nav surface. |
| Chatbot/results/cards hiding under nav | Fixed by the same bottom-nav layout correction. Needs screenshot evidence. |
| Ethics graph/color | Fixed in Flutter with semantic metric bars/cards; web bias bars now use semantic gradients. |
| Card style parity | All remaining Flutter `Card(` usages under `care_attend_app/lib` were migrated to `AppCard`. |
| Admin session logs | Implemented in backend, Flutter admin screen, and web admin screen. Login/logout now persist to audit logs. |
| Localization | Session-log labels added to EN/CY/PL/UR and generated localizations updated. |
| Build health | `flutter analyze` clean and `flutter test` passing after latest changes. |

## Backend / Data / Security Audit

| Area | Status | Notes |
|---|---|---|
| Login session persistence | Satisfied. `login_success` and `logout` audit rows are written. |
| Audit deletion integrity | Satisfied. `username_snapshot` migration preserves history if an account is deleted. |
| Auth model | Strong. Opaque DB sessions, 2FA, remember-me, password reset, RBAC. |
| Admin safety | Strong. Self-demotion and self-delete blocked; approval flow implemented. |
| Privacy | Defensible. Raw prediction feature vectors are not persisted; operational IDs/contact fields are persisted and must be framed as justified operational additions. |
| Input validation | Strong on main endpoints; robustness tests cover JSON errors. |
| Failed-login throttling | Satisfied. Repeated failed `/auth/login` attempts return `429` with `Retry-After`. |
| Remaining scalability gap | `validate_token` writes session activity frequently; acceptable prototype, throttle for production. |

## Web Version Audit

| Area | Status | Notes |
|---|---|---|
| Admin parity | Improved. Admin panel now refreshes users plus login session logs. |
| Bias colors | Improved. Pass/warn/fail bars now use color gradients. |
| JS syntax | Verified with `node --check frontend/js/app.js`. |
| Accessibility | Existing `docs/a11y_report.md` reports automated WCAG scan evidence. |
| Remaining web evidence | Need browser screenshot/video pass of admin session log, bias, ethics, results export. |

## World-Class Left-To-Build List

Priority 0: do before submission/demo.

| # | Work | Why it matters | Done when |
|---:|---|---|---|
| 1 | SUS mini-study with 5 users | Converts usability from "claimed" to evidenced. | Complete: `docs/sus_results_2026-06-28.md` records 5 role-adjusted participants, mean SUS 74.0/100, task completion, findings, and product responses. |
| 2 | Screenshot/video evidence pack | Proves app version is fixed and styled, not just web. | `docs/screenshots/` manifest now exists; real app/web captures still pending. |
| 3 | Report wording alignment | Prevents marker confusion and lost communication marks. | FR/NFR IDs, test counts, NFR-01, synthetic-data limitation all match docs/code. |
| 4 | UAT scenario table | Covers frontend-only flows not fully captured by unit tests. | Pass/fail table for login, assessment, export, admin logs, bias, ethics, mobile layout. |
| 5 | App README/report screenshots | Removes remaining "student scaffold" smell and shows product maturity. | App screenshots exist and are captioned. |

Priority 1: improves robustness but not required for AT2.

| # | Work | Why it matters | Done when |
|---:|---|---|---|
| 7 | Session write throttling | Reduces DB write amplification. | `last_activity` only persists when stale by configured interval. |
| 8 | Visual regression/golden tests | Protects world-class styling. | Golden tests for app cards/results/admin or Playwright snapshots for web. |

Priority 2: real NHS product path, outside AT2.

| # | Work | Why it matters |
|---:|---|---|
| 11 | DPIA and DCB0129 clinical safety case | Required before real clinical deployment. |
| 12 | FHIR R4 / EMIS / SystmOne / Spine connectors | Required for interoperability. |
| 13 | External validation on real NHS data | Required before claiming real-world model performance. |
| 14 | Pen test and DSPT evidence | Required for NHS security assurance. |
| 15 | Pilot/A-B study measuring DNA reduction | Required to prove impact beyond technical correctness. |

## Final 90%+ Judgement

The software is strong enough for a 90%+ narrative if the submission is honest
and evidence-led. The strongest marking argument is:

CareAttend does not just predict DNA risk. It implements a calibrated,
explainable, fairness-audited, role-secured, multi-surface clinical decision
support workflow with operational follow-through and traceable automated tests.
Its limitation is not missing engineering; it is that model performance is
demonstrated on synthetic data, so real-world clinical performance remains
future work.

Use that exact framing. Do not claim the model is clinically validated. Claim the
system design, governance, explainability, accessibility, and engineering
discipline are distinction-level.

## Verification Snapshot

Commands run during this pass:

| Check | Result |
|---|---|
| `pytest --collect-only -q` | 234 backend tests collected |
| `pytest -q` | Full backend suite completed successfully |
| `python -m py_compile backend/...` | Passed |
| `node --check frontend/js/app.js` | Passed |
| `flutter analyze` | No issues |
| `flutter test` | 26 tests passed |
| `flutter build web` | Succeeded; existing Cupertino icon font warning remains non-blocking |

OpenAPI refresh completed after this audit: `docs/openapi.yaml` now documents
login/logout audit writes, `AuditLogEntry.username`, nullable deleted-user
`userId`, and admin session-log usage.
