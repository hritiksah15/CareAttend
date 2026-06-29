# CareAttend AT3 Demo and Viva Evidence Pack

Date: 2026-06-28
Branch: `app-worldclass-phase1`
Current commit baseline: `7343a15 Add dashboard workflow cards`

Purpose: use this document as the speaking plan for AT3 and as preparation for
technical questions. It is aligned to the COM668 handbook guidance for AT3:
15-minute maximum video, natural voice, camera visible, executable software kept
unchanged after recording, and source code submitted as a zip.

## AT3 Rubric Matrix

| Rubric criterion | Weight | What the handbook expects | CareAttend evidence | 90%+ delivery rule |
|---|---:|---|---|---|
| Functional Walkthrough | 45% | Complete demonstration of product functionality, correct operation, robustness, data effects, and limitations. | Web + Flutter app; assessment, result, SHAP, interventions, batch CSV, dashboard cards, clinic list, outcomes, admin approval/audit, bias, ethics, FHIR boundary. | Show role-specific workflows end to end; include at least one boundary/negative case; explicitly state synthetic-data and live-EHR limits. |
| Code Walkthrough | 50% | Detailed source-code understanding, key concepts, significant choices, security/error handling, and less successful items. | Flask routes, SQLAlchemy models, auth/RBAC/session audit, calibrated predictor, SHAP/interventions, batch CSV validation, Flutter `ApiService`/screens/widgets, web `app.js`. | Walk through code that proves ownership, not every file. Explain why each choice was made and what was tested. |
| Communication | 5% | Clear video, pace, structure, legible text, audible commentary. | Timeboxed 4-part script below. | Use 1080p or clear HD, no speed-up, camera overlay not covering UI, transitions edited only to remove dead time. |

## 15-Minute Demo Script

| Time | Segment | What to show | Evidence message |
|---:|---|---|---|
| 0:00-0:45 | Introduction | App title and problem statement. | "CareAttend is a clinical decision-support prototype for reducing NHS missed appointments by identifying DNA risk and closing the loop through staff action tracking." |
| 0:45-2:15 | Login and roles | Login as staff/admin; show role-gated tabs. | RBAC prevents unapproved users from operating staff/admin functions. |
| 2:15-4:15 | Single assessment | Enter patient features, submit, show risk tier, percentage, SHAP, interventions, export. | Prediction is calibrated, explainable, and privacy-minimised; raw feature vectors are not stored. |
| 4:15-5:15 | Batch CSV | Download template, mention required/optional columns, upload valid sample, show results. | Fixes the old dead-end CSV error; batch accepts up to 100 patient rows and provides actionable result CSV. |
| 5:15-6:45 | Dashboard workflow | Show top module cards, expandable result cards, clickable recent assessment detail row. | This is the main operational dashboard: module navigation, drill-down, and outcome review. |
| 6:45-8:15 | Clinic/outcomes | Show clinic list, action/status concepts, operational outcomes. | The system does not stop at prediction; it tracks outreach and outcome evidence. |
| 8:15-9:15 | Admin/governance | Show bias monitor, ethics, admin approval/session log. | Governance, fairness, and auditability are first-class features. |
| 9:15-11:15 | Backend code | `backend/app.py`, `auth.py`, `models.py`, `ml/predictor.py`. | Routes validate input, call calibrated model, persist only necessary summaries/actions, enforce roles, audit security events. |
| 11:15-12:30 | Frontend/app code | Flutter `ApiService`, `dashboard_screen.dart`, `batch_screen.dart`; web `frontend/js/app.js`. | The app and web clients share API contracts and expose role-appropriate workflows. |
| 12:30-13:30 | Testing and QA | Run or show evidence for pytest, Flutter analyze/test, JS syntax, dashboard smoke, sample CSV tests. | 245 backend tests and 38 Flutter tests pass; key risk areas have automated coverage. |
| 13:30-14:30 | Limitations | Synthetic data, no live NHS connector, safety documents are outlines, browser screenshots pending. | Honest scope control: engineering prototype is strong; clinical deployment requires real validation and signed governance. |
| 14:30-15:00 | Conclusion | Summarise aim met, main achievement, next step. | The main achievement is an explainable, governed, role-secured prediction-to-action workflow. |

## Demo Data To Prepare

