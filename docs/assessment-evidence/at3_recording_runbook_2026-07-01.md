# AT3 Recording Runbook - Hosted Demo

Date: 2026-07-01
Use with: `docs/assessment-evidence/at3_viva_evidence_pack.md`
Hosted app: `https://careattend-64793.web.app/`
Hosted API health: `https://careattend-api.onrender.com/health`
Runtime/deploy baseline: `6c86456 fix: avoid benchmark credential false positive`
Current GitHub submission branch: `master` with later documentation/test-path fixes

## Recording Rules

- Keep the video under 15 minutes.
- Use natural voice; do not speed up the recording.
- Keep camera visible if required by the AT3 brief.
- Use the hosted Firebase app and Render API unless a live outage forces local fallback.
- Do not show passwords, secret values, reset codes, `.env`, Render secrets, GitHub secrets, or admin credentials.
- State clearly that the app is an academic prototype and not clinically validated for live NHS use.

## Pre-Recording Check

Run these immediately before recording:

```bash
curl -s https://careattend-api.onrender.com/health
```

Expected:

```json
{"auth_tables":"ok","database":"ok","model_loaded":true,"status":"ok"}
```

Open the hosted app:

```text
https://careattend-64793.web.app/
```

Prepare:

- One approved `staff` or `admin` account.
- One admin account if showing admin/bias/session log.
- `docs/model-and-data/sample_batch_upload.csv` ready for batch upload.
- `docs/assessment-evidence/at3_viva_evidence_pack.md` open for the script.
- Code editor open at:
  - `backend/app.py`
  - `backend/auth.py`
  - `backend/ml/predictor.py`
  - `backend/ml/interventions.py`
  - `care_attend_app/lib/services/api_service.dart`
  - `care_attend_app/lib/screens/dashboard_screen.dart`

## 15-Minute Run-Of-Show

### 0:00-0:45 - Introduction

Show the hosted login screen.

Say:

> CareAttend is a clinical decision-support prototype for reducing NHS missed appointments. It predicts DNA risk, explains the main drivers, and turns risk into staff action tracking.

Mention:

- Built as an academic prototype.
- Uses synthetic NHS-style data.
- Real clinical deployment would require real NHS validation, DPIA, DCB0129, and live EHR integration approval.

### 0:45-2:15 - Login And Roles

Log in as approved staff/admin.

Show:

- Role-appropriate navigation.
- Staff/admin tabs.
- Admin/governance areas if using admin.

Say:

> Access is role-gated. Public registration creates a low-privilege user, and operational access requires admin approval.

Do not show password entry if possible; start with password manager hidden or pause before typing.

### 2:15-4:15 - Single Assessment

Open patient assessment form and enter:

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

Submit and show:

- Risk percentage and tier.
- SHAP/top risk factors.
- Intervention recommendations.
- Export controls if visible.

Say:

> The result is calibrated and explainable. The app stores only minimal assessment summary data, not raw patient feature vectors.

### 4:15-5:15 - Batch CSV

Open batch upload.

Show:

- Download template action.
- Required wide CSV columns.
- Upload `docs/model-and-data/sample_batch_upload.csv`.
- Result table/download.

Say:

> Batch mode supports up to 100 rows and gives clear validation errors for the wrong CSV shape.

### 5:15-6:45 - Dashboard Workflow

Open dashboard.

Show:

- Module cards.
- Risk counts/recent assessments.
- Expand a recent assessment/detail row if data is present.

Say:

> The dashboard connects risk assessment to operational review rather than leaving the prediction isolated.

### 6:45-8:15 - Clinic And Outcomes

Show clinic/outcomes concepts if seeded data is present.

Show:

- Clinic list or appointment worklist.
- Outreach/action/status concepts.
- Operational outcomes summary.

Say:

> The prototype tracks whether staff action is taken and whether outcomes improve, but this is observational evidence in the prototype.

If there is no seeded clinic data, say:

> This workflow is implemented and tested; for the recording I am showing the interface and then the endpoint/code path in the walkthrough.

### 8:15-9:15 - Admin, Bias, Ethics

Show:

- Bias monitor.
- Ethics framework.
- Admin approval/session/audit view if available.

Say:

> Governance is built into the workflow: admin approval, audit logs, fairness indicators, and explicit limitation wording.

### 9:15-11:15 - Backend Code Walkthrough

Open code quickly, do not scroll randomly.

Show:

- `backend/app.py`: `/api/predict`, validation, health/security headers.
- `backend/auth.py`: bcrypt, opaque sessions, timeout, OTP, role decorators.
- `backend/ml/predictor.py`: calibrated model, threshold, SHAP.
- `backend/ml/interventions.py`: rule-based interventions.

Say:

> Flask routes validate inputs and enforce roles. The predictor loads the calibrated model and returns probability, risk tier, SHAP factors, and interventions. The health endpoint checks model, database, and auth tables.

### 11:15-12:30 - Frontend/App Code Walkthrough

Show:

- `care_attend_app/lib/services/api_service.dart`: API boundary, token handling, errors.
- `care_attend_app/lib/screens/dashboard_screen.dart`: module cards and details.
- Optional: `frontend/js/app.js` for web parity.

Say:

> The clients share the same API contract. The app keeps UI logic separate from API calls and hides restricted views for lower roles.

### 12:30-13:30 - Testing And QA

Show README or final QA sign-off.

Say:

> The current baseline has 246 backend tests and 39 Flutter tests. CI, CodeQL, dependency audit, secret scanning, accessibility scanning, and hosted smoke checks passed.

Mention:

- `pip-audit`: no known Python vulnerabilities after dependency fixes.
- `bandit`: no issues.
- a11y scan: 0 violations.
- GitHub CI and Render deployment passed.

### 13:30-14:30 - Limitations

Say clearly:

> The model is validated on synthetic data, not real NHS data. The FHIR adapter is a prototype boundary, not a live EMIS/SystmOne/Spine connector. DPIA and DCB0129 are documented outlines, not signed deployment approvals.

### 14:30-15:00 - Conclusion

Say:

> The main achievement is a complete, explainable, role-secured prediction-to-action workflow with fairness and audit evidence. The next real-world step would be external validation on governed NHS data and signed clinical safety approval.

## If Something Goes Wrong During Recording

- If Render is cold: wait and refresh after `/health` returns `status=ok`.
- If a workflow screen has no data: say it is implemented/tested, then show code or screenshot evidence.
- If batch upload fails: use `docs/model-and-data/sample_batch_upload.csv`.
- If admin credentials are not ready: show staff workflow and cover admin via screenshots/code.
- If time runs short: skip clinic details and preserve code walkthrough plus limitations.

## Final Source Zip Reminder

Create the source zip from Git:

```bash
git archive --format=zip --output CareAttend-source.zip master
```

Do not include local videos, browser cache files, `.env`, or untracked scratch files.
