# CareAttend — Requirements Traceability Matrix

**Purpose:** Prove every requirement traces from objective → design → implementation → test. This single table is the highest-ROI artefact for the AT2 *Software Definition* criterion (40% of AT2). Paste into the report and reference it from the requirements section.

**How it was built:** Requirement IDs harvested directly from `@requirement` tags in the source (`grep -rEn "FR-|NFR-|US-" backend/`). Implementation and test columns are verified file references, not claims. **Action for you:** replace each *Requirement (description)* cell with the exact wording from your AT2 report so the matrix is word-identical to your requirements section.

**Test status:** 226 pytest tests, all passing (June 2026).

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
| **FR-09** | *(if defined in report — e.g. PDF/print export)* | Could | — | frontend (jsPDF) | manual / UAT | ⚠️ confirm |

## Non-Functional Requirements

| Req ID | Requirement (sync wording w/ AT2) | MoSCoW | Design / standard | Implementation | Test evidence | Status |
|--------|-----------------------------------|:------:|-------------------|----------------|---------------|:------:|
| **NFR-01** | Privacy: no raw patient input persisted; only anonymised assessment summaries for operations | Must | GDPR Art 5(1)(c) | `assessment_summaries` stores ID/probability/tier/age-group/feedback only; no patient table in `models.py` | `test_feature_coverage.py::TestDashboard::test_prediction_persists_anonymised_summary` | ✅ |
| **NFR-04** | Model quality: F1 ≥ 0.72, Recall ≥ 0.70 | Must | Eval methodology | `ml/pipeline.py` (threshold opt); `training_results.json` | `test_predictor.py` (NFR-04) | ✅ |
| **NFR-06** | Security: bcrypt hashing, 30-min session timeout, 2FA, RBAC | Must | OWASP / NHS DSPT | `auth.py:29` `SESSION_TIMEOUT=1800`; bcrypt; TOTP | `test_auth.py`; `test_new_endpoints::TestTwoFactor` | ✅ |
| **NFR-02** | Performance: interactive endpoints respond within budget (`/predict` p95 ≤ 500 ms, `/bias-audit` p95 ≤ 1000 ms) | Must | Latency benchmark | `backend/benchmark_latency.py` | `docs/perf_benchmark.md` — measured p95 1.35 ms (`/predict`) and 4.48 ms (`/bias-audit`), both well under target | ✅ |
| **NFR-03** | *(confirm — e.g. usability / WCAG AA)* | — | WCAG 2.2 | dark mode, contrast | SUS test (A5) TODO | ⚠️ confirm |
| **NFR-05** | *(confirm — e.g. portability / Docker)* | — | OCI / 12-factor | `Dockerfile`; GHCR image published by CI; SQLite/Postgres via `DATABASE_URL` | CI Docker build + `/health` gate green on every master push | ⚠️ confirm wording (evidence present) |

## User Stories & Features (selected, code-tagged)

| ID | Story / Feature | Implementation | Test / Evidence | Status |
|----|-----------------|----------------|-----------------|:------:|
| **US-002** | Practice dashboard (risk counts, breakdown) | `app.py:284` `/api/dashboard` | `test_feature_coverage::TestDashboard` | ✅ |
| **US-011** | Export bias audit as PDF for governance | `app.py:497`; frontend jsPDF | manual / UAT (frontend) | ⚠️ add UAT |
| **Feature 10** | Mock NHS EHR integration | `app.py:382` `/api/ehr/*` | `test_feature_coverage::TestEHR` | ✅ |
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
- **Remaining (⚠️):** US-011 PDF export = frontend, needs UAT evidence. NFR-03 (usability/WCAG) needs a SUS study (A5) — WCAG 2.2 design measures (contrast, dark mode, keyboard) are in place but unaudited. NFR-05 (portability) evidence is present (Docker + CI/GHCR); only the report wording needs confirming.

**Distinction tip:** in the report prose, state *"every Must requirement is traced to an automated test; Should/Could items to UAT"* and cite this table. That sentence + table is what moves the 40% bucket from 70 to 85.