Use a staff or admin account with approved role.

Assessment example:

| Field | Value |
|---|---:|
| Age | 72 |
| Gender | 0 |
| AppointmentLeadTimeDays | 14 |
| SMSReceived | 1 |
| PriorDNACount | 3 |
| IMDDecile | 2 |
| Hypertension | 1 |
| Diabetes | 0 |
| Alcoholism | 0 |
| Disability | 0 |

Batch file:

- Use `docs/sample_batch_upload.csv` or `docs/dummy_patient_batch_upload.csv`.
- Required columns: `Age,Gender,AppointmentLeadTimeDays,SMSReceived,PriorDNACount,IMDDecile`.
- Optional columns: `Hypertension,Diabetes,Alcoholism,Disability`.

## Code Walkthrough Route

| Code area | File | What to explain |
|---|---|---|
| Request validation and routes | `backend/app.py` | `/api/predict`, `/api/batch`, `/api/dashboard`, `/api/operational-outcomes`; validation errors are actionable; batch detects wrong CSV shape. |
| Security/session model | `backend/auth.py`, `backend/models.py` | bcrypt, opaque DB sessions, remember-me, session timeout, role gates, admin approval, login/logout audit rows. |
| ML inference | `backend/ml/predictor.py` | scaler, calibrated model, trained threshold, SHAP top factors, risk-tier mapping. |
| Interventions | `backend/ml/interventions.py` | rule engine converts risk factors into ranked outreach actions. |
| Fairness governance | `backend/ml/bias_monitor.py` | demographic parity, equalised odds, governance verdict, trained threshold use. |
| Batch CSV | `backend/app.py`, `docs/sample_batch_upload.csv` | canonical wide template, 100-row cap, Field/Value handling, targeted error message. |
| Flutter API boundary | `care_attend_app/lib/services/api_service.dart` | central headers, timeouts, offline flag, response handling. |
| Flutter dashboard | `care_attend_app/lib/screens/dashboard_screen.dart` | module cards, expandable result cards, details/actions, widget test coverage. |
| Web dashboard | `frontend/js/app.js`, `frontend/templates/index.html` | module cards, role-aware navigation, expandable panels, clickable table rows. |

## Technical Questions and Defensible Answers

### 1. What tech stack are you using?

Flask backend, SQLAlchemy/Alembic database layer, scikit-learn ML pipeline,
SHAP explainability, Pandas/Numpy data processing, Flutter mobile/web app, and
a Flask-served web frontend using vanilla JavaScript, CSS, Chart.js/Plotly where
needed, and Lucide icons.

Why: this stack is lightweight enough for an academic prototype but still
professional: Flask exposes clear REST endpoints, SQLAlchemy gives auditable
persistence, scikit-learn supports interpretable calibrated models, and Flutter
gives one codebase for mobile/tablet/web clinical workflows.

Candidates considered: Django/FastAPI for backend, React/Vue for web, React
Native for mobile, Random Forest/XGBoost/LightGBM/MLP for modelling. Logistic
Regression was selected for interpretability and auditability after comparison.

### 2. Are there aims/objectives not achieved?

Yes. Live NHS EHR integration, real NHS patient-data validation, signed DPIA,
signed DCB0129 safety case, penetration test, and real deployment were not
achieved because they require institutional agreements, clinical safety officer
approval, data-sharing governance, and external validation beyond the academic
prototype scope. Prototype FHIR boundaries and safety outlines are documented.

### 3. What was the most challenging part?

The hardest part was making the ML useful without making unsafe clinical claims.
The solution was to use calibration, a trained operating threshold, SHAP
explanations, fairness monitoring, human-overview wording, and a model card that
states the synthetic-data limitation clearly.

### 4. What real-world applications can this be used for?

Outpatient appointment DNA reduction, clinic worklist prioritisation, targeted
reminder planning, transport/carer support triage, service-manager outcome
tracking, and governance review of whether interventions are fair across groups.
It is decision support for staff, not an automated clinical decision-maker.

### 5. What SDLC did you use and why?

The project combines CRISP-DM for the ML lifecycle with iterative incremental
software delivery. CRISP-DM fits the data-mining workflow: business
understanding, data understanding, modelling, evaluation, and deployment. The
app itself was built iteratively because each sprint could add, test, and review
one feature set: prediction, explainability, batch upload, dashboard, clinic
actions, governance, and app polish.

