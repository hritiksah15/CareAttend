# Session Log — App Worldclass Pass (2026-06-27 → 28)

Branch: `app-worldclass-phase1` · Pushed: `2ffac0b..ab2cdd2` (12 commits) ·
Verified: `flutter analyze` clean (0 issues), 22 tests pass, web build OK,
live Playwright screenshots on `:8090`.

## Goal
Bring the Flutter web app (`care_attend_app/`, the AT2-graded deliverable) to a
world-class / production bar — dark-mode correctness, visual consistency,
glassmorphism on transient panels, notifications, branding, i18n, tests.

## Commits (oldest → newest)
1. `cee87d2` fix(app): repair dark-mode card/text visibility + theme foundation
   - Full dark `ColorScheme` (surface ladder scaffold<card<dialog, onSurface,
     onSurfaceVariant, surfaceContainer roles, outline); dark card/dialog
     border (`darkOutline #5A74AB`, WCAG ≥3:1); dialog/menu/sheet raised
     surface; recessed input fill. Replaced hardcoded white card helpers with
     `AppCard`; routed 56 hardcoded `darkGrey` text colours →
     `onSurfaceVariant`. Carer/Family Proxy dialog rebuilt (16px grid).
2. `1b2a4fb` fix(app): dark-mode legibility for titles, callouts + stat-card grid
   - NHS-blue text/icons/accents → `colorScheme.primary`; light pastel callout
     boxes → theme-aware `NHSTheme.calloutBg`; clinic stat tiles → responsive
     equal-width `LayoutBuilder` grid.
3. `3ad50ef` feat(app): age-vulnerability banner (65+/85+) + copy-result.
4. `9df35ed` i18n(app): localize those new strings (EN/CY/UR/PL).
5. `147d952` fix(app): intervention + nudge cards dark legibility (calloutBg).
6. `96d6aa2` feat(app): systematize nav bar (short "Assessment" label, single-
   line aligned), frosted translucent bottom bar, `AppCard` hover, 320px appbar
   (left title + hide username <360px).
7. `3856f75` feat(app): dynamic notifications + security alerts
   - `lib/state/notifications.dart` (session feed, cap 30, clear on
     logout/expiry); sources = secure sign-in, each assessment, idle warning;
     app-bar bell Badge + bottom sheet w/ Clear-all + empty state; localized.
8. `62390af` feat(app): branded boot splash + PWA metadata (no blank-white boot).
9. `114a319` test(app): Notifications unit tests; `dart fix` → analyze 0 issues.
10. `03b5949` feat(app): glassmorphism drawer + notifications (`GlassPanel`);
    removed persistent bottom-nav `BackdropFilter` (fixed per-frame
    "GPU stall due to ReadPixels").
11. `5142b25` feat(app): branded NHS-heart app/PWA icons (pure-python PNG gen).
12. `ab2cdd2` fix(app): bundle Noto Sans Arabic → Urdu renders, no Noto warning.

## Verification (live, Playwright on :8090, Hritik/Hritik@1111)
- Dark mode: patient form, Carer dialog, drawer, bias (+audit metric boxes),
  results (gauge/age-banner/SHAP/interventions/copy) — all legible, bordered.
- Responsive 320px: no overflow; appbar title visible; nav labels aligned.
- Glassmorphism: drawer + notifications frosted (content blurs behind).
- Splash: NHS-blue heart splash during boot, clears on first frame.
- Icons: branded NHS heart favicon/PWA.
- i18n: Urdu locale + native-name menu render RTL, 0 Noto warnings.
- WCAG contrast computed for every text/surface pair, both themes (text ≥4.5,
  edges ≥3.0).

## Known / environment (not code)
- `webGLVersion is -1` → browser hardware acceleration OFF → CanvasKit CPU
  paint (works, janky). Fix: enable Chrome graphics acceleration, OR deploy the
  `--wasm` (skwasm) build (verified renders) **with COOP/COEP headers** on the
  server.

## Deferred / optional next
- Motion (tab transitions) — skipped until WebGL/`--wasm` (jank under CPU).
- Golden tests; richer empty-state illustrations.
