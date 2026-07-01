# DPIA and DCB0129 Clinical Safety Outline

Status: academic prototype safety outline. This is not a signed DPIA or DCB0129 safety case.

## Scope

CareAttend predicts DNA risk for appointments, explains the drivers, audits fairness, and supports staff outreach actions. It is a decision-support tool. It must not be used as a solely automated clinical or administrative decision maker.

## Data Protection Impact Assessment Outline

| Area | Prototype position | Production requirement |
| --- | --- | --- |
| Purpose | Reduce missed appointments through staff-led risk review and outreach | Approved lawful basis and clinical/operational purpose |
| Data source | Synthetic training data, mock EHR records, user-entered appointment workflow | Data-sharing agreement and approved source systems |
| Data minimisation | Raw prediction inputs are not persisted; operational records store patient identifiers only where needed for appointment/action workflow | Retention schedule, pseudonymisation strategy, role-specific access |
| Special category data | Clinical flags can be entered or mocked (`Diabetes`, `Hypertension`, etc.) | Explicit Article 9 condition, DPIA sign-off, access controls |
| Transparency | Human-readable explanations, interventions, and model card | Patient/staff privacy notice and operational SOP |
| Automated decision-making | Human-in-the-loop only; no automated cancellation, booking, or denial of care | Written policy prohibiting solely automated decisions |
| Retention | Prototype database retention is environment controlled | Defined retention/deletion rules and audit archive policy |
| Access control | RBAC, admin approval, TOTP, DB-backed sessions, audit logs | NHS identity/access integration and periodic access review |
| International transfer | None in prototype | Supplier and hosting review before production |

## DCB0129 Hazard Log Outline

| Hazard | Potential harm | Existing control | Required production control |
| --- | --- | --- | --- |
| Model overestimates risk | Patient may receive unnecessary outreach or anxiety | Risk tier is advisory; explanations are visible | Clinical safety officer review, threshold approval, user training |
| Model underestimates risk | Patient may miss useful support | Staff can still act outside model output; dashboard monitors outcomes | External validation, drift monitoring, false negative review |
| Bias across demographic groups | Unequal targeting of outreach | Bias audit with governance warnings | Threshold review process, fairness mitigation, equality impact assessment |
| Stale appointment data | Staff contact wrong patient or wrong date | Appointment records include date/status and owner scope | EHR sync timestamps, connector reconciliation, data quality alerts |
| Unsupported live connector | Unauthorised data access or incorrect mapping | Prototype explicitly labels mock/FHIR adapter boundary | Approved connector, penetration test, integration test pack |
| Notification failure | Patient not reminded | Persisted notification status and dispatch result | Provider SLA, retry policy, delivery receipts, fallback workflow |
| Staff misuse of risk score | Risk score treated as a final decision | UI and docs frame the tool as decision support | SOP, audit review, training, incident reporting |

## Safety Requirements Before Live Use

1. Appoint a clinical safety officer and complete DCB0129 hazard review.
2. Complete DPIA, data-sharing agreement, retention schedule, and privacy notices.
3. Validate the model on representative temporal and geographic datasets.
4. Approve thresholds and fairness tolerances through a governance group.
5. Run penetration testing and connector security review.
6. Produce an operational SOP for action tracking, escalation, override, and incident reporting.
7. Monitor false positives, false negatives, DNA rate change, and group fairness in production.

## Current Verdict

The prototype now has the correct engineering hooks for safety governance: role-based access, audit logs, explainability, fairness audit, persisted appointment/action/outcome workflow, and documented FHIR boundaries. It is not production clinical software until the external safety, IG, and validation controls above are completed and signed.