Alternatives: waterfall would be too rigid because the ML and UX risks were
unknown early; pure Scrum would be heavier than needed for a solo academic
project.

### 6. What architectural design pattern are you using?

A layered client-server architecture: UI clients call REST APIs; Flask route
handlers act as controllers; SQLAlchemy models handle persistence; ML modules
encapsulate prediction, interventions, calibration, and fairness; Flutter uses
screen/service/widget separation through `ApiService`, screens, and reusable UI
widgets. It is not a monolith of UI logic embedded in routes.

### 7. What security considerations are implemented?

Password hashing with bcrypt, opaque session tokens, 30-minute idle timeout,
remember-me sessions, 2FA/TOTP, RBAC, admin approval flow, failed-login rate
limiting, audit logging, no self-demotion/self-delete for admins, input
validation, clear role-gated frontend tabs, and privacy-minimised assessment
summary persistence. Remaining production requirements are penetration testing,
DSPT, DPIA sign-off, retention policy, and live connector security review.

### 8. How does it compare to market alternatives?

Existing appointment systems and messaging tools such as EHR appointment
modules, Accurx/DrDoctor-style messaging, and generic BI dashboards can support
communication and reporting. CareAttend's difference is combining explainable
DNA risk prediction, fairness governance, batch and single assessment, staff
workflow actions, and outcome measurement in one prototype. A real buyer would
only use it after external validation and integration approval.

### 9. What are the demographics of the user base?

Direct users are NHS clinic staff, administrators, service managers, and
governance/equality leads. Indirect beneficiaries are patients at risk of
missing appointments, including older adults, deprived communities, disabled
patients, and patients needing carer/transport support. UX choices therefore
prioritise clarity, role-specific navigation, large tap targets, readable risk
tiers, non-technical summaries, and multilingual nudge support.

### 10. What accessibility considerations do you have?

WCAG 2.2 AA-oriented work: contrast checks, light/dark theme support, labelled
controls, keyboard-friendly web rows, tap targets, not relying only on colour,
responsive mobile layouts, readable dashboard cards, and accessibility evidence
in `docs/a11y_report.md`. Human usability evidence is recorded through SUS.

### 11. How much AI did you use?

Answer this according to the university's disclosure rules and your actual
process. Keep the repository evidence focused on implemented, inspected, and
tested project work; do not include external-tool names in commits,
source comments, screenshots, or submission artefacts.

### 12. What would you do differently?

Start user testing and screenshot evidence earlier; keep report wording and
code changes synchronised every sprint; reduce scope earlier around production
NHS integration; and plan a real-data partnership sooner if the aim were a
deployable clinical product rather than an academic prototype.

### 13. Which module helped most?

The strongest link is the software engineering/project management content:
requirements engineering, risk analysis, architecture, testing, and SDLC
selection. If asked live, name the exact Westminster/degree module title that
covered software engineering and project management on your transcript.

### 14. What new skills did you acquire?

Model calibration, SHAP explanations, fairness auditing, Flask RBAC/session
security, SQLAlchemy migrations, Flutter app development, accessible dashboard
design, OpenAPI documentation, and evidence-led QA across backend, web, and app.

### 15. How would you monetize this?

B2B SaaS/licensing to clinics or NHS trusts, with implementation and support
fees. Pricing should be per trust/site rather than per patient to avoid
misaligned incentives. A realistic route is pilot study, validated outcome
evidence, integration certification, then enterprise licensing with governance,
audit, and support included.

## Hard Limitations To Say Clearly

- The model is not clinically validated on real NHS populations.
- Synthetic performance metrics are evidence of pipeline correctness, not
  real-world clinical effectiveness.
- FHIR support is a prototype adapter, not a live EMIS/SystmOne/Spine connector.
- DPIA/DCB0129 documents are outlines, not signed deployment approvals.
- Screenshots/video evidence must be captured from the final executable build.

## Final Examiner Sentence

CareAttend's strongest contribution is not just predicting missed appointments;
it demonstrates a traceable, explainable, fairness-audited and role-secured
workflow that connects prediction to staff action and measurable outcomes, while
being honest about the external validation still required before clinical use.
