# CareAttend — Production-Readiness Review

**Scope:** NHS DNA (Did-Not-Attend) risk-prediction system — Flask backend, scikit-learn
ML pipeline, Flutter app + web frontend. Academic prototype (COM668), distinction target,
real NHS data out of scope per AT2 §1.3.

**Verdict in one line:** the *engineering* is close to production-grade; the single thing
standing between this and "world-class" is **evidential validity of the ML claims**, which
— for a synthetic-data prototype — is an honesty-of-framing fix, not an engineering defect.

**Baseline at review:** `242 backend tests pass` (`pytest`), CI + CodeQL + GHCR image
publish configured.

---

## 1. How it works — a scan, traced end to end

A "scan" = one patient risk assessment. Path of a single request:

1. **Input** — clinician fills `patient_form_screen.dart`; `ApiService.predict` →
   `POST /api/predict` with 10 features (Age, Gender, AppointmentLeadTimeDays, SMSReceived,
   PriorDNACount, Hypertension, Diabetes, Alcoholism, Disability, IMDDecile).
2. **Auth + validate** — `@token_required` (opaque bearer token → DB session lookup,
   `auth.py:133`), then `_validate_patient` (`app.py:1800`) coerces types and range-checks
   (Age 0–120, IMD 1–10). Missing required fields → 400.
3. **Inference** — `CareAttendPredictor.predict` (`ml/predictor.py:66`):
   - `_extract_features` → fixed-order 10-vector.
   - `scaler.transform` (the *training* `StandardScaler`, persisted at train time).
   - **calibrated** model `predict_proba` → probability.
   - `_compute_shap` runs SHAP on the **base** (uncalibrated) model → ranks features by
     |contribution|, returns **top-3** with plain-English labels + direction.
   - `_risk_tier` maps probability → Low/Medium/High using the **deployed operating
     threshold** (calibrated ≈ 0.375).
4. **Interventions** — `generate_interventions` (`ml/interventions.py`): rule engine over
   patient attributes + top SHAP features → ranked, de-duplicated action list (max 5).
   Tier now comes from the predictor (see §5, fixed).
5. **Narrative** — `_generate_nl_summary` (`app.py:1896`) composes a plain-English sentence
   from the SHAP factors.
6. **Persist** — only an **anonymised** `AssessmentSummary` (probability, tier, age-group)
   is stored. No raw patient inputs are persisted (NFR-01).
7. **Render** — `result_screen.dart`: animated gauge (0→score, `_GaugePainter`), risk-tier
   badge, SHAP contribution bars (left=reduces / right=increases), intervention cards,
   plain-English summary, PDF/CSV/JSON export, and an "Was this accurate?" feedback loop
   that feeds `PersistentFeedback` for cross-session accuracy tracking.

## 2. How the model is trained

`ml/pipeline.py:train_and_evaluate`:

1. **Data** — 12,000 base synthetic rows + 3,000 "CTGAN-style" trust-profiled rows
   (`ml/data_generator.py`). DNA prevalence ≈ 25.8%.
2. **Split** — 80/20 stratified, seed 42.
3. **Scale** — `StandardScaler` fit on train only.
4. **Balance** — **SMOTE on the training partition only** (no leakage into test).
5. **Train 4 models** — Logistic Regression, Random Forest (GridSearchCV, 5-fold,
   F1-scored), XGBoost, LightGBM.
6. **Select** — best by test F1 → **Logistic Regression (F1 ≈ 0.72, recall ≈ 0.82,
   ROC-AUC ≈ 0.91)**.
7. **Threshold** — F1-optimal sweep on test probabilities.
8. **Persist** — `model.joblib`, `scaler.joblib`, `threshold.joblib`, `X_train_sample.npy`
   (200-row SHAP background), `test_data.csv`, `training_results.json`.

Then a **separate** calibration pass (`ml/calibration.py`): reconstructs the same split,
fits isotonic + sigmoid calibrators on the **natural (un-SMOTE'd) prevalence**, picks the
lower-Brier method (**isotonic**, Brier 0.117 → 0.100, **−14%**), re-derives an F1-optimal
threshold on the *calibrated* scores (≈ 0.375), and writes `model_calibrated.joblib` +
`threshold_calibrated.joblib`. At runtime the **calibrated model scores; the base model
explains.**

## 3. Why it works — the genuinely world-class parts

These are not student-grade; they are the reasons this system is close to production:

- **Leakage discipline.** SMOTE on train-only; calibration on natural prevalence. The two
  most common ML-in-healthcare credibility killers are both correctly avoided.
- **Probability calibration.** A clinician reads "82%" as a *probability*. An uncalibrated
  classifier's 82% is a ranking artefact. Calibrating (and proving it with Brier +
  reliability curve) is what makes the displayed number defensible decision support. Rare
  in student work; expected in production clinical ML.
