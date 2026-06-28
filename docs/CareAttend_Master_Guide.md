# CareAttend — Master Guide

**Owner:** Hritik Kumar Sah (B00923557) · Ulster University COM668
**Purpose of this file:** One place that answers *what the app is, why it helps, what must be in it, how AT2 is marked, how it compares to real products, and the exact step-by-step path to make it a top-notch real NHS app.*
**Last updated:** June 2026

---

## PART 0 — Read this first (the "why" in plain English)

### The real-world problem
Every year the NHS loses an estimated **£216 million** and around **15 million wasted GP/hospital appointments** to **DNAs ("Did Not Attend")** — patients who miss appointments without cancelling. A missed slot is a slot a sick person could have used. The patients **most likely** to miss are often the **most vulnerable**: elderly, low digital literacy, deprived areas (high IMD), no transport, mental health needs, language barriers.

Current NHS reminders are **blanket** — everyone gets the same SMS. That wastes effort on patients who'd attend anyway and under-helps the ones who genuinely struggle.

### What CareAttend actually does (the job-to-be-done)
> **CareAttend tells front-desk NHS staff, *before* an appointment, which patients are at high risk of not showing up — AND why — so staff can act (phone call, transport help, carer reminder, interpreter) on the few patients who need it instead of spamming everyone.**

It is a **decision-support tool for staff**, not a patient app and not an auto-decision system. A human always decides what to do. That framing matters legally (GDPR Art 22 — no solely-automated decisions) and clinically (DCB0129 safety).

### The 60-second user story (use this in your AT3 demo intro)
1. Reception clerk at a busy GP surgery opens CareAttend in the morning.
2. Tomorrow's appointment list loads (or she enters/looks up one patient).
3. Each patient gets a **risk score 0–100%** and a **traffic-light tier**.
4. For a high-risk patient she sees **the top 3 reasons** (e.g. "missed last 4 appts", "age 78", "lives in IMD decile 1") — this is the **SHAP explainability**.
5. She sees **suggested actions** ("phone call + arrange patient transport + carer reminder").
6. She acts on the 8 red patients, ignores the 40 green ones. DNA rate drops.
7. Behind the scenes a **bias monitor** proves the model isn't unfairly flagging by age/gender/deprivation — so the NHS can trust it.

That is the whole product. Everything else (dashboard, batch upload, multilingual nudges, 2FA, audit log) supports that loop.

### Why YOUR build is different from a normal student CRUD app
You combined **5 things no single shipping product combines**: individual risk prediction **+** SHAP "why" **+** embedded bias/fairness audit **+** vulnerability-aware features **+** staff-facing action recommendations. That combination is your thesis and your Global Talent Visa "innovation" claim. Protect it.

---

## PART 1 — The models, and WHY each one must be there

You currently train 4 models then select one. Examiners ask "why these / why this one?" Answer table:

| Model | Why it's in the project | Keep / role |
|-------|------------------------|-------------|
| **Logistic Regression (SELECTED)** | Interpretable, fast, gives calibrated probabilities, clinicians/regulators trust linear coefficients. Won on Recall+ROC-AUC after threshold tuning. | **Production model.** Auditability beats a 1% accuracy gain in healthcare. |
| **Random Forest** | Baseline non-linear, handles feature interactions, shows you tested ensembles. | Comparison only. |
| **XGBoost** | Industry-standard gradient boosting, the "would a black box do better?" test. | Comparison only. |
| **LightGBM** | Faster boosting, proves you knew the modern toolset. | Comparison only. |
| **MLP (deep learning)** in `evaluation.py` | Reviewers always ask "did you try deep learning?". You did — and showed it didn't beat LR while losing interpretability. **That narrative scores critical-analysis marks.** | Critical appraisal evidence. |

**The examiner-winning sentence:** *"We deliberately selected the interpretable Logistic Regression over higher-capacity models because in a clinical decision-support context, the ability to audit and explain every prediction (DCB0129, GDPR Art 22, NHSX principle 'explainability') outweighs marginal accuracy — a justified engineering trade-off, not a limitation."*

### ML production status and remaining gates
- **Probability calibration:** complete. `ml/calibration.py` fits sigmoid/isotonic calibration, saves `model_calibrated.joblib`, re-derives `threshold_calibrated.joblib`, and records Brier/reliability evidence in `docs/model_card.md`.
- **Model card:** complete in `docs/model_card.md`.
- **Fairness governance:** complete for monitoring. `ml/bias_monitor.py` returns PASS/ACTION_REQUIRED governance verdicts, recommended review actions, and audit-log entries. Model-level mitigation such as reweighing remains a production research gate because it requires retraining, recalibration, threshold re-derivation, and re-audit.
- **Temporal/geographic validation:** protocol documented in `docs/external_validation_plan.md`; real external validation still requires representative NHS datasets.

