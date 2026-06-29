# CareAttend — Requirements Traceability Matrix

**Purpose:** Prove every requirement traces from objective → design → implementation → test. This single table is the highest-ROI artefact for the AT2 *Software Definition* criterion (40% of AT2). Paste into the report and reference it from the requirements section.

**How it was built:** Requirement IDs harvested directly from `@requirement` tags in the source (`grep -rEn "FR-|NFR-|US-" backend/`). Implementation and test columns are verified file references, not claims. **Action for you:** replace each *Requirement (description)* cell with the exact wording from your AT2 report so the matrix is word-identical to your requirements section.

**Test status:** 241 pytest tests, all passing (June 2026).

---

## Functional Requirements

| Req ID | Requirement (sync wording w/ AT2) | MoSCoW | Design artefact | Implementation | Test evidence | Status |
|--------|-----------------------------------|:------:|-----------------|----------------|---------------|:------:|
| **FR-01** | Capture patient attributes & generate the prediction dataset | Must | DFD / Class diagram | `app.py:135` `/api/predict`; `ml/data_generator.py` | `test_api.py::TestPredictEndpoint`; `test_data_generator.py` | ✅ |
| **FR-02** | Produce individual DNA risk score (0–100%) + tier | Must | Sequence diagram (predict) | `ml/predictor.py::predict` | `test_predictor.py`; `test_api::test_predict_success` | ✅ |
| **FR-03** | Explain prediction via SHAP top-3 factors | Must | Component diagram (XAI) | `ml/predictor.py` (SHAP); `app.py:482` | `test_predictor.py` (SHAP structure) | ✅ |
| **FR-04** | Authenticate users (register / login / logout, RBAC) | Must | Sequence diagram (auth) | `auth.py`; `models.py` (User/Session) | `test_auth.py::TestAuthEndpoints` | ✅ |
| **FR-05** | Generate contextual intervention recommendations | Must | Activity diagram | `ml/interventions.py` | `test_interventions.py` | ✅ |
| **FR-06** | Priority-order & cap interventions (max 5, dedup) | Should | Activity diagram | `ml/interventions.py` | `test_interventions.py` (priority, dedup, max-5) | ✅ |
| **FR-07** | Bias audit (demographic parity + equalised odds) | Must | Component diagram (fairness) | `ml/bias_monitor.py` using calibrated model + saved threshold; `app.py:/api/bias-audit` | `test_bias_monitor.py`; `test_api::TestBiasEndpoint` | ✅ |
| **FR-07a** | Fairness **governance gate**: aggregate PASS/ACTION_REQUIRED verdict at 0.10 tolerance + human-oversight actions (monitoring only — no protected-attribute thresholds) | Should | Component diagram (governance) | `ml/bias_monitor.py::_governance_summary`; `app.py:/api/bias-audit` (audits breaches) | `test_bias_monitor.py::TestGovernanceGate` (5 tests) | ✅ |
| **FR-08** | Batch CSV upload (≤100 records) → results CSV | Should | Sequence diagram (batch) | `app.py:188` `/api/batch` | `test_api.py` (batch path) | ✅ |
| **FR-09** | Export / print results and governance reports | Could | UI workflow / UAT plan | frontend export controls (jsPDF/CSV/JSON/print) | `docs/feature_test_plan.md` UX8 scenario | ✅ |

## Non-Functional Requirements

| Req ID | Requirement (sync wording w/ AT2) | MoSCoW | Design / standard | Implementation | Test evidence | Status |
|--------|-----------------------------------|:------:|-------------------|----------------|---------------|:------:|
| **NFR-01** | Privacy: no raw patient input persisted; only anonymised assessment summaries for operations | Must | GDPR Art 5(1)(c) | `assessment_summaries` stores ID/probability/tier/age-group/feedback only; no patient table in `models.py` | `test_feature_coverage.py::TestDashboard::test_prediction_persists_anonymised_summary` | ✅ |
| **NFR-04** | Model quality: F1 ≥ 0.72, Recall ≥ 0.70 | Must | Eval methodology | `ml/pipeline.py` (threshold opt); `training_results.json` | `test_predictor.py` (NFR-04) | ✅ |
| **NFR-06** | Security: bcrypt hashing, 30-min session timeout, 2FA, RBAC | Must | OWASP / NHS DSPT | `auth.py:29` `SESSION_TIMEOUT=1800`; bcrypt; TOTP | `test_auth.py`; `test_new_endpoints::TestTwoFactor` | ✅ |
| **NFR-02** | Performance: interactive endpoints respond within budget (`/predict` p95 ≤ 500 ms, `/bias-audit` p95 ≤ 1000 ms) | Must | Latency benchmark | `backend/benchmark_latency.py` | `docs/perf_benchmark.md` — measured p95 1.35 ms (`/predict`) and 4.48 ms (`/bias-audit`), both well under target | ✅ |
| **NFR-03** | Usability / accessibility: WCAG 2.2 AA + SUS usability study | Must | WCAG 2.2 AA + SUS >= 68 | dark mode, contrast, keyboard; `frontend/css/style.css`; `docs/sus_testing_template.md` | `docs/a11y_report.md` — axe-core/Playwright scan, 0 violations across landing/assessment/results in light + dark (3 contrast defects found + fixed); `docs/sus_results_2026-06-28.md` — 5/5 role-adjusted proxy participants, mean SUS 74.0/100 | ✅ |
| **NFR-05** | Portability / deployability: containerised backend and environment-based configuration | Should | OCI / 12-factor | `Dockerfile`; GHCR image published by CI; SQLite/Postgres via `DATABASE_URL` | CI Docker build + `/health` gate green on every master push | ✅ |

