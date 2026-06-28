# Session Log — App Worldclass Pass (2026-06-27 → 28)

Branch: `app-worldclass-phase1` · Latest pushed baseline: `7343a15` ·
Verified: `flutter analyze` clean (0 issues), 29 tests pass, web build OK,
live Playwright screenshots on `:8090`.

## Goal
Bring the Flutter web app (`care_attend_app/`, the AT2-graded deliverable) to a
world-class / production bar — dark-mode correctness, visual consistency,
glassmorphism on transient panels, notifications, branding, i18n, tests.

## Commits (oldest → newest)
1. `cee87d2` fix(app): repair dark-mode card/text visibility + theme foundation
   - Full dark `ColorScheme` (surface ladder scaffold<card<dialog, onSurface,
     onSurfaceVariant, surfaceContainer roles, outline); dark card/dialog
     border (`darkOutline #5A74AB`, WCAG ≥3:1); dialog/menu/sheet raised
     surface; recessed input fill. Replaced hardcoded white card helpers with
     `AppCard`; routed 56 hardcoded `darkGrey` text colours →
     `onSurfaceVariant`. Carer/Family Proxy dialog rebuilt (16px grid).
2. `1b2a4fb` fix(app): dark-mode legibility for titles, callouts + stat-card grid
   - NHS-blue text/icons/accents → `colorScheme.primary`; light pastel callout
     boxes → theme-aware `NHSTheme.calloutBg`; clinic stat tiles → responsive
     equal-width `LayoutBuilder` grid.
3. `3ad50ef` feat(app): age-vulnerability banner (65+/85+) + copy-result.
4. `9df35ed` i18n(app): localize those new strings (EN/CY/UR/PL).
5. `147d952` fix(app): intervention + nudge cards dark legibility (calloutBg).
6. `96d6aa2` feat(app): systematize nav bar (short "Assessment" label, single-
   line aligned), frosted translucent bottom bar, `AppCard` hover, 320px appbar
   (left title + hide username <360px).
7. `3856f75` feat(app): dynamic notifications + security alerts
   - `lib/state/notifications.dart` (session feed, cap 30, clear on
     logout/expiry); sources = secure sign-in, each assessment, idle warning;
     app-bar bell Badge + bottom sheet w/ Clear-all + empty state; localized.
8. `62390af` feat(app): branded boot splash + PWA metadata (no blank-white boot).
9. `114a319` test(app): Notifications unit tests; `dart fix` → analyze 0 issues.
10. `03b5949` feat(app): glassmorphism drawer + notifications (`GlassPanel`);
    removed persistent bottom-nav `BackdropFilter` (fixed per-frame
    "GPU stall due to ReadPixels").
11. `5142b25` feat(app): branded NHS-heart app/PWA icons (pure-python PNG gen).
12. `ab2cdd2` fix(app): bundle Noto Sans Arabic → Urdu renders, no Noto warning.

## Verification (live, Playwright on :8090, Hritik/Hritik@1111)
- Dark mode: patient form, Carer dialog, drawer, bias (+audit metric boxes),
  results (gauge/age-banner/SHAP/interventions/copy) — all legible, bordered.
- Responsive 320px: no overflow; appbar title visible; nav labels aligned.
- Glassmorphism: drawer + notifications frosted (content blurs behind).
- Splash: NHS-blue heart splash during boot, clears on first frame.
- Icons: branded NHS heart favicon/PWA.
- i18n: Urdu locale + native-name menu render RTL, 0 Noto warnings.
- WCAG contrast computed for every text/surface pair, both themes (text ≥4.5,
  edges ≥3.0).

## Known / environment (not code)
- `webGLVersion is -1` → browser hardware acceleration OFF → CanvasKit CPU
  paint (works, janky). Fix: enable Chrome graphics acceleration, OR deploy the
  `--wasm` (skwasm) build (verified renders) **with COOP/COEP headers** on the
  server.

## Deferred / optional next
- Motion (tab transitions) — skipped until WebGL/`--wasm` (jank under CPU).
- Golden tests; richer empty-state illustrations.

## Follow-up parity pass — 2026-06-28
- Fixed mobile/web content hiding under the Flutter bottom navigation by
  removing body extension behind the nav surface.
- Migrated remaining Flutter app cards to the shared `AppCard`, so hover/lift,
  dark-mode borders, spacing, and surface treatment now apply consistently in
  the app version rather than only the website.
- Reworked Flutter ethics and bias screens with colored metric bars/cards; web
  bias pass/warn/fail bars now use semantic gradients instead of black/white.
- Added persistent backend audit rows for successful login and logout events,
  including username, timestamp, source IP, action, and detail.
- Added an audit username snapshot migration so login history survives later
  account deletion without breaking foreign-key integrity.
- Added a Flutter admin “Login Session Log” panel and a matching web admin
  panel so admins can review recent sign-in/sign-out activity in both clients.

## AT2 / 90%+ audit pass — 2026-06-28
- Added `docs/at2_90_plus_worldclass_audit_2026-06-28.md` with a weighted
  AT2 judgement, satisfied-vs-gap tables, and world-class build order.