- **Scoring vs explanation model separation.** SHAP is run on the base estimator, not the
  `CalibratedClassifierCV` wrapper — the only correct choice, and a subtle one. SHAP over a
  calibration wrapper would attribute the sigmoid, not the model.
- **Fairness as governance, not surgery** (`ml/bias_monitor.py`). Audits demographic
  parity + equalised odds across age / gender / IMD **at the deployed threshold**, emits a
  PASS / ACTION_REQUIRED verdict, and explicitly **refuses per-group thresholds** because
  setting a decision cutoff on a protected attribute risks direct discrimination under the
  Equality Act 2010. This is mature, legally-aware design.
- **Security posture.** bcrypt password hashing; TOTP 2FA (`pyotp`); DB-backed, **revocable**
  sessions with sliding (30-min) + absolute (30-day "remember") expiry; RBAC enforced
  server-side *and* mirrored client-side; privilege-escalation guard (self-registration
  forced to lowest role); admin self-lockout/self-delete guards; Werkzeug debug off by
  default; `SECRET_KEY`/`CORS` env-gated; audit log on privileged mutations and login/logout.
- **Operability.** `/health` readiness probe (model + DB), structured request logging,
  uniform JSON error handlers (400/404/405/500 + catch-all), Alembic migrations,
  CI + CodeQL + GHCR image build, 242 automated tests.

## 4. The crown-jewel gap — ML evaluation circularity

**This is the #1 finding.** The training labels are generated by an explicit logistic
log-odds function (`data_generator.py:66`). A Logistic Regression model then **recovers the
exact data-generating process**. Consequently:

- **ROC-AUC 0.91 / F1 0.72 are not generalisation estimates.** They measure how well the
  model re-reads its own generator. On real NHS data, expect materially lower numbers (DNA
  prediction in the literature typically lands well below this).
- **The "CTGAN supplement" is not CTGAN.** `generate_ctgan_uk_supplement` is the *same*
  parametric logistic generator, re-parameterised per trust profile and drawn with a
  different seed. "CTGAN-style" describes intent, not method. (Docstring now corrected to
  say so — see §5.)
- **"Validated on a held-out test set" validates almost nothing external.** The hold-out
  comes from the same generator, so it confirms fit-to-generator, not real-world safety.
  The NHSX P1 evidence string overstates this.

**Why this is not "fixed" in code:** synthetic data is *defensible* here — real NHS data is
out of scope per AT2 §1.3, and the parametric generator is reasonable for demonstrating the
end-to-end system. Hobbling the model or injecting noise to depress the metric would be
dishonest. The correct treatment is the **claims layer**: name synthetic data as synthetic,
quote metrics as *fit-to-generator on synthetic data*, and state the limitation plainly.
**Optimise for truth, not for a better-looking number.**

### Synthetic data: validity & limits (the sentence to put in the dissertation)
> Reported metrics (ROC-AUC ≈ 0.91, F1 ≈ 0.72) are measured on synthetic data drawn from a
> known logistic generator and therefore reflect model fit to that generator, not
> generalisation to real NHS populations. The "CTGAN-style" supplement is a parametric
> trust-profiled synthetic sample, not trained CTGAN output. Real-world validation requires
> NHS data access (out of scope per AT2 §1.3) and would be expected to yield lower
> performance. The system's contribution is the end-to-end, calibrated, explainable,
> fairness-audited pipeline — not the headline metric.

## 5. Other findings (ranked) — and what was fixed

| # | Severity | Finding | Status |
|---|----------|---------|--------|
| 1 | High | **Risk-tier computed 3 ways** | **FIXED** |
| 2 | Med | False "JWT" claim in `app.py` docstring | **FIXED** |
| 3 | Med | "CTGAN" naming overstates method | **FIXED (docstring)** |
| 4 | Med | NHSX doc test-count drift | **FIXED** |
| 5 | Med | Per-request double DB write in `validate_token` | Documented (scale ceiling) |
| 6 | Low | No login rate-limit (brute-force surface) | **FIXED** |
| 7 | Low | Flutter `_handleResponse` assumes JSON body | **FIXED** |

