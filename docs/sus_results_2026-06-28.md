# SUS Results

Date created: 2026-06-28
Status: pending real participant responses

This file is the results placeholder for the 5-person System Usability Scale
study. Do not mark this complete with synthetic responses. The AT2/AT4 evidence
value comes from real users or realistic proxy users completing the task script
in `docs/sus_testing_template.md`.

## Required Inputs

Use `docs/sus_responses_template.csv` and collect five rows:

| Field group | Required evidence |
|---|---|
| Participant profile | Anonymous ID, role/proxy role, device used. |
| Task completion | Pass/fail and completion time for login, assessment, results interpretation, bias monitoring, and dark mode. |
| SUS scores | Q1-Q10, each scored 1-5. |
| Qualitative feedback | Most useful feature, confusing point, willingness to use, SHAP helpfulness, intervention relevance. |

## Scoring Command

After filling the CSV, run:

```bash
python3 tools/sus/calculate_sus.py docs/sus_responses_template.csv
```

The command prints:

- per-participant SUS score
- mean SUS score
- benchmark interpretation against the target of 68+
- task completion rates
- qualitative finding prompts for the report

## Results Summary

| Metric | Result |
|---|---|
| Participants completed | pending |
| Mean SUS score | pending |
| Benchmark result | pending |
| Login completion | pending |
| Assessment completion | pending |
| Results interpretation completion | pending |
| Bias-monitoring completion | pending |
| Dark-mode completion | pending |

## Findings To Report

| Finding | Evidence | Product response |
|---|---|---|
| pending | pending | pending |
| pending | pending | pending |
| pending | pending | pending |

## AT2/AT4 Write-Up Slot

Replace this paragraph after the real test:

```text
Five participants completed the CareAttend usability script covering login,
patient assessment, risk interpretation, bias monitoring, and dark mode. The
mean SUS score was [score]/100, compared with the 68 above-average benchmark.
The strongest usability evidence was [finding]. The main issue was [finding],
which was addressed by [fix/justification].
```
