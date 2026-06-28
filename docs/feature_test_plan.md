# Care Attend — Feature Test Plan (all roles) — v1.2.0

Manual test script. Three roles: `user` (registered, unapproved), `staff`, `admin`.
Tests every feature, the role gate, the steps, and the expected outcome.
Verifies which features work vs broken.

---

## 0. Setup

### 0.1 Start backend
```bash
cd backend && ./run.sh          # starts Postgres, migrates, serves :5000
# health check:
curl -s localhost:5000/health   # expect {"status":"ok",...} 200
```

### 0.2 Start web client
Open http://127.0.0.1:5000 (Flask serves the static web client).

### 0.3 Start Flutter app (optional, separate UI)
```bash
export PATH="$HOME/development/flutter/bin:$PATH"
cd care_attend_app && flutter run -d chrome --web-port=8090   # → http://localhost:8090
```
App talks to backend at 127.0.0.1:5000 (web) / 10.0.2.2:5000 (Android emu).

### 0.4 Seed the three role accounts

**Admin (out-of-band CLI — only way to make first admin):**
```bash
cd backend
export CAREATTEND_ADMIN_USER=admin1 CAREATTEND_ADMIN_EMAIL=admin@nhs.test CAREATTEND_ADMIN_PASSWORD='Admin#2026pw'  # pragma: allowlist secret
flask --app app create-admin           # "Admin account 'admin1' created."
```

**Staff:** register via web/app (becomes `user`), then admin approves it.
```bash
# register (role forced to 'user' regardless of body):
curl -s -XPOST localhost:5000/auth/register -H 'Content-Type: application/json' \
  -d '{"username":"staff1","email":"staff@nhs.test","password":"Staff#2026pw"}'  # pragma: allowlist secret
# admin logs in, lists pending, approves (see §4 for token capture):
```

**User:** register only, leave unapproved.
```bash
curl -s -XPOST localhost:5000/auth/register -H 'Content-Type: application/json' \
  -d '{"username":"user1","email":"user@nhs.test","password":"User#2026pw1"}'  # pragma: allowlist secret
```

### 0.5 Capture tokens (for curl tests)
```bash
TOKEN_ADMIN=$(curl -s -XPOST localhost:5000/auth/login -H 'Content-Type: application/json' \
  -d '{"username":"admin1","password":"Admin#2026pw"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])')  # pragma: allowlist secret
TOKEN_STAFF=$(curl -s -XPOST localhost:5000/auth/login -H 'Content-Type: application/json' \
  -d '{"username":"staff1","password":"Staff#2026pw"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])')  # pragma: allowlist secret
TOKEN_USER=$(curl -s -XPOST localhost:5000/auth/login -H 'Content-Type: application/json' \
  -d '{"username":"user1","password":"User#2026pw1"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])')  # pragma: allowlist secret
auth() { echo "-H"; echo "Authorization: Bearer $1"; }   # helper
```

---

## 1. Role gate matrix (expected)

| Feature / endpoint | user | staff | admin |
|---|:--:|:--:|:--:|
| Register / Login / Forgot / Reset | ✓ public | ✓ | ✓ |
| **Predict** `/api/predict` | ✓ | ✓ | ✓ |
| Profile GET/PUT, change-password, 2FA | ✓ | ✓ | ✓ |
| Batch CSV `/api/batch` | ✗ 403 | ✓ | ✓ |
| Dashboard `/api/dashboard` | ✗ | ✓ | ✓ |
| Feedback POST / summary | ✗ | ✓ | ✓ |
| EHR lookup / list | ✗ | ✓ | ✓ |
| Appointments / clinic-list / status | ✗ | ✓ | ✓ |
| Operational outcomes | ✗ | ✓ | ✓ |
| Trusts | ✗ | ✓ | ✓ |
| Notifications schedule/list/dispatch | ✗ | ✓ | ✓ |
| Outreach actions POST/GET/PATCH | ✗ | ✓ | ✓ |
| Carer proxy / list | ✗ | ✓ | ✓ |
| Slot optimisation | ✗ | ✓ | ✓ |
| Patient nudge | ✗ | ✓ | ✓ |
| **Bias audit** `/api/bias-audit` | ✗ | ✗ 403 | ✓ |
| Model info / comparison / export | ✗ | ✗ | ✓ |
| Cross-validation eval | ✗ | ✗ | ✓ |
| Ethics framework | ✗ | ✗ | ✓ |
| Audit log | ✗ | ✗ | ✓ |
| Admin users / role / approve / delete | ✗ | ✗ | ✓ |

