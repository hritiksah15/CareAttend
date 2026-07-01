# WCAG 2.2 accessibility scan (NFR-03)

Automated accessibility audit of the CareAttend web client using **axe-core**
driven by **Playwright** (headless Chromium). A real browser is required so that
colour-contrast and layout rules are genuinely evaluated — `jsdom`/static
scanners cannot compute either.

The scan covers the views that actually contain the application, in **both light
and dark themes**:

| View         | What it exercises                                  |
|--------------|----------------------------------------------------|
| `landing`    | Login / register / password-reset screen           |
| `assessment` | Authenticated main app — prediction input form     |
| `results`    | Risk-result view, rendered after a real prediction |

Standard: **WCAG 2.0 / 2.1 / 2.2, Level A + AA**
(`wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa`).

The latest results and method writeup live in [`docs/testing-and-validation/a11y_report.md`](../../docs/testing-and-validation/a11y_report.md).

## Run

Requires Node 18+. One-off setup:

```bash
cd tools/a11y
npm install
npx playwright install chromium
```

Then, with a CareAttend server running on an isolated SQLite database and a
seeded staff user, run the scan:

```bash
./run_scan.sh
```

`run_scan.sh` boots the app on a throwaway SQLite DB (never PostgreSQL), seeds a
staff user, runs the scan, and tears the server down. To point the scan at an
already-running server instead:

```bash
A11Y_URL=http://127.0.0.1:5000 A11Y_USER=<user> A11Y_PASS=<pass> node axe_scan.mjs
```

The script exits non-zero if any violation is found, so it can gate a manual
QA workflow. It is intentionally **not** wired into required CI (a browser-based
job is not worth gating `master` on) — it is a runnable evidence artifact, the
same model as `backend/benchmark_latency.py` / `docs/testing-and-validation/perf_benchmark.md`.

## Environment variables

| Var         | Default                  | Meaning                          |
|-------------|--------------------------|----------------------------------|
| `A11Y_URL`  | `http://127.0.0.1:5055`  | Base URL of the running server   |
| `A11Y_USER` | `bench`                  | Staff username to log in with    |
| `A11Y_PASS` | `Password123!`           | Password                         |
| `A11Y_OUT`  | `./axe_results.json`     | JSON results output path         |
