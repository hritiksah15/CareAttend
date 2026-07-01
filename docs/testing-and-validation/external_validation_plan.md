# External Validation Plan

Status: plan and acceptance criteria. No real-world external validation is claimed.

## Objective

Validate that the CareAttend DNA risk model generalises beyond its synthetic training generator before any operational pilot. The key question is not whether the prototype works on held-out synthetic data; it is whether the calibrated probability, tiering threshold, explanations, and fairness profile remain acceptable on real appointment populations.

## Required Validation Slices

| Validation type | Dataset | Question answered |
| --- | --- | --- |
| Temporal validation | Later appointment period from the same organisation | Does performance drift over time? |
| Geographic validation | Different practice, clinic, trust, or region | Does the model generalise across populations? |
| Specialty validation | Separate clinic types | Does risk behave differently by service? |
| Equity validation | Age, sex/gender, deprivation, disability where lawfully available | Are false positives/negatives unevenly distributed? |
| Workflow validation | Appointments with recorded outreach actions and outcomes | Does action tracking correlate with lower DNA rates? |

## Minimum Dataset Fields

Required model fields:

- `Age`
- `Gender`
- `AppointmentLeadTimeDays`
- `SMSReceived`
- `PriorDNACount`
- `IMDDecile`

Optional model fields:

- `Hypertension`
- `Diabetes`
- `Alcoholism`
- `Disability`

Outcome field:

- Attendance outcome mapped to `attended` vs `dna`.

Governance fields:

- Appointment date, clinic/service, source organisation, extraction date, and documented missingness.

## Metrics

| Area | Metric | Gate |
| --- | --- | --- |
| Discrimination | ROC AUC, PR AUC, F1, recall, precision | Must be clinically reviewed against baseline booking rules |
| Calibration | Brier score, calibration curve, calibration slope/intercept | Probability output must be recalibrated if materially off |
| Threshold | Confusion matrix at trained threshold | Threshold must be reviewed, not blindly reused |
| Operations | DNA rate by tier, workload by tier | High/medium tier volume must be operationally manageable |
| Fairness | Demographic parity gap, equalised odds gap, false negative rate by group | Breaches trigger governance review and mitigation |
| Drift | Feature distribution and outcome-rate drift | Significant drift triggers retraining/recalibration review |

## Protocol

1. Freeze the model artifact, scaler, feature list, and threshold.
2. Extract validation data without training on it.
3. Run schema validation and missingness report.
4. Score all records using the frozen pipeline.
5. Produce performance, calibration, threshold, and fairness reports.
6. Review false positive and false negative samples with clinical/operational staff.
7. Decide whether to recalibrate, retrain, change thresholds, or reject deployment.
8. Repeat after any model, threshold, connector, or workflow change.

## Reporting Template

Each validation report should include:

- Dataset provenance and dates.
- Inclusion/exclusion criteria.
- Missing-data handling.
- Metrics with confidence intervals.
- Fairness table and governance decision.
- Threshold decision and workload impact.
- Clinical safety sign-off status.
- Deployment decision: reject, monitor-only pilot, or controlled operational pilot.

## Current Verdict

CareAttend currently has calibrated-model loading, trained-threshold use, bias audit, and operational outcome tracking. These are necessary foundations, but external validation remains a pre-production gate. The README, model card, and production review should continue to state this clearly.