> **FINDING to confirm:** `/api/predict` has only `@token_required` (no role gate).
> An **unapproved `user` can run predictions**. If that is unintended, add
> `@role_required("staff","admin")` to predict. Test it explicitly in §2.

---

## 2. Tests as `user` (unapproved)

| # | Action | Steps | Expected outcome |
|---|---|---|---|
| U1 | Login | web/app login as user1 | Logged in; staff/admin tabs hidden or denied |
| U2 | Predict | submit patient form (Age 72, Gender F, Lead 14, SMS yes, PriorDNA 3, IMD 2) | 200: probability %, risk_tier, top-3 SHAP, interventions, `model_used:"Logistic Regression (calibrated)"` |
| U3 | Profile | open profile, edit display name | 200 saved |
| U4 | Change password | profile → change password | 200; re-login with new pw works |
| U5 | 2FA setup | profile → enable 2FA, scan QR, confirm code | 2FA enabled; next login needs code |
| U6 | Denied: dashboard | `curl localhost:5000/api/dashboard $(auth $TOKEN_USER)` | **403** "insufficient role" |
| U7 | Denied: bias-audit | `curl localhost:5000/api/bias-audit $(auth $TOKEN_USER)` | **403** |

Curl example U2:
```bash
curl -s -XPOST localhost:5000/api/predict $(auth $TOKEN_USER) -H 'Content-Type: application/json' \
 -d '{"Age":72,"Gender":0,"AppointmentLeadTimeDays":14,"SMSReceived":1,"PriorDNACount":3,"IMDDecile":2}'
# expect probability, percentage, risk_tier, shap_values[3], interventions, model_used
```

---

## 3. Tests as `staff`

Pre: admin must approve staff1 first (see §4 A3). Then re-login staff1 to refresh role.

| # | Feature | Steps | Expected outcome |
|---|---|---|---|
| S1 | Predict | same as U2 | 200 full result |
| S2 | Batch CSV | upload CSV (≤100 rows: Age,Gender,AppointmentLeadTimeDays,SMSReceived,PriorDNACount,IMDDecile + comorbidity cols) | CSV download: per-row risk_probability, risk_tier, age_group, top_risk_factor |
| S2b | Batch limit | upload 101 rows | **400** "Maximum 100 records" |
| S3 | Dashboard | open Dashboard tab; set date range | counts by risk tier; date filter narrows; loads <2s |
| S4 | Feedback | on a result, mark outcome attended/DNA | 200 stored; appears in feedback summary |
| S5 | EHR lookup | enter mock NHS number on patient form | auto-fills demographics (mock EMIS/SystmOne); unknown → 404 with scope note |
| S6 | Appointments import | POST appointments (EHR id or full features) | rows created, risk-scored on import |
| S7 | Clinic list | open Clinic tab, pick date | per-user day worklist with tiers |
| S8 | Appt status | PATCH status → attended/dna/cancelled | status updated; feeds outcomes |
| S9 | Operational outcomes | open outcomes | anonymised attended/DNA rates by tier; actioned-vs-unactioned gap (observational note) |
| S10 | Notification schedule | schedule reminder for high-risk | notification row, status scheduled, delivery_status pending |
| S11 | Notification dispatch | dispatch it (clinic-list one-click) | delivery_status sent (or failed→retry); audited |
| S12 | Outreach action | create action (phone/transport), complete it | action planned→completed; linked notification → actioned |
| S13 | Carer proxy | add carer (name, relationship, contact, patient ref) | persisted; listed |
| S14 | Slot optimisation | run slot optimiser | suggested slots by risk |
| S15 | Patient nudge | generate nudge (pick language EN/CY/UR/PL) | localised reminder text |
| S16 | Trusts | view trust config | trust list / detail |
| S17 | Denied: bias-audit | `curl .../api/bias-audit $(auth $TOKEN_STAFF)` | **403** (admin-only) |
| S18 | Denied: admin users | `curl .../api/admin/users $(auth $TOKEN_STAFF)` | **403** |