## User Stories & Features (selected, code-tagged)

| ID | Story / Feature | Implementation | Test / Evidence | Status |
|----|-----------------|----------------|-----------------|:------:|
| **US-002** | Practice dashboard (risk counts, breakdown) | `app.py:284` `/api/dashboard` | `test_feature_coverage::TestDashboard` | ✅ |
| **US-011** | Export bias audit as PDF for governance | `/api/bias-audit`; frontend jsPDF export controls | `docs/feature_test_plan.md` UX8 scenario; `node --check frontend/js/app.js` | ✅ |
| **US-012 / FR-09 evidence** | Risk trajectory line chart for the session's last five assessments | Web `frontend/js/app.js::recordRiskHistory`; Flutter `ApiService.recordRiskHistory`; `_RiskHistoryChart` | `care_attend_app/test/logic_test.dart::risk history keeps only the last five assessments`; `node --check frontend/js/app.js` | ✅ |
| **Feature 10** | Mock NHS EHR integration + prototype FHIR R4 adapter | `app.py:/api/ehr/*`; `backend/fhir.py`; `docs/ehr_fhir_architecture.md` | `test_feature_coverage::TestEHR`; `test_new_endpoints::TestAppointmentWorklist` FHIR mapping tests | ✅ |
| **Feature 12** | Prediction feedback loop | `app.py:327` `/api/feedback` | `test_feature_coverage::TestFeedback` | ✅ |
| **Feature 13** | Natural-language risk summary | `app.py:_generate_nl_summary` | `test_feature_coverage::TestNLSummary` | ✅ |
| **Feature 14** | Multi-trust configuration | `app.py:417` `/api/trusts` | `test_feature_coverage::TestTrusts` | ✅ |
| **Feature 15** | Rigorous evaluation (CV, CIs, McNemar) | `ml/evaluation.py`; `app.py:434` | `test_feature_coverage::TestCrossValidation` | ✅ |
| **Feature 19** | NHSX AI ethics framework mapping | `app.py:461` `/api/ethics-framework` | `test_feature_coverage::TestEthicsFramework` | ✅ |
| **(new)** | Carer/family proxy mode | `app.py:691` | `test_new_endpoints::TestCarerProxy` | ✅ |
| **(new)** | Appointment slot optimisation | `app.py:735` | `test_new_endpoints::TestSlotOptimisation` | ✅ |
| **(new)** | Patient nudge generator (4 langs) | `app.py:813` | `test_new_endpoints::TestPatientNudge` | ✅ |
| **(new)** | Admin audit log | `app.py:868` | `test_new_endpoints::TestAuditLog` | ✅ |
| **(new)** | Push-notification scheduling | `app.py:570` | `test_new_endpoints::TestNotifications` | ✅ |
| **(new)** | Appointment clinic-list workflow | `/api/appointments`; `/api/clinic-list`; `models.py::AppointmentRecord` | `test_new_endpoints::TestAppointmentWorklist` | ✅ |
| **(new)** | Operational outreach action tracking | `/api/actions`; `models.py::OutreachAction` | `test_new_endpoints::TestOutreachActions` | ✅ |
| **(new)** | Operational outcomes dashboard | `/api/operational-outcomes`; `frontend/js/app.js` dashboard render | `test_new_endpoints::TestAppointmentWorklist::test_operational_outcomes_aggregates_actioned_vs_unactioned` | ✅ |
| **(new)** | Staff onboarding **approval flow** (pending queue → approve → role elevation; out-of-band admin seed) | `app.py:/api/admin/pending-users`, `/api/admin/users/<id>/approve`; `flask create-admin` CLI | `test_new_endpoints::TestUserApproval` (6 tests) | ✅ |
| **(new)** | Notification **delivery lifecycle** (simulated provider: scheduled→sent/failed, retry, audit) | `notification_provider.py`; `app.py:/api/notifications/<id>/dispatch`; `models.py::ScheduledNotification` delivery fields | `test_new_endpoints::TestNotificationDispatch` (5 tests) | ✅ |

---

## Coverage summary

- **Core FR/NFR (FR-01→08, NFR-01/04/06):** designed, implemented, **automated-tested** ✅
- **Sprint-3 advanced endpoints:** automated-tested ✅
- **Features 10/12/13/14/15/19 + US-002:** now automated-tested ✅
- **Fairness governance, staff approval, notification delivery:** automated-tested ✅ (added June 2026)
- **NFR-02 (performance):** latency benchmark captured ✅ — `docs/perf_benchmark.md` + repeatable `backend/benchmark_latency.py` (June 2026).
- **NFR-03 (accessibility/usability):** WCAG 2.2 AA automated scan captured ✅ — `docs/a11y_report.md` + repeatable `tools/a11y/` harness, 0 violations after fixing 3 contrast defects (June 2026). SUS evidence captured ✅ — `docs/sus_results_2026-06-28.md`, mean SUS 74.0/100 above the 68 target.
- **Remaining evidence polish:** Screenshot/video evidence remains pending for final report polish. External clinical gates (signed DPIA/DCB0129, real EHR connector approval, real-data validation, pen test/DSPT) remain outside the academic prototype.

**Distinction tip:** in the report prose, state *"every Must requirement is traced to an automated test; Should/Could items to UAT"* and cite this table. That sentence + table is what moves the 40% bucket from 70 to 85.
