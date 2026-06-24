/**
 * WCAG 2.2 automated accessibility scan (NFR-03) for the CareAttend web client.
 *
 * Drives a real headless Chromium with Playwright and runs axe-core against the
 * rendered DOM — a real browser is required so colour-contrast and layout rules
 * are actually evaluated (jsdom cannot do either). Scans the views that contain
 * the application, in BOTH light and dark themes, because dark mode is where
 * contrast regressions hide and the project explicitly claims dark-mode support.
 *
 * Views scanned:
 *   - landing   : unauthenticated login / register / reset screen
 *   - assessment: authenticated main app (prediction input form)
 *   - results   : authenticated risk-result view (after a prediction is run)
 *
 * Standard: WCAG 2.0/2.1/2.2 Level A + AA (tags below).
 *
 * Env:
 *   A11Y_URL   base URL of a running server (default http://127.0.0.1:5055)
 *   A11Y_USER  staff username to log in with (default bench)
 *   A11Y_PASS  password (default Password123!)
 *   A11Y_OUT   JSON output path (default ./axe_results.json)
 *
 * Usage: node axe_scan.mjs   (see run_scan.sh for the full seed+boot+scan flow)
 */

import { chromium } from "playwright";
import { AxeBuilder } from "@axe-core/playwright";
import { writeFileSync } from "node:fs";

const BASE = process.env.A11Y_URL || "http://127.0.0.1:5055";
const USER = process.env.A11Y_USER || "bench";
const PASS = process.env.A11Y_PASS || "Password123!";
const OUT = process.env.A11Y_OUT || "./axe_results.json";

const WCAG_TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];

const THEMES = ["light", "dark"];

// Set theme (and optionally an auth token) in localStorage BEFORE the app's
// scripts run, so the app boots straight into the desired state.
function initScript(theme, token, username) {
  return `(() => {
    try {
      localStorage.setItem('careattend-dark-mode', ${theme === "dark"} ? '1' : '0');
      ${token ? `localStorage.setItem('careattend_token', ${JSON.stringify(token)});` : ""}
      ${username ? `localStorage.setItem('careattend_user', ${JSON.stringify(username)});` : ""}
    } catch (e) {}
  })();`;
}

async function analyse(page) {
  // Freeze CSS animations/transitions and let the layout settle, so axe measures
  // the final rendered colours — fade-in cards otherwise produce spurious ~1.0
  // contrast ratios from blended mid-transition frames.
  await page.addStyleTag({
    content: "*,*::before,*::after{animation:none!important;transition:none!important}",
  });
  await page.waitForTimeout(350);
  const results = await new AxeBuilder({ page }).withTags(WCAG_TAGS).analyze();
  return results.violations.map((v) => ({
    id: v.id,
    impact: v.impact,
    help: v.help,
    helpUrl: v.helpUrl,
    nodes: v.nodes.length,
    detail: v.nodes.slice(0, 8).map((n) => {
      const data = (n.any.find((c) => c.id === "color-contrast") || {}).data || {};
      return {
        target: n.target.join(" "),
        fg: data.fgColor,
        bg: data.bgColor,
        ratio: data.contrastRatio,
        expected: data.expectedContrastRatio,
        fontSize: data.fontSize,
      };
    }),
  }));
}

async function login(context) {
  // Perform a real form login once to obtain a session token.
  const page = await context.newPage();
  await page.goto(BASE, { waitUntil: "networkidle" });
  await page.fill("#login-username", USER);
  await page.fill("#login-password", PASS);
  await page.click("#login-submit-btn");
  await page.waitForSelector("#main-app", { state: "visible", timeout: 15000 });
  const token = await page.evaluate(() => localStorage.getItem("careattend_token"));
  await page.close();
  if (!token) throw new Error("login did not produce a token — check credentials/seed");
  return token;
}

async function scanLanding(context, theme) {
  const page = await context.newPage();
  await page.addInitScript(initScript(theme));
  await page.goto(BASE, { waitUntil: "networkidle" });
  await page.waitForSelector("#login-screen", { state: "visible" });
  const violations = await analyse(page);
  await page.close();
  return violations;
}

async function scanAuthed(context, theme, token, withResults) {
  const page = await context.newPage();
  await page.addInitScript(initScript(theme, token, USER));
  await page.goto(BASE, { waitUntil: "networkidle" });
  await page.waitForSelector("#main-app", { state: "visible", timeout: 15000 });

  if (!withResults) {
    const violations = await analyse(page);
    await page.close();
    return violations;
  }

  // Run a prediction so the results view renders real components.
  await page.fill("#age", "78");
  await page.selectOption("#gender", "0");
  await page.fill("#leadtime", "21");
  await page.fill("#priordna", "4");
  await page.fill("#imd", "2");
  await page.click("#submit-btn");
  await page.waitForSelector("#results-content", { state: "visible", timeout: 15000 });
  await page.waitForFunction(
    () => document.getElementById("risk-percentage")?.textContent?.trim() !== "--",
    { timeout: 15000 },
  );
  const violations = await analyse(page);
  await page.close();
  return violations;
}

async function main() {
  const browser = await chromium.launch();
  const context = await browser.newContext();
  const scans = [];

  try {
    for (const theme of THEMES) {
      scans.push({ view: "landing", theme, violations: await scanLanding(context, theme) });
    }

    const token = await login(context);

    for (const theme of THEMES) {
      scans.push({ view: "assessment", theme, violations: await scanAuthed(context, theme, token, false) });
    }
    for (const theme of THEMES) {
      scans.push({ view: "results", theme, violations: await scanAuthed(context, theme, token, true) });
    }
  } finally {
    await browser.close();
  }

  const total = scans.reduce((n, s) => n + s.violations.length, 0);
  const report = {
    standard: "WCAG 2.0 / 2.1 / 2.2 — Level A + AA",
    tags: WCAG_TAGS,
    tool: "axe-core via @axe-core/playwright (headless Chromium)",
    base_url: BASE,
    scanned_at: new Date().toISOString(),
    total_violations: total,
    scans,
  };
  writeFileSync(OUT, JSON.stringify(report, null, 2));

  console.log(`\nWCAG 2.2 a11y scan — ${BASE}`);
  console.log("view        theme   violations");
  console.log("-".repeat(34));
  for (const s of scans) {
    console.log(`${s.view.padEnd(11)} ${s.theme.padEnd(6)} ${String(s.violations.length).padStart(3)}`);
    for (const v of s.violations) {
      console.log(`    [${v.impact}] ${v.id} (${v.nodes}) — ${v.help}`);
    }
  }
  console.log("-".repeat(34));
  console.log(`total violations: ${total}`);
  console.log(`wrote ${OUT}`);

  // Non-zero exit on violations so the scan can gate a manual workflow if wanted.
  process.exit(total === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(2);
});