---

## 4. Tests as `admin`

| # | Feature | Steps | Expected outcome |
|---|---|---|---|
| A1 | Login | admin1 | all tabs visible |
| A2 | Pending users | `GET /api/admin/pending-users` | lists role=user accounts (user1, staff1 if unapproved) |
| A3 | Approve staff | `POST /api/admin/users/<staff1_id>/approve` | staff1 role→staff; audited. **Do this before §3.** |
| A4 | Change role | `PUT /api/admin/users/<id>/role` body `{"role":"admin"}` | role updated |
| A5 | Delete user | `DELETE /api/admin/users/<id>` | user removed (cascade sessions) |
| A6 | Bias audit | open Bias tab | per-attribute DP/EO, traffic-light, governance verdict PASS/ACTION_REQUIRED @0.10, plain-English summary; breach → banner + audit row (deduped 24h) |
| A7 | Model info | `GET /api/model-info` | model name, threshold, metrics |
| A8 | Model comparison | `GET /api/model-comparison` | LR vs RF/XGB/LGBM metric table |
| A9 | Cross-validation | `POST /api/evaluation/cross-validation` | CV folds, CIs, McNemar |
| A10 | Ethics framework | `GET /api/ethics-framework` | NHSX/ethics mapping |
| A11 | Export model | `GET /api/export-model` | model artefact/metadata download |
| A12 | Audit log | `GET /api/audit-log` | staff actions + login/logout session events w/ username, IP, timestamps |
| A12b | Login Session Log UI | web Admin tab + Flutter Admin screen | recent `login_success`/`logout` rows render with time, user, event, IP/detail |
| A13 | Inherits all staff features | repeat §3 S1–S16 with $TOKEN_ADMIN | all 200 |

Approve curl (A3):
```bash
PID=$(curl -s localhost:5000/api/admin/pending-users $(auth $TOKEN_ADMIN) | python3 -c 'import sys,json;[print(u["userId"]) for u in json.load(sys.stdin).get("users",[]) if u["username"]=="staff1"]')
curl -s -XPOST localhost:5000/api/admin/users/$PID/approve $(auth $TOKEN_ADMIN)
# then re-login staff1 to get a staff-role token
```

---

## 5. Cross-cutting / negative tests

| # | Test | Expected |
|---|---|---|
| X1 | No token on protected route | 401 |
| X2 | Expired/invalid token | 401; web keeps token only on 5xx (no false logout) |
| X3 | Session timeout 30 min idle | re-login required (NFR-06) |
| X4 | Predict missing field | 400 "Missing fields: ..." |
| X5 | Predict bad range (Age 999, IMD 99) | 400 validation error |
| X6 | Register weak password | 400 password-policy message |
| X7 | Register duplicate email | 400 |
| X8 | Self-register with `role:admin` in body | ignored → role=user (no escalation) |
| X9 | NFR-01 check | after predict, confirm no Age/Gender/IMD row in DB (only AssessmentSummary prob/tier/age_group, age="Not stored") |
| X10 | Six repeated bad logins for same identifier/IP | first five 401, sixth **429** with `Retry-After` |

NFR-01 DB check:
```bash
# inspect what persisted (Postgres):
psql careattend -c "select probability,risk_tier,age_group from assessment_summaries limit 5;"
# expect NO raw Age/Gender/IMD columns anywhere
```

---

## 6. Results capture template

Fill while testing — one row per test ID:

| Test ID | Role | Pass/Fail | Actual outcome | Notes |
|---|---|---|---|---|
| U2 | user | | | |
| S2 | staff | | | |
| A6 | admin | | | |
| ... | | | | |

Mark any FAIL → file as defect. Known item to confirm: predict open to `user` role (matrix note §1).

### 6.1 App/web screenshot evidence checklist

