# System Usability Scale (SUS) Testing Template

## Overview
Target: SUS >= 68 (above-average usability threshold per Lewis, 2024)
Aligned to: NFR-03, FR-01, US-001 (Asha Patel persona)

## Pre-Test Setup
1. Deploy Care Attend on localhost or accessible device
2. Create test account for participant
3. Prepare test scenario card (below)
4. Record completion times for each task

## Test Scenario Card

**Participant Role:** NHS GP Receptionist (or equivalent)

### Task 1: Login (target: < 30 seconds)
"Log into Care Attend using the provided credentials."

### Task 2: Patient Assessment (target: < 60 seconds)
"Enter the following patient details and submit a risk assessment:
- Age: 78, Female, IMD Decile: 2
- Lead time: 14 days, Prior DNAs: 4, No SMS sent
- Hypertension: Yes, Diabetes: No"

### Task 3: Interpret Results
"Look at the risk dashboard and tell me:
- What is the patient's risk level?
- What are the top two reasons for this score?
- What intervention would you prioritise?"

### Task 4: Bias Monitoring
"Navigate to the Bias Monitor and run an audit. Does the model show any fairness concerns?"

### Task 5: Dark Mode
"Switch the application to dark mode."

## SUS Questionnaire (Brooke, 1996)

Rate each statement 1 (Strongly Disagree) to 5 (Strongly Agree):

| # | Statement | Score (1-5) |
|---|-----------|-------------|
| 1 | I think that I would like to use this system frequently | |
| 2 | I found the system unnecessarily complex | |
| 3 | I thought the system was easy to use | |
| 4 | I think I would need the support of a technical person | |
| 5 | I found the various functions well integrated | |
| 6 | I thought there was too much inconsistency | |
| 7 | I imagine most people would learn to use this system quickly | |
| 8 | I found the system very cumbersome to use | |
| 9 | I felt very confident using the system | |
| 10 | I needed to learn a lot before I could get going | |

## SUS Scoring Formula
For odd items (1,3,5,7,9): score - 1
For even items (2,4,6,8,10): 5 - score
Sum all adjusted scores, multiply by 2.5
Result: 0-100 scale

## Post-Test Questions (Qualitative)
1. "What was the most useful feature?"
2. "What was confusing or difficult?"
3. "Would you use this in your daily workflow? Why/why not?"
4. "Were the SHAP explanations helpful for understanding the risk score?"
5. "Were the intervention recommendations relevant and actionable?"

## Participant Recruitment
Even 2-3 informal participants add significant weight:
- NHS admin staff (ideal)
- Healthcare students
- Practice managers
- Anyone in admin/reception role at a GP surgery

Document consent: "Participation is voluntary. No patient data is used. Responses are anonymised."

## Reporting for AT4
Include in Quality Assurance section:
- SUS composite score
- Task completion rates and times
- Key qualitative findings
- Comparison to industry benchmark (68 = above average)

## Response Sheet And Calculator
Use `docs/sus_responses_template.csv` for the five anonymised participant rows.
After collecting real responses, calculate the score with:

```bash
python3 tools/sus/calculate_sus.py docs/sus_responses_template.csv
```

Record the final score and top findings in
`docs/sus_results_2026-06-28.md`.