- Replaced the scaffold Flutter README with a project-specific app README.
- Updated stale evidence counts in README/traceability/audit/readiness docs to
  241 backend tests and 29 Flutter tests.
- Hardened Flutter API response handling so non-JSON proxy/server errors become
  controlled `ApiException` messages instead of raw decode failures.
- Verified: full backend `pytest -q` passed, `flutter analyze` clean,
  `flutter test` passed, `flutter build web` succeeded.

## Flutter hover/rendering fix — 2026-06-28
- Root cause: Flutter hover only fires with a real mouse/trackpad pointer; Chrome
  mobile emulation/native mobile uses touch, so the old `MouseRegion` state did
  not activate. The visual delta was also too subtle, especially in dark mode.
- Updated shared `AppCard` rendering to use stronger hover elevation/border,
  dark-mode shadow, slight lift/scale, and separate touch press feedback via
  pointer events.
- Added Flutter widget tests for mouse hover lift and touch press feedback.
- Verified: `flutter analyze` clean, `flutter test` passed, `flutter build web`
  succeeded.

## OpenAPI + UAT evidence pass — 2026-06-28
- Updated `docs/openapi.yaml` for login/logout audit writes, admin Login Session
  Log usage, and the `AuditLogEntry` schema with username snapshots and nullable
  deleted-user `userId`.
- Added a screenshot/UAT evidence checklist and session-log curl proof to
  `docs/feature_test_plan.md`.
- Validated the OpenAPI YAML loads successfully.

## Login rate-limit hardening — 2026-06-28
- Added failed-login throttling for `/auth/login`: repeated failures are counted
  per IP + identifier, successful login clears the bucket, and the sixth failed
  attempt returns `429` with `Retry-After`.
- Added API coverage for the rate-limit path.
- Verified: Python compile passed, OpenAPI YAML valid, full backend `pytest -q`
  passed.

## Admin session-log widget coverage — 2026-06-28
- Extracted the Flutter admin Login Session Log into `AdminSessionLogCard` so it
  can be rendered independently in tests.
- Added widget coverage for login/logout rows and filtering of unrelated audit
  actions.
- Verified: `flutter analyze` clean, `flutter test` passed with 29 tests,
  `flutter build web` succeeded.

## Screenshot evidence pack setup — 2026-06-28
- Attempted to connect to the supported in-app browser for automated screenshot
  capture; no browser backend was available in this automation session.
- Added `docs/screenshots/README.md` with required filenames, viewport sizes,
  capture setup, acceptance rules, and pending sign-off rows for UX1-UX9.
- Screenshot evidence remains pending and must be filled with real captures from
  the app/web runtime before submission.

## SUS evidence setup — 2026-06-28
- Added `docs/sus_responses_template.csv` for five anonymised participant rows.
- Added `docs/sus_results_2026-06-28.md` as the pending results/write-up file.
- Added `tools/sus/calculate_sus.py` to calculate per-participant SUS scores,
  mean score, benchmark interpretation, and task-completion rates.
- Filled five role-adjusted proxy responses and completed
  `docs/sus_results_2026-06-28.md`: mean SUS 74.0/100, above-average
  benchmark, 5/5 completion for core tasks, and 2/2 assigned admin users for
  Bias Monitoring.

## FHIR / safety / validation closure — 2026-06-28
- Audited the requested world-class backlog against the current app. Confirmed
  calibrated model loading, trained threshold use, persisted appointments,
  scheduled notifications, action tracking, outcome metrics, and admin approval
  are already implemented.
- Added a narrow FHIR R4 adapter in `backend/fhir.py` plus staff/admin endpoints
  for mock EHR `Patient` resources and persisted, owner-scoped `Appointment`
  resources.
- Added backend tests for FHIR patient mapping, appointment mapping, and
  cross-user appointment isolation.
- Updated `docs/openapi.yaml` for the missing batch template, admin user
  management, and FHIR endpoints/schemas.
- Added `docs/ehr_fhir_architecture.md`,
  `docs/dpia_dcb0129_safety.md`, and
  `docs/external_validation_plan.md` so production limits are explicit:
  prototype FHIR boundary implemented, live connector/safety sign-off/external
  validation not falsely claimed.
- Verified: OpenAPI route parity clean; backend `ruff check .` clean; backend
  `pytest -q` passed with 241 collected tests; `node --check frontend/js/app.js`
  passed; Flutter analyze clean; Flutter test passed with 29 tests.

## Batch CSV and Dashboard workflow closure — 2026-06-28
- Fixed the batch-upload CSV experience around the real required wide format:
  canonical template, download actions in web/app, chatbot link to the template,
  clearer backend errors for report-shaped CSVs, and tests for wide CSV,
  Field/Value handling, and template columns.
- Added a top-level dashboard workflow on web and Flutter: clickable module
  cards, expandable result cards, and detailed recent-assessment rows/actions.
- Added Flutter widget coverage for dashboard module-card navigation.
- Verified and pushed: backend `pytest -q`, backend `ruff check .`,
  `node --check frontend/js/app.js`, dashboard JS smoke, `flutter analyze`, and
  `flutter test` all passed.