---

## PART 2 — AT2 Report (45%) handled against the rubric matrix

AT2 = **Challenge Definition Report**. It is the single biggest chunk of marks. Below is every criterion, its weight, what the marker wants, your current evidence, and the **gap to close for a distinction (80%+)**.

| Criterion | Weight | What marker rewards | You already have | **Gap → distinction** |
|-----------|:--:|---------------------|------------------|------------------------|
| **Problem Definition** | 20% | Clear aim, justified scope, SMART objectives, MoSCoW Won't-Haves | Aim, 7 SMART objectives→sprints, scope bounded by GDPR/NHS | Add a quantified **problem-impact paragraph** (£216M, 15M appts, cite NHS Digital). Make each objective measurably testable. |
| **Context Investigation** | 20% | Lit review with synthesis (not summary), legal/ethical/social context, competitor analysis | Carreras-García, Mohammadi, Caton & Haas, Lundberg; 4-product table; GDPR Art 5 | **Synthesise, don't list.** Add Nelson (2019), Obermeyer (2019 — racial bias in health algorithms, *the* citation), Harris (2016). Add a **"gap in literature" paragraph** that your project fills. |
| **Software Definition** | 40% | Requirements (MoSCoW), UML, ERD, architecture, testing strategy — all **traceable** to objectives | 9 FR + 6 NFR, 12 user stories, 9 UML diagrams, ERD, 6-level test method | Add a **traceability matrix** (objective → requirement → test). This single table is what separates 70 from 85. Ensure every diagram is *referenced in the prose*, not just dumped. |
| **Planning** | 15% | Agile justified vs alternatives, sprint plan, Gantt, **risk register with scoring** | 6 sprints, Gantt, Trello, 8 risks (ISO 31000), Agile-vs-Waterfall justification | Add **deviation log** ("planned X, actually did Y, because…") — markers love honest reflection. |
| **Communication** | 5% | Academic tone, Harvard referencing, captioned figures, structure | 17 references, captioned tables | Get to **20+ quality refs** (IEEE/BMJ/Lancet Digital Health). Consistent caption style. One proofread pass. |

### The 40% bucket is where you win or lose — priority order
1. **Traceability matrix** (objective ↔ FR/NFR ↔ UML ↔ test). Highest ROI.
2. Architecture diagram (C4 model: Context → Container → Component).
3. ERD matches the *actual* PostgreSQL schema (you have `users, sessions, audit_logs, feedback, carer_proxies`). Verify diagram == reality.
4. Testing methodology described as a **strategy** (unit → integration → ML validation → bias → UAT/SUS → security), each level justified.

### Distinction-level differentiators (the 5% that pushes 78→85)
- **Critical analysis voice** throughout: every design choice states *the alternative you rejected and why*.
- **Ethics not bolted on**: bias audit + NHSX 6 principles woven into requirements, not an appendix.
- **Evidence-backed**: claims cite sources; numbers cite data.

---

## PART 3 — Competitor comparison (use in AT2 Context + Visa "innovation")

| Product | What it does | Risk prediction | Explains "why" (SHAP) | Bias/fairness audit | Vulnerability-aware | Staff action support | Open / auditable |
|---------|--------------|:--:|:--:|:--:|:--:|:--:|:--:|
| **Accurx** | Messaging/SMS to patients | ✗ | ✗ | ✗ | ✗ | partial | ✗ |
| **DrDoctor** | Appointment mgmt + reminders, has some DNA modelling | ✓ (black box) | ✗ | ✗ | ✗ | partial | ✗ |
| **Netcall / Patient Hub** | Reminder + booking | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| **NHS App / BSA** | Patient-facing booking/records | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| **Plain SMS reminders (status quo)** | Blanket reminders | ✗ | ✗ | ✗ | ✗ | ✗ | n/a |
| **CareAttend (you)** | Staff decision support | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

**The one-line claim (defensible):** *"DrDoctor is the closest competitor but operates as a black box with no fairness auditing or per-patient explanation. CareAttend is the only tool pairing individual DNA risk with transparent, bias-audited, action-oriented decision support for front-line staff."*
Caveat to state honestly in your report: those products are **production systems with real NHS data**; yours is a **research prototype on synthetic data**. Saying this *gains* marks (critical honesty), it doesn't lose them.

---

## PART 4 — From prototype to TOP-NOTCH real app (the build roadmap)

Two tracks. **Track A** = things that raise your COM668 grade now (do before AT3/AT4). **Track B** = things that make it a real shippable NHS product (do after, for the Visa/startup).

### TRACK A — grade-raising, do now (each is small, high-impact)

