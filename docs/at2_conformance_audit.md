# AT2 Conformance Audit — CareAttend

Audit date: 2026-06-24. Source of truth: `submission 2/submission/AT2 -Sah_Hritik_B00923557(1).pdf`.
Verified against backend (`backend/`), Flutter app (`care_attend_app/`), web frontend (`frontend/`), docs.

## Method
- Read full AT2 report (49pp): reqs, RTM (App B), MoSCoW (App A), testing methodology, plan.
- Backend: 241 pytest tests run → **all pass**.
- Models inspected directly: base = LogisticRegression, calibrated = CalibratedClassifierCV.
- Perf + a11y: read actual result numbers, not just file presence.
- Flutter: `flutter analyze` → **no issues**; `flutter test` → **30 tests pass, including AppCard hover/press, admin session-log rendering, batch template, risk-history cap, and dashboard module-card coverage**. Toolchain at `~/development/flutter`. Full browser E2E not run (optional: `flutter run -d chrome`).

## Functional Requirements (by feature, IDs vary between Table 3.3 and MoSCoW p41)

| Feature | AT2 ID | Status | Evidence |
|---|---|---|---|
| Patient input form (validated) | FR-01 | ✅ | `patient_form_screen.dart`, `_validate_patient` app.py:292 |
| DNA risk probability score | FR-02 | ✅ | `/api/predict` returns probability+percentage; predictor.py |
| Traffic-light risk tier | FR-03 | ✅ | risk_tier Low/Med/High in predict response |
| SHAP top-3 attribution | FR-04 | ✅ | shap_values in predict response; SHAP in predictor |
| Contextual interventions | FR-05 | ✅ | `generate_interventions` ml/interventions.py |
| Age-sensitive tiers 18-64/65-74/75-84/85+ | FR-06 | ✅ | `derive_age_group`, interventions.py:66-70 (85+ + High≥75 escalation) |
| Bias dashboard (parity + equalised odds) | FR-07 | ✅ | `/api/bias-audit`, bias_monitor.py:152-158 |
| Batch CSV ≤100 records | FR-08 | ✅ | `/api/batch` app.py:332, 100-row cap, CSV out |
| Risk trajectory line chart (session last five) | FR-09 | ✅ | Web `recordRiskHistory` and Flutter `ApiService.recordRiskHistory` cap to five; `_RiskHistoryChart` renders a line chart |

## Non-Functional Requirements

| NFR | Requirement | Status | Evidence |
|---|---|---|---|
| NFR-01 | Session-scoped, NO persistence (GDPR Art 5(1)(c)) | ⚠️ DRIFT | See below |
| NFR-02 | API ≤2s p95 | ✅ | perf_benchmark.md: /predict p95 ≈1.35ms |
| NFR-03 | WCAG 2.1 AA | ✅ EXCEEDS | a11y_report.md: 0 violations at WCAG 2.2 AA |
| NFR-04 | F1≥0.72, Recall≥0.70 | ✅ | model_card: F1 0.721, Recall 0.735 |
| NFR-05 | Documented for extension | ✅ | docstrings, README, openapi.yaml, model_card |
| NFR-06 | bcrypt, no plaintext, session expiry | ✅ | `auth.py` bcrypt + opaque DB-backed sessions |

### NFR-01 drift (highest-stakes finding)
AT2 §3.3.2 + ERD + both DFDs + NFR-01 describe a **DB-less, session-scoped** design,
called a load-bearing GDPR constraint. Actual code has **10 Alembic migrations + a real DB**.
- Patient *demographics* (Age/Gender/IMD feature vector) are NOT persisted on the predict path — only `AssessmentSummary` (prob/tier/age_group). Defensible.
- BUT the DB persists UserAccount, appointments, assessment summaries, notifications, feedback, outreach actions, audit logs.
- `/api/ehr/lookup` is an explicit **mock** (EHR_MOCK_PATIENTS), labelled out-of-scope per AT2 §1.3. `synthetic_dataset.csv` is synthetic training data, not real patients.
Verdict: predictive feature vector (Age/Gender/IMD/comorbidities) is NOT persisted by any
route — `AssessmentSummary` stores `age: "Not stored"` (models.py:275). BUT `carer_proxies`
persists carer name+contact+patient identifier (real PII), and appointments/notifications/
outreach persist a `patient_id` label + dates. **Resolved via Option A** — see
`docs/nfr01_persistence_justification.md` for the full table + AT4 re-framing narrative.

## Resolved defects / remaining polish

1. **[RESOLVED] NFR-01 architecture vs report mismatch.** Persistence is documented as a justified AT4 evolution in `docs/nfr01_persistence_justification.md`; raw prediction feature vectors are still not persisted on the predict path.
2. **[RESOLVED] Model mislabel bug.** Live prediction now reports Logistic Regression / calibrated model evidence consistently.
3. **[RESOLVED] Flutter app runtime.** `flutter analyze` 0 errors; `flutter test` passes (boots to login). Toolchain `~/development/flutter`. Optional: on-camera `flutter run -d chrome` for AT3 demo.
4. **[LOW] FR ID numbering inconsistent in the PDF itself** (Table 3.3: FR-03=SHAP, FR-04=auth; MoSCoW p41: FR-03=traffic-light, FR-04=SHAP). Doc-level; align IDs in AT4 RTM.

## Extras built BEYOND AT2 scope
Large undocumented surface. For AT4 objective-07 (RTM verification) frame these as **scope additions needing justification**, not pure bonus — they widen the gap between submitted design and code.

Auth/account: forgot/reset password (OTP), change-password, 2FA setup/enable/disable, profile + avatar, RBAC roles, admin user mgmt + approval flow, audit log.
Clinical ops: EHR mock lookup, appointment worklist + status PATCH, clinic-list, operational outcomes, slot-optimisation, patient-nudge, carer-proxy, outreach action tracking.
Notifications: schedule + dispatch lifecycle, delivery status.
ML/analytics: model-comparison, cross-validation endpoint, calibration, feedback loop + summary, dashboard, trusts.
Platform: web frontend (Flask-served), i18n, dark theme, guided tour, chatbot, CI/CD workflows, pre-commit, latency benchmark harness, axe-core a11y scan harness, Docker.

## Bottom line
Every AT2 fundamental (FR-01..09, NFR-01..06) is **implemented and backend-verified**.
Resolved defects are documented above. No missing core feature remains; final polish is screenshot/video evidence and exact report wording alignment.
