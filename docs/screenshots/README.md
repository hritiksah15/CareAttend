# Screenshot Evidence Pack

Date created: 2026-06-28
Status: pending capture

This folder is the evidence pack for the UI checklist in
`docs/feature_test_plan.md`.

Automation note: Codex could not capture these screenshots in this session
because the in-app browser backend was unavailable and the browser list was
empty. Do not mark this pack complete until real screenshots are added.

## Capture Setup

Start the backend:

```bash
cd backend
./run.sh
```

Open the web client:

```text
http://127.0.0.1:5000
```

Start the Flutter web app:

```bash
cd care_attend_app
flutter run -d chrome --web-port=8090 --dart-define=API_BASE=http://127.0.0.1:5000
```

Open the Flutter client:

```text
http://localhost:8090
```

## Required Captures

| ID | Filename | Surface | Size | Required proof |
|---|---|---|---|---|
| UX1 | `UX1_flutter_admin_session_log_390.png` | Flutter app | 390 x 844 | Admin Login Session Log rows visible; content not hidden by bottom nav. |
| UX2 | `UX2_web_admin_session_log_1440.png` | Web app | 1440 x 900 | Same login/logout events visible in web admin view. |
| UX3 | `UX3_flutter_bias_390.png` | Flutter app | 390 x 844 | Bias indicators use colored pass/warn/fail styling and remain readable. |
| UX4 | `UX4_flutter_ethics_390.png` | Flutter app | 390 x 844 | Ethics metrics are colorful, systematic, and not black-and-white only. |
| UX5 | `UX5_flutter_results_390.png` | Flutter app | 390 x 844 | Risk card, SHAP, interventions, and chatbot/button area are above the nav. |
| UX6 | `UX6_flutter_hover_desktop_1440.png` | Flutter web | 1440 x 900 | Mouse hover over `AppCard` visibly changes lift, shadow, and border. |
| UX7 | `UX7_flutter_touch_feedback_390.png` | Flutter mobile/emulated | 390 x 844 | Tap/press feedback is visible; true hover is not expected on touch devices. |
| UX8 | `UX8_web_results_export_1440.png` | Web app | 1440 x 900 | PDF/CSV/JSON/print export controls are visible and usable. |
| UX9 | `UX9_flutter_bottom_nav_320.png` | Flutter app | 320 x 800 | Bottom navigation labels fit and page content remains above the nav. |

## Acceptance Rules

- Every image must show the full viewport, not a cropped widget.
- Include at least one desktop capture and at least one narrow mobile capture.
- Use fresh login/logout rows generated on the same day as capture.
- If a screen requires seeded data, record the role and account used in the
  submission appendix.
- If an expected control is below the fold, capture the relevant scrolled state
  and make sure the bottom navigation does not cover it.

## Sign-Off Table

| ID | Captured | Pass/fail | Notes |
|---|---|---|---|
| UX1 | no | pending | Browser capture unavailable in Codex session. |
| UX2 | no | pending | Browser capture unavailable in Codex session. |
| UX3 | no | pending | Browser capture unavailable in Codex session. |
| UX4 | no | pending | Browser capture unavailable in Codex session. |
| UX5 | no | pending | Browser capture unavailable in Codex session. |
| UX6 | no | pending | Browser capture unavailable in Codex session. |
| UX7 | no | pending | Browser capture unavailable in Codex session. |
| UX8 | no | pending | Browser capture unavailable in Codex session. |
| UX9 | no | pending | Browser capture unavailable in Codex session. |
