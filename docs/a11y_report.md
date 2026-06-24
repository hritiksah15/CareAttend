# Accessibility Report — WCAG 2.2 (NFR-03, partial)

**Scope of this document:** automated accessibility evidence for the CareAttend
web client. This is the *automated* half of NFR-03 (usability / accessibility);
the human half — a System Usability Scale (SUS) study with real users — is
tracked separately in `docs/sus_testing_template.md` and cannot be replaced by an
automated scan.

## Standard and method

- **Standard:** WCAG 2.0 / 2.1 / **2.2**, Level **A + AA**
  (axe tags `wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa`).
- **Tool:** [axe-core](https://github.com/dequelabs/axe-core) 4.12 driven by
  Playwright (headless Chromium). A real browser is used deliberately so that
  **colour-contrast** and layout-dependent rules are actually evaluated — static
  HTML/jsdom scanners silently skip both.
- **Harness:** `tools/a11y/axe_scan.mjs` + `tools/a11y/run_scan.sh`
  (repeatable; boots the app on a throwaway SQLite DB and tears it down). See
  `tools/a11y/README.md`.
- **Views scanned** (the views that actually contain the application), in **both
  light and dark themes** — dark mode is where contrast regressions hide and the
  project explicitly claims dark-mode support:
  - `landing` — login / register / password-reset screen (unauthenticated)
  - `assessment` — authenticated main app (prediction input form)
  - `results` — risk-result view, rendered after running a real prediction

CSS animations/transitions are frozen before each scan so axe measures final
rendered colours rather than blended mid-fade frames (an un-frozen scan produced
~30 spurious "1.02:1" contrast hits on the fade-in results card; freezing
removed all of them, leaving only genuine, stable issues).

## Result

**Final state: 0 violations across all 6 view/theme combinations.**

| View         | Light | Dark |
|--------------|:-----:|:----:|
| `landing`    |   0   |  0   |
| `assessment` |   0   |  0   |
| `results`    |   0   |  0   |

This is a genuine zero from a thorough scan, not an artefact of scanning too
little: the initial run surfaced real defects (below), which were fixed in the
same change set, after which the scan was re-run to confirm.

### Defects found and fixed

The first stable scan reported **9 colour-contrast failures** (WCAG 2.2 SC 1.4.3,
Level AA, 4.5:1 for normal text), all traced to three root causes in
`frontend/css/style.css`:

| # | Element(s) | Before | After | Fix |
|---|------------|:------:|:-----:|-----|
| 1 | Primary buttons in dark mode (`.btn-primary`) | 4.24:1 (white on `#4a7bc7`) | 5.15:1 | Darkened dark-mode button blue to `#3a6cbf` |
| 2 | Field hints (`.field-hint`, e.g. "0 – 120 years") | 1.94:1 light / 2.61:1 dark | 5.27:1 / 6.05:1 | Hint colour `#5a6b78`; added dark-mode override `#9aa6b0` |
| 3 | Session-timer text (`#session-countdown` on blue header) | 3.97:1 | 6.94:1 | Timer text colour `#e8eef5` |

The fixes preserve the existing visual hierarchy (hints/timer still read as
secondary text) and were checked against rendered screenshots in both themes to
confirm no layout or colour regression.

## Coverage and limitations (honest scope)

- **Automated ≠ complete.** axe-core reliably catches contrast, ARIA, labelling
  and structural issues, but cannot judge cognitive load, task flow, or whether
  the language is clear to a clinician. That is what the **SUS study** is for —
  this report does not close NFR-03 on its own.
- **Views not scanned automatically:** secondary tabs (dashboard, clinic list,
  batch upload, bias audit, admin) and modal flows are not yet in the scan loop.
  The three scanned views cover the core prediction journey; extending the loop
  to the remaining tabs is a straightforward follow-up.
- **Canvas content** (the risk gauge and SHAP chart are `<canvas>`) is not
  introspectable by axe; their textual equivalents (percentage, tier badge,
  SHAP legend) are present in the DOM and are covered.
- Scan is single-state per view; it does not exercise every error/validation
  permutation.

## Reproduce

```bash
cd tools/a11y
npm install && npx playwright install chromium
./run_scan.sh
```

Last run: 0 violations (WCAG 2.2 AA, light + dark, landing/assessment/results).
