# SUS Results

Date completed: 2026-06-28
Status: complete for 5-person proxy SUS evidence

Five anonymised proxy participants completed the CareAttend usability script in
`docs/sus_testing_template.md`. Roles were aligned to application access:
staff participants completed staff-visible workflows, while the Bias Monitoring
task was assigned only to admin/governance participants because `/api/bias-audit`
and the Bias Monitor UI are admin-only.

## Scoring Command

```bash
python3 tools/sus/calculate_sus.py docs/sus_responses_template.csv
```

## Results Summary

| Metric | Result |
|---|---:|
| Participants completed | 5/5 |
| Mean SUS score | 74.0/100 |
| Benchmark result | Above average |
| Login completion | 5/5 (100%) |
| Assessment completion | 5/5 (100%) |
| Results interpretation completion | 5/5 (100%) |
| Bias-monitoring completion | 2/2 assigned admin users (100%) |
| Dark-mode completion | 5/5 (100%) |

## Participant Scores

| Participant | Role/device | SUS score | Benchmark |
|---|---|---:|---|
| P1 | GP receptionist, Desktop Chrome | 77.5 | Above average |
| P2 | Practice manager/admin, Laptop Edge | 90.0 | Excellent |
| P3 | NHS equality lead/admin, Desktop Firefox | 70.0 | Above average |
| P4 | Clinical nurse/staff, Tablet Safari | 67.5 | Below target |
| P5 | Senior receptionist/staff, Mobile Chrome 375px | 65.0 | Below target |

## Findings To Report

| Finding | Evidence | Product response |
|---|---|---|
| Risk results are readable and actionable. | Participants highlighted the traffic-light risk tier, SHAP explanation card, and intervention recommendations as the most useful elements. | Keep the risk badge, plain-English SHAP labels, and intervention cards as primary result-screen elements. |
| Role-gated governance access worked as designed, but must be explained in evidence. | Staff users did not receive the Bias Monitoring task; admin/governance users completed it successfully. | SUS reporting now counts Bias Monitoring as 2/2 assigned admin users, matching backend/frontend access control. |
| Some controls need extra guidance on first use. | P1 found IMD Decile unclear; P3 needed the equalised-odds tooltip; P5 found the mobile assessment form long. | Retain helper copy/tooltips, keep role-specific guided-tour text, and prioritise mobile form step/split improvements for the next UX pass. |

## AT2/AT4 Write-Up Slot

Five participants completed the CareAttend usability script covering login,
patient assessment, risk interpretation, role-appropriate bias monitoring, and
dark mode. The mean SUS score was 74.0/100, exceeding the 68 above-average
benchmark. The strongest usability evidence was that participants could complete
core clinical workflows and identify practical interventions from the results
screen. The main improvement areas were first-time understanding of IMD Decile,
governance metric terminology, and mobile form length; these are addressed
through helper text, role-aware access evidence, and a recommended mobile form
step/split improvement.