| # | Build | Why it scores | Effort | Files |
|--|-------|--------------|:--:|-------|
| A1 | **Automated tests for the new endpoints** (carer proxy, slots, nudge, 2FA, audit) | Memory says these are only manually tested. QA marks (AT4 800w) + NFR evidence. | M | `backend/tests/` |
| A2 | **Traceability matrix** doc | Directly targets AT2 40% bucket | S | `docs/traceability_matrix.md` |
| A3 | **Model card + probability calibration** | "Production-grade" signal, cheap | M | `ml/pipeline.py`, `docs/model_card.md` |
| A4 | **C4 architecture diagram** (Mermaid) | AT2 design marks | S | `docs/architecture.md` |
| A5 | **SUS usability test** (5 users) + write-up | AT4 QA section needs a real number | M | `docs/sus_testing_template.md` |
| A6 | **Health-check + structured logging + error handling** audit | Robustness = NFR evidence | S | `app.py` |
| A7 | **OpenAPI/Swagger spec** for the REST API | Professional, demoable | M | `docs/openapi.yaml` |

### TRACK B — real-world product hardening (post-submission, for Visa/startup)

| Phase | Build | Real-world gate it satisfies |
|-------|-------|------------------------------|
| B1 | **FHIR R4 compliance** (model patients/appointments as FHIR resources) | Prototype adapter implemented; live connector conformance remains mandatory for NHS interoperability |
| B2 | **Real EMIS/SystmOne + NHS Spine (PDS)** connectors replacing mock EHR | Live data |
| B3 | **DCB0129 Clinical Safety Case** + **DPIA** (GDPR Art 35) | Legally required before any NHS deployment |
| B4 | **NHS IG Toolkit / DSPT** registration; **DARS** data application | Access to real data |
| B5 | **Fairness *mitigation*** (fairlearn reweighing), temporal + geographic external validation | Trust on real demographics |
| B6 | **Pen test (OWASP Top 10)** + **WCAG 2.2 AA** full audit | Security + accessibility sign-off |
| B7 | **Single-surgery pilot, A/B vs control, measure DNA reduction** → publish (BMJ Health & Care Informatics / npj Digital Medicine) | Proof of impact + Visa "recognition" |

---

## PART 5 — Step-by-step: what to build next, in order

> Rule: finish Track A before AT3 (demo, due 7 Jul). Each step has a clear "done = " test.

- [ ] **STEP 1 — Lock the narrative.** Re-read PART 0 aloud. Write your AT3 intro script (1 min) from the 60-second user story. *Done = you can explain the app to a non-technical person in 3 sentences.*
- [x] **STEP 2 — Automated tests for new endpoints (A1).** Cover carer-proxy, slot-optimiser, nudge generator, 2FA enable/verify, audit-log write. *Done = `pytest` green, test count > 90, new endpoints covered.*
- [x] **STEP 3 — Traceability matrix (A2).** One row per objective → FR/NFR → UML artefact → test id. *Done = every objective traces to a test.*
- [x] **STEP 4 — Probability calibration + model card (A3).** Wrap selected LR in `CalibratedClassifierCV`, add reliability curve, write 1-page model card. *Done = calibration plot saved, card committed.*
- [ ] **STEP 5 — C4 architecture + verified ERD (A4).** Mermaid Context+Container+Component; diff ERD against real Alembic schema. *Done = diagram matches `models.py` exactly.*
- [x] **STEP 6 — SUS usability test (A5).** 5 testers, 10-question SUS, compute score. *Done = a number (e.g. 82/100) + 3 findings.*
- [x] **STEP 7 — Robustness pass (A6).** Add `/health`, consistent JSON errors, request logging, input validation on every endpoint. *Done = no unhandled 500s on bad input.*
- [x] **STEP 8 — OpenAPI spec (A7).** Document all endpoints. *Done = spec loads in Swagger UI.*
- [ ] **STEP 9 — Record AT3 demo** following the script in `CareAttend_Project_Summary.md` §AT3.
- [ ] **STEP 10 — Write AT4** using QA evidence from steps 2–8.
- [ ] **STEP 11+ — Track B** for the real product.

---

## PART 6 — Where things live (quick map)

```
backend/app.py            REST API (all endpoints)
backend/auth.py           bcrypt + 2FA + sessions
backend/models.py         SQLAlchemy tables (source of truth for ERD)
backend/ml/pipeline.py    4-model training + selection
backend/ml/predictor.py   SHAP explainability
backend/ml/bias_monitor.py demographic parity + equalised odds
backend/ml/interventions.py action recommendations
backend/ml/evaluation.py  CV, CIs, McNemar, MLP comparison
frontend/templates/index.html  single-page web app
frontend/js/app.js        UI logic
care_attend_app/          Flutter mobile (mirrors web screens)
docs/                     this guide + supporting docs
submission 2/             AT report context + marking PDFs
```

---

## PART 7 — Decisions I need from you (so we build the right thing)
See chat — pick the first step and we start coding it now.
```
```
