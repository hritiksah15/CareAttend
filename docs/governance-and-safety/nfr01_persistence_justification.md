# NFR-01 Persistence — Deviation Justification (for AT4)

**Status:** Implementation deviates from the AT2 (§3.3.2, ERD, DFDs, NFR-01) "DB-less,
session-scoped" design. This is a deliberate Sprint-4 evolution, documented here for the
AT4 critical appraisal (objective 07, RTM verification). Argue it — do not hide it.

## What AT2 claimed
NFR-01: "All patient data handled in session-scoped memory with no persistent storage."
ERD: only `UserAccount` persisted. Framed as load-bearing UK GDPR Art 5(1)(c) constraint.

## What the code actually persists (verified `backend/models.py`)

| Table | Patient-related columns | Identifiable? |
|---|---|---|
| `users` | staff only — no patient data | No (always in ERD) |
| `sessions` | auth tokens | No |
| `audit_logs` | staff action + IP | No patient data |
| `feedback` | risk_tier, probability, outcome | No demographics |
| `assessment_summaries` | probability, risk_tier, age_group; **age = "Not stored"** | No demographics |
| `appointments` | `patient_id` label, dates, clinic, prob, tier, age_group | Pseudo-ID label |
| `notifications` | `patient_id` label, risk_tier, appt date | Pseudo-ID label |
| `outreach_actions` | `patient_id` label, action, outcome | Pseudo-ID label |
| `carer_proxies` | `carer_name`, `carer_contact`, `patient_identifier` | **YES — real PII** |

## Defensible core
The **ML prediction path honours NFR-01**: the model feature vector
(Age, Gender, IMDDecile, comorbidities) is NOT persisted by any route.
`/api/predict` writes only `AssessmentSummary` (aggregate prob/tier/age_group); raw age
is explicitly dropped (`age: "Not stored"`, models.py:275). GDPR Art 5(1)(c) data
minimisation intact for the predictive core.

## Honest residual deviation (acknowledge in AT4)
1. `carer_proxies` persists carer name + contact + patient identifier = genuine PII.
   This is the strongest divergence from "zero patient records persisted."
2. `patient_id` / `appointment` / `notification` / `outreach` rows persist a free-text
   patient label + appointment metadata. These are operational-workflow extras added
   beyond AT2 scope (appointment worklist, outreach loop, carer alerts).

## Recommended AT4 narrative
- Re-frame NFR-01 in the AT4 report: split into (a) **predictive data** — remains
  session-scoped, zero persistence (claim still holds, evidence above); and
  (b) **operational workflow data** — a Sprint-4 scope addition that required a
  persistence layer, justified by the FR-05 intervention/outreach lifecycle which is
  meaningless without durable tracking.
- State the design driver honestly: the report's no-DB model fit a pure scoring tool;
  once outreach/appointment tracking was added (extras), persistence became necessary.
- Note GDPR posture: `patient_id` is a staff-entered local reference, not a stored
  demographic record; carer contact is the one field requiring a lawful-basis note
  (Art 6) in a real deployment.

## Optional code mitigations (if you want to shrink the deviation)
- Document/enforce that `patient_id` is a pseudonymised local ref, not NHS number.
- Add a retention/purge job for appointments + carer proxies (TTL) to bound persistence.
- Move carer_contact behind explicit consent flag.
Not required for AT3 demo; raise in AT4 limitations if not done.