Use this checklist for the report appendix / demo evidence pack. Store captures
under `docs/screenshots/` or paste them into the submission document with
caption, date, role, and device width.

| Evidence ID | Surface | Role | Screen / action | Expected evidence |
|---|---|---|---|---|
| UX1 | Flutter app | admin | Admin tab → Login Session Log | Login/logout rows visible; no content hidden behind bottom nav |
| UX2 | Web | admin | Admin tab → Login Session Log | Same login/logout events visible as app |
| UX3 | Flutter app | admin | Bias screen | Color-coded pass/warn/fail bars; readable in light/dark |
| UX4 | Flutter app | admin | Ethics screen | Colorful metrics/cards; no black-and-white graph issue |
| UX5 | Flutter app | staff/admin | Results screen after prediction | Risk card, SHAP, interventions, chatbot/button area not hidden by nav |
| UX6 | Flutter web desktop | any | Hover over an `AppCard` with mouse | Card lifts/shadow/border change visibly |
| UX7 | Flutter mobile/emulator | any | Tap an `AppCard` | Press feedback appears; true hover is not expected on touch |
| UX8 | Web | staff/admin | Results export row | PDF/CSV/JSON/print controls visible and operable |
| UX9 | Flutter app 320-390px width | any | Bottom navigation | Labels fit; body content remains above nav |

### 6.2 Admin session-log curl evidence

```bash
# create login_success
TOKEN_ADMIN=$(curl -s -XPOST localhost:5000/auth/login -H 'Content-Type: application/json' \
  -d '{"username":"admin1","password":"Admin#2026pw"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])')  # pragma: allowlist secret

# create logout
curl -s -XPOST localhost:5000/auth/logout -H "Authorization: Bearer $TOKEN_ADMIN"

# inspect both rows
TOKEN_ADMIN=$(curl -s -XPOST localhost:5000/auth/login -H 'Content-Type: application/json' \
  -d '{"username":"admin1","password":"Admin#2026pw"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])')  # pragma: allowlist secret
curl -s localhost:5000/api/audit-log -H "Authorization: Bearer $TOKEN_ADMIN" \
  | python3 -m json.tool
# expect rows with action = login_success and logout, username, ipAddress, createdAt
```

---

## 7. Headless run results — 2026-06-24 (v1.2.0, fresh server)

Automated curl harness, all 3 roles seeded (admin via CLI, staff via approval, user unapproved).

**30 / 30 functional + role-gate checks PASS.** Backend `pytest`: **234 passed**.

| Group | Result |
|---|---|
| User: predict ✓, profile ✓, dashboard/bias DENY 403 ✓ | PASS |
| Staff: predict, dashboard, outcomes, EHR, clinic-list, trusts, notifications, actions, carer, feedback-summary, nudge ✓; bias/admin DENY 403 ✓ | PASS |
| Admin: bias-audit, model-info, model-comparison, ethics, audit-log, pending-users, approve, predict ✓ | PASS |
| Negative: no-token 401, missing-field 400, bad-range 400, weak-pw 400, no-escalation 403 | PASS |

**Confirmed working:** role gates exactly match §1 matrix; staff approval flow; multilingual nudge (Urdu verified); calibrated model; validation; no privilege escalation.

**Defects found & FIXED this run:**
1. **SHAP returned top-5, AC = top-3** (FR-03 / US-004). Was `[:5]` backend + `slice(0,5)` web + `.take(5)` app — all three returned/showed 5 factors. Fixed → top-3 everywhere; test tightened to `== 3`; live verified `shap count: 3`.
2. `model_used` mislabel "Random Forest" → real "Logistic Regression (calibrated)" (fixed earlier this session).

**Confirmed-by-design (not a bug, flag for AT4):** `/api/predict` is `@token_required` only → an unapproved `user` can run predictions. If undesired, add `@role_required("staff","admin")`.

**Harness false-alarms (server/script, not app):** first run hit a 28h-stale server (old binary) → restart fixed; pending-users JSON key is `pending` not `users` (script fixed); nudge needs `{"patient":{...},"language"}` body (script fixed).