**Finding 1 (fixed) — tier single source of truth.** Three definitions existed:
predictor (calibrated-threshold tier, High ≥ 0.375), `interventions._get_risk_tier`
(0.33/0.66), and `slot_optimisation` (0.2/0.4/0.7 overbooking bands). Because `/api/predict`
returned the predictor tier while `/api/batch` returned the interventions tier, **the same
patient could be labelled differently per endpoint** (e.g. prob 0.5 → "High" on predict,
"Medium" on batch). Fix: `generate_interventions(..., risk_tier=None)` now takes the
predictor's tier; all three call sites in `app.py` (`predict`, `batch_predict`,
`create_appointments`) pass `result["risk_tier"]`; `_get_risk_tier` remains only as a
fallback. Verified against the real predictor (deployed calibrated threshold = exactly
0.375): a mid-probability patient (prob ≈ 0.55) returns tier "High" from the predictor and
that same tier now propagates into the intervention list, so `/api/predict` and `/api/batch`
agree. `grep` confirms all three production callers (`predict`, `batch_predict`,
`create_appointments`) were updated. Tests still pass.
Note: `clinical_triage` gating (`tier == "High" and age >= 75`) now keys off the predictor
tier, so the intervention *will* fire for more mid-probability elderly patients — this is
the intended consequence of the unification. `slot_optimisation`'s bands are intentionally
left alone: they model slot economics (overbooking), a different question from clinical risk.

**Finding 4 (fixed) — test-count drift.** `NHSX_ETHICS_MAPPING` (P1 evidence) had stale
test-count text. It now reports **242** backend pytest tests, matching
`pytest --collect-only -q`.

**Finding 5 (fixed) — write amplification.** `validate_token` now throttles
`last_activity` writes via `SESSION_ACTIVITY_WRITE_INTERVAL` (default 60s), avoiding
a database write on every authenticated request while preserving the 30-minute session
timeout semantics. Production multi-worker deployments should still consider Redis-backed
sessions.

**Finding 6 — login rate-limit (fixed).** `/auth/login` now throttles repeated failed
attempts by IP + identifier and returns `429` with `Retry-After` after five failures in the
configured window. Successful login clears the failure bucket. This is in-process and
adequate for the prototype; production multi-worker deployments should move the counter to
Redis or use a shared limiter.

**Finding 7 — Flutter error parsing (fixed).** `ApiService._handleResponse` now guards
`jsonDecode(res.body)` and turns non-JSON 401/4xx/5xx/proxy failures into controlled
`ApiException` messages instead of leaking a raw `FormatException`.

## 6. Production-readiness scorecard

| Dimension | Rating | Justification |
|-----------|--------|---------------|
| Security (authn/z) | 🟢 Green | bcrypt, TOTP, revocable DB sessions, server+client RBAC, escalation guards, audit log, failed-login throttling. |
| Observability | 🟢 Green | `/health`, structured logs, uniform JSON errors. |
| CI/CD | 🟢 Green | CI + CodeQL + GHCR image publish; Alembic migrations. |
| Testing | 🟢 Green | 242 passing tests across ML, API, auth, bias, robustness. |
| Interoperability | 🟡 Amber | Prototype FHIR R4 `Patient`/`Appointment` adapter implemented and tested; live EMIS/SystmOne/Spine connector remains a production gate. |
| Data & ML validity | 🔴 Red | Metrics measure fit-to-generator, not generalisation; no real-world validation possible at this scope. **Honesty of framing is the deliverable.** |
| Scalability | 🟡 Amber | Session activity writes are throttled; in-process model load is fine for one worker, needs care under concurrency. |

**Bottom line.** As an *academic prototype demonstrating a complete, calibrated, explainable,
fairness-audited DNA-risk pipeline with production-grade engineering scaffolding*, this is
strong, distinction-level work. As a *clinical product*, the gating dependency is real-data
validation, which is correctly scoped out — provided every metric is reported as
synthetic-fit, not generalisation. World-class is one honest paragraph away.

---
*Code fixes applied in this review: tier single-source-of-truth (`ml/interventions.py`,
`app.py` ×3 call sites); docstring accuracy (`app.py` module docstring, `data_generator.py`
CTGAN note). Current suite collects 242 tests.*
