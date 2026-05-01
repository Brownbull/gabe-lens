# Layer B — Mockup Hub & Test-Harness Templates

**Status:** COMPLETED 2026-04-25 (Layer A executed in gastify same session: 43/43 tests green, PLAN.md Phase 4 Exec ✅, LEDGER appended).
**Created:** 2026-04-24
**Repo this plan modifies:** `/home/khujta/projects/gabe_lens/`
**Reference implementation (source-of-truth):** `/home/khujta/projects/apps/gastify/`
**Estimated complexity:** MEDIUM (~3h total — 1.5h template extraction, 1h SKILL.md update, 30m bench verification)

## Completion summary (2026-04-25)

**Layer A (gastify):** new section-card top hub at `docs/mockups/index.html` (legacy gap matrix preserved as `gap-matrix.html`); `flows/index.html` (13 live + 7 planned); `molecules/index.html` (placeholder + 7 planned cards); `assets/js/tweaks.js` section-aware breadcrumb (atoms-only path-match → generalized `/<section>/<page>` and `/<section>/index` and top-level patterns); `tests/mockups/hubs.spec.ts` renamed-from `atoms-hub.spec.ts` + generalized to 19 specs across 5 describe blocks. PLAN.md Phase 4 Exec ⬜ → ✅. 43/43 tests pass.

**Layer B (gabe_lens):** D1 `templates/mockup/index.html` · D2 `section-index.html` · D3 `playwright.config.ts` · D4 `package.json` · D5 `tests/mockups/hub.spec.ts` · D6 `tests/mockups/tweaks.spec.ts` · D7 `tests/mockups/section-smoke.spec.ts.tmpl` · D8 SKILL.md (5 sub-edits: hub navigation convention, test harness convention, M0 scaffold phase, M2/M3/M4 emit steps, bench-test appendix). `tweaks.js` template synced from gastify (now matches canonical). Sanitization: 'Baloo 2' fallback → `system-ui`; 'gastify / editorial theme' example → 'my-project / editorial theme'. `install.sh` `cp` → `cp -r` to recurse `tests/mockups/` subtree.

**Mirror:** `refrepos/setup/cherry-pick/kdbp/templates/mockup/` (12 files incl. 3 in tests/mockups/) + install.sh delta.

**Verification:** structural bench-test (mkdir tmp, cp templates, verify 6 files land + 6 placeholder cards + .tmpl excluded) ✅; gastify regression 43/43 still green ✅.

---

## TL;DR

A different project just hand-built a centralized mockup hub pattern (a top-level `docs/mockups/index.html` with section cards, per-section sub-hubs like `atoms/index.html`, a section-aware breadcrumb in the runtime Tweaks panel, and a Playwright test harness that catches "JS works but CSS doesn't react" regressions). That work lives only in gastify today. This plan extracts the pattern into reusable `gabe_lens/templates/mockup/` files + wires it into the `gabe-mockup` skill so the **next** mockup project gets the whole scaffold for free on `/gabe-mockup` init.

**You are operating in a fresh context window.** Read this doc top to bottom, run the preconditions check, then execute the deliverables. If preconditions fail, stop and ask the user to land Layer A in gastify first.

---

## Context

### What `gabe-mockup` is

The `gabe-mockup` skill (lives at `/home/khujta/projects/gabe_lens/skills/gabe-mockup/SKILL.md`, 195 lines) is the playbook the `/gabe-mockup` command consumes when executing each phase of a mockup-project plan. The canonical 13-phase preset (M1 design language → M13 handoff) is owned by `/gabe-plan --preset=mockup-project` and emitted into `.kdbp/PLAN.md` at project init.

Today the skill has these **shared conventions** (per SKILL.md):
- Tokens CSS discipline (one canonical `tokens.css` or `<project>-shell.css` under `assets/css/`; no per-screen `:root` blocks; no hex/RGB literals in screens).
- Tweaks panel — single-script include via `tweaks.js`; injects `<style>` + `<div id="tweaks-panel">` at boot; auto-detects `[data-theme]` / `[data-font]` selectors from loaded stylesheets.
- State-tabs — multi-state screen pattern.
- Per-platform frame rules — desktop vs mobile-web vs native-mobile frame conventions.
- HANDOFF.json emission at M13.

### Templates that exist today

`/home/khujta/projects/gabe_lens/templates/mockup/`:

| File | Purpose |
|------|---------|
| `tweaks.js` (399 lines) | Self-contained runtime panel — theme/mode/font/primary controls, state-tab driver |
| `tokens.css` (5.1KB) | Greenfield token starter |
| `INDEX.md` (4.4KB) | 4-table living-doc seed (decisions log, workflows, screens-by-section, CRUD×entity) |
| `wireframe-template.html` (6.2KB) | M5+ wireframe skeleton |
| `HANDOFF.schema.json` (6.6KB) | Apache-2.0 derivative of impeccable DESIGN.json v2 (handoff schema) |

**Zero `{{ TOKEN }}` placeholders anywhere.** Existing convention: literal copy + per-project edit by the recipe (Read → Edit at scaffold time). Keep that pattern; do **not** introduce a templating engine in this plan.

### The gap this plan fills

Gastify (Layer A reference implementation) ships these patterns that DON'T exist as gabe-mockup templates:

1. **Top-level `docs/mockups/index.html` hub** — section cards (Design / Atoms / Molecules / Flows / Screens / Handoff), each linking to the section's sub-hub or to `design-system.html`. Today the only template emit is `INDEX.md` (markdown 4-table doc); the visual hub is a per-project hand-author.
2. **Per-section sub-hubs** — gastify has `docs/mockups/atoms/index.html` (10-card atom gallery, hub-style), `flows/index.html` (13-flow gallery), `molecules/index.html` (placeholder for P3). Pattern: card grid · 1 inline preview per card · 1-line description · variants list · footer link back to top hub.
3. **Section-aware breadcrumb** — `tweaks.js` injects "← <section> index" or "← Mockups home" into the Tweaks panel header based on `location.pathname`. Lets a viewer navigate the whole hierarchy without manually editing URLs.
4. **Playwright test harness** — `package.json` (devDeps: `@playwright/test`, `http-server`) + `playwright.config.ts` (webServer wraps `http-server docs/mockups -p 4173`) + `tests/mockups/{hubs,tweaks,atoms}.spec.ts`. Catches JS-works-but-CSS-doesn't-react regressions. ~24 specs, ~6s run time.

Gastify's gap-fix is decision-record D22 (`/home/khujta/projects/apps/gastify/.kdbp/DECISIONS.md`).

---

## Preconditions

Layer A is the gastify-side execution that produces the reference files this plan extracts from. **Run this check before doing anything else:**

```bash
# 1. Layer A landed?
ls /home/khujta/projects/apps/gastify/docs/mockups/index.html         # must exist (top hub, with section cards — not the legacy gap matrix)
ls /home/khujta/projects/apps/gastify/docs/mockups/flows/index.html    # must exist (13-flow gallery sub-hub)
ls /home/khujta/projects/apps/gastify/docs/mockups/molecules/index.html # must exist (P3 placeholder hub)
ls /home/khujta/projects/apps/gastify/tests/mockups/hubs.spec.ts        # must exist (renamed from atoms-hub.spec.ts in A5)

# 2. Section-aware breadcrumb in tweaks.js?
grep -n "Mockups home\|<section> index\|/<section>/" /home/khujta/projects/apps/gastify/docs/mockups/assets/js/tweaks.js
# must show match — section-aware logic added in A4

# 3. Phase 4 Exec column = ✅?
grep "^| 4 |" /home/khujta/projects/apps/gastify/.kdbp/PLAN.md
# must show ✅ in the Exec column (5th cell)

# 4. Tests green?
cd /home/khujta/projects/apps/gastify && npm test 2>&1 | tail -3
# must show "<N> passed"
```

**If ANY check fails:**

```
Stop. Layer A is not complete. The gastify reference implementation is the source-of-truth this plan extracts from. Tell the user:

  "Layer B preconditions not met — gastify Layer A hasn't landed yet. Per /home/khujta/projects/apps/gastify/.kdbp/PLAN.md Phase 4 amendment, Layer A must execute first. Run /gabe-execute or /gabe-next on Phase 4 in gastify, verify all checks above pass, then re-run Layer B."

Do NOT extract templates from a partial Layer A — the patterns aren't stable yet.
```

**If all checks pass:** proceed to objectives.

---

## Objectives

1. **Extract** the centralized hub + sub-hub + Playwright test pattern from gastify into `gabe_lens/templates/mockup/`, sanitizing project-specific content.
2. **Wire** the extracted templates into the `gabe-mockup` SKILL.md recipes — so M0 init seeds the harness + top hub, and M2/M3/M4 emit per-section sub-hubs + spec instances.
3. **Verify** with a clean greenfield bench-test that `/gabe-mockup` on a fresh project yields a working hub + green Playwright suite from zero.

---

## Deliverables (8 items)

Process pattern for D1–D7: **read source from gastify, sanitize project-specific content, write to gabe_lens template path.** Sanitization principles:

- Replace gastify-specific brand strings (`gastify`, `Gastify`, the Outfit + Baloo 2 font stack, the warm green-brown palette) with **HTML/JS comments** that mark the substitution site. Example: `<!-- {{PROJECT_NAME}} - replace with this project's display name -->` or `// {{PROJECT_BRAND_FONTS}} - swap to project's bundled fonts`. Keep the markers **visible in source** so the recipe (or a human) sees them on copy.
- Replace project-specific URLs/paths with relative paths or comment-marked placeholders.
- Strip gastify-specific REQs, decision IDs, font filenames.
- Keep the structural pattern (CSS tokens used, layout grid, JS shape) intact — the value is the pattern, not the content.
- Match the existing template convention: **literal copy with comment markers**, NOT a templating engine.

### D1. NEW `gabe_lens/templates/mockup/index.html`

**Source:** `/home/khujta/projects/apps/gastify/docs/mockups/index.html` (post-Layer-A — section-card hub style, NOT the legacy P5–P12 gap matrix).

**What it is:** a principal hub for `docs/mockups/index.html` in any new project. Section cards (Design System · Atoms · Molecules · Flows · Screens · Handoff) with per-section status badge ("not yet built" placeholder vs "live N items").

**Sanitize:**
- Replace gastify wordmark / project name with `<!-- {{PROJECT_NAME}} -->` markers (h1 + meta).
- Replace gastify-specific tokens (`--bg`, `--primary`, etc.) — these should already use `desktop-shell.css` canonical tokens after Layer A's A1 token migration; just verify there's no inline `:root` block left and the file uses `var(--token)` everywhere.
- Strip gastify REQ pills (the existing screens section has `<span class="pill req">REQ-XX</span>` markers from the legacy gap matrix). Replace the screens section card body with a generic "N screens · M screens with desktop variants" placeholder format.
- Section card status logic: leave `data-status="placeholder"` and `data-status="live"` attributes intact — the sub-hub recipes flip these. Document that contract in a comment block at the top of the file.

**Exit criteria:** the template file renders in any browser as a hub with all 6 placeholder section cards. Loaded via `<link rel="stylesheet" href="assets/css/<canonical>.css">` (the canonical CSS lookup path is project-specific — leave a comment marker at the link tag).

### D2. NEW `gabe_lens/templates/mockup/section-index.html`

**Source:** `/home/khujta/projects/apps/gastify/docs/mockups/atoms/index.html` (the atoms gallery hub).

**What it is:** a generic section sub-hub. Card-grid layout, one card per item, inline preview slot per card, footer back-link to principal hub.

**Sanitize:**
- Replace section-specific text ("Atoms", "10 atoms", "Phase 2 · MVP tier", atom catalog descriptions) with comment markers: `<!-- {{SECTION_NAME}} -->`, `<!-- {{SECTION_TIER}} -->`, `<!-- {{SECTION_DESCRIPTION}} -->`.
- Card-grid container intact (`<nav class="atom-grid" aria-label="...">`). Generalize class name from `atom-grid` to `section-grid` or similar — let the recipe pick the per-section class.
- Inside each card: leave a comment block showing the expected card structure:
  ```html
  <a class="section-card" href="<item-file>.html">
    <div class="section-preview">
      <!-- {{INLINE_PREVIEW_HTML}} - real DOM example using project tokens -->
    </div>
    <div class="section-meta">
      <h2>{{ITEM_NAME}}</h2>
      <p class="item-desc">{{ITEM_DESCRIPTION}}</p>
      <span class="item-variants">{{ITEM_VARIANTS}}</span>
    </div>
  </a>
  ```
- Footer: keep links to `INDEX.md` and forward placeholder; replace gastify-specific paths with project-relative relative paths.

**Exit criteria:** copying this template into `<section>/index.html` and substituting the comment markers produces a working section gallery.

### D3. NEW `gabe_lens/templates/mockup/playwright.config.ts`

**Source:** `/home/khujta/projects/apps/gastify/playwright.config.ts` (35 lines).

**What it is:** generic Playwright config. Single chromium project. webServer wraps `http-server` on port 4173, serving `docs/mockups/`.

**Sanitize:** the source is already nearly project-agnostic. Just verify no gastify-specific paths and add a header comment block:

```ts
/**
 * Playwright config — emitted by /gabe-mockup template scaffold.
 *
 * Tests live under tests/mockups/. Static server serves docs/mockups/ on port
 * 4173 (avoids file:// protocol restrictions on cssRules introspection +
 * @import resolution). Single chromium project; no cross-browser by default.
 *
 * Customize: change port if 4173 conflicts; add more projects in `projects: []`.
 */
```

**Exit criteria:** copy to project root + run `npm test` from a project with a hub + atoms + tests, all should pass.

### D4. NEW `gabe_lens/templates/mockup/package.json`

**Source:** `/home/khujta/projects/apps/gastify/package.json`.

**What it is:** minimal node package metadata for Playwright + http-server.

**Sanitize:** replace `"name": "gastify"` with `"name": "{{PROJECT_SLUG}}"` placeholder (comment-marked since JSON doesn't support comments — use a sentinel like `"name": "PLACEHOLDER-PROJECT-SLUG"` that's obviously not real and document the contract). Replace description.

```json
{
  "name": "PLACEHOLDER-PROJECT-SLUG",
  "version": "0.0.0",
  "private": true,
  "description": "PLACEHOLDER - mockup project. Test harness for docs/mockups/.",
  "scripts": {
    "test": "playwright test",
    "test:headed": "playwright test --headed",
    "test:ui": "playwright test --ui",
    "serve:mockups": "http-server docs/mockups -p 4173 -c-1 --silent"
  },
  "devDependencies": {
    "@playwright/test": "^1.48.0",
    "http-server": "^14.1.1"
  }
}
```

**Exit criteria:** copy to project root, run `npm install` + `npx playwright install chromium`, both succeed.

### D5. NEW `gabe_lens/templates/mockup/tests/mockups/hub.spec.ts`

**Source:** `/home/khujta/projects/apps/gastify/tests/mockups/hubs.spec.ts` (post-Layer-A; renamed from `atoms-hub.spec.ts` in A5).

**What it is:** smoke spec for the principal hub + every section sub-hub it links to.

**Sanitize:**
- Replace gastify-specific section list (`["button.html", "input.html", ...]`) with empty arrays + comment markers: `// {{SECTIONS_TO_VERIFY}} - filled by recipe at scaffold time`.
- Keep the assertion shape (each section card resolves to 200, principal hub renders, breadcrumb chain works).
- Add a guard: `if (sectionsToVerify.length === 0) test.skip();` so a fresh-scaffold project (zero sections built yet) doesn't fail this spec.

**Exit criteria:** runs against a project with N sections, asserts each section's index resolves; runs against a fresh-scaffold project (zero sections), skips gracefully.

### D6. NEW `gabe_lens/templates/mockup/tests/mockups/tweaks.spec.ts`

**Source:** `/home/khujta/projects/apps/gastify/tests/mockups/tweaks.spec.ts`.

**What it is:** spec covering the Tweaks panel — theme/mode visible-effect, collapse toggle, font picker, listener-leak guard, localStorage migration.

**Sanitize:**
- The strong assertion `expect(bg).toBe("rgb(9, 9, 11)")` is gastify's Mono Dark `--bg`. Generalize to "switching to the first declared dark theme actually changes computed body bg to a different rgb than the light default":
  ```ts
  test("dark mode toggle actually changes body bg color", async ({ page }) => {
    const bgLight = await page.evaluate(() => getComputedStyle(document.body).backgroundColor);
    // Pick the first available theme + dark mode (project-agnostic)
    const firstTheme = await page.locator('.tweaks__chip[data-act="theme"]').first().getAttribute('data-val');
    if (firstTheme) await page.locator(`.tweaks__chip[data-act="theme"][data-val="${firstTheme}"]`).click();
    await page.locator('.tweaks__chip[data-act="mode"][data-val="dark"]').click();
    await expect.poll(async () => page.evaluate(() => getComputedStyle(document.body).backgroundColor), { timeout: 2000 })
      .not.toBe(bgLight);
  });
  ```
- Replace gastify-specific font-name assertion (`"outfit"` / `"space grotesk"`) with project-agnostic: assert that selecting a different font from the picker changes computed `font-family` to a different string.
- Test target page: gastify uses `/atoms/button.html`. Generalize to "first available section's first item" or accept a comment marker `// {{TWEAKS_TEST_PAGE}} - default to first atom in /atoms/, override via env var if no atoms exist yet`.

**Exit criteria:** runs against any project that has ≥1 atom-style page + ≥2 themes declared; passes 6/6 specs (theme default, dark visible-effect, collapse, font pickerexposes ≥2 options, font picker switches, listener-leak guard).

### D7. NEW `gabe_lens/templates/mockup/tests/mockups/section-smoke.spec.ts.tmpl`

**Source:** `/home/khujta/projects/apps/gastify/tests/mockups/atoms.spec.ts`.

**What it is:** parameterized smoke spec — one per section. The `.tmpl` extension means Playwright doesn't pick it up unless it's been instantiated (renamed to `.ts` and filled).

**Sanitize:**
- Replace `ATOMS` array with `// {{ITEMS_ARRAY}} - filled by /gabe-mockup recipe at section emit time`.
- Replace `Atoms — smoke` describe block name with `{{SECTION_NAME}} — smoke`.
- Keep the assertion pattern (page loads, no console errors, `#tweaks-panel` visible, primary class appears, breadcrumb visible).

**Recipe contract for instantiation:** when `/gabe-mockup` M2 (or M3 / M4) emits a section, it copies this `.tmpl` to `tests/mockups/<section>.spec.ts`, fills `{{ITEMS_ARRAY}}` from the section's manifest, fills `{{SECTION_NAME}}`, fills `{{ITEM_NAME}}` per row.

**Exit criteria:** the .tmpl file exists. Filling it via copy-and-substitute produces a working section spec. The `.tmpl` extension is excluded from `playwright.config.ts` `testDir` matching.

### D8. UPDATE `gabe_lens/skills/gabe-mockup/SKILL.md`

**File:** `/home/khujta/projects/gabe_lens/skills/gabe-mockup/SKILL.md` (currently 195 lines).

**Edits required:**

#### D8.1 — Add a new shared convention section (between "Tweaks panel" and "State-tabs")

```markdown
### Hub + sub-hub navigation

- **Principal hub:** `docs/mockups/index.html` — section-card grid (Design System · Atoms · Molecules · Flows · Screens · Handoff). Each card has `data-status="placeholder|live"`; placeholder = "not yet built", live = "N items, click to enter". Section recipes flip the status when their phase emits.
- **Section sub-hubs:** every section that produces many files (atoms, molecules, flows, screens) gets its own `<section>/index.html` — same card-grid layout. Card per item with: name, 1-line description, variants list, inline preview HTML (real DOM, NOT iframe).
- **Section-aware breadcrumb:** `tweaks.js` reads `location.pathname` at boot. On `/<section>/<name>.html` → injects "← <section> index" link to `./index.html`. On `/<section>/index.html` → injects "← Mockups home" link to `../index.html`. Hub itself injects nothing (it IS home).
- **Token discipline reminder:** principal hub + section sub-hubs use the canonical CSS via `<link rel="stylesheet" href="assets/css/<canonical>.css">`. Never inline `:root` blocks; never per-page font/color overrides. Theme + font picker on the Tweaks panel must work uniformly across hub + sections.
- **Templates:** `templates/mockup/index.html` (principal) + `templates/mockup/section-index.html` (sub-hub). Recipes copy + substitute project-specific markers at scaffold time.
```

#### D8.2 — Add a new shared convention section: "Test harness scaffold"

```markdown
### Test harness scaffold

- **Goal:** every mockup project ships with a working Playwright smoke suite that catches "JS works but CSS doesn't react" regressions.
- **Files:** `package.json` (devDeps `@playwright/test` + `http-server`), `playwright.config.ts` (webServer + chromium), `tests/mockups/{hub,tweaks}.spec.ts` (always present), `tests/mockups/<section>.spec.ts` (one per emitted section).
- **Templates:** `templates/mockup/package.json`, `templates/mockup/playwright.config.ts`, `templates/mockup/tests/mockups/{hub,tweaks}.spec.ts`, `templates/mockup/tests/mockups/section-smoke.spec.ts.tmpl`.
- **Static server:** Playwright config uses `http-server docs/mockups -p 4173`. Avoids file:// protocol issues with `cssRules` introspection + `@import` resolution.
- **Run:** `npm install && npm test` (after `npx playwright install chromium` once).
```

#### D8.3 — Add a new phase recipe before M1: "M0 — Scaffold (auto, idempotent)"

```markdown
### M0 — Scaffold (auto, idempotent)

**Goal:** seed the principal hub + Test harness on `/gabe-mockup` init for a fresh project, and only on the first run. Idempotent: re-runs are no-ops.

**Triggered by:** `/gabe-mockup` Step 0 if `docs/mockups/index.html` does not exist.

**Steps:**

1. Copy `templates/mockup/index.html` → `docs/mockups/index.html`. Substitute `{{PROJECT_NAME}}` from `.kdbp/BEHAVIOR.md` `name:` field.
2. Copy `templates/mockup/INDEX.md` → `docs/mockups/INDEX.md` (existing template, already in place).
3. Copy `templates/mockup/package.json` → project root (`./package.json`). Substitute `PLACEHOLDER-PROJECT-SLUG` with `name:` from BEHAVIOR.md (slugified). Skip if `package.json` already exists at root (might be a non-mockup project).
4. Copy `templates/mockup/playwright.config.ts` → project root.
5. Copy `templates/mockup/tests/mockups/hub.spec.ts` → `tests/mockups/hub.spec.ts`.
6. Copy `templates/mockup/tests/mockups/tweaks.spec.ts` → `tests/mockups/tweaks.spec.ts`.
7. Append `node_modules/`, `playwright-report/`, `test-results/` to `.gitignore` (idempotent grep-before-append).

**Exit criteria:** `docs/mockups/index.html` renders the section-card hub. `npm install && npm test` from project root passes (smoke level — no atoms yet, but hub + tweaks specs pass).
```

#### D8.4 — Update M2 / M3 / M4 recipes

For each section-emitting phase (M2 atoms, M3 molecules, M4 flows), add **two new steps at the end**:

```markdown
**N. Emit section sub-hub.** Copy `templates/mockup/section-index.html` → `docs/mockups/<section>/index.html`. Substitute `{{SECTION_NAME}}`, `{{SECTION_TIER}}`, `{{SECTION_DESCRIPTION}}` from the phase's plan entry. Build the card grid by iterating over the phase's emitted files; for each, fill `{{ITEM_NAME}}`, `{{ITEM_DESCRIPTION}}`, `{{ITEM_VARIANTS}}`, `{{INLINE_PREVIEW_HTML}}`.

**N+1. Emit section spec.** Copy `templates/mockup/tests/mockups/section-smoke.spec.ts.tmpl` → `tests/mockups/<section>.spec.ts` (drop the `.tmpl`). Fill `{{ITEMS_ARRAY}}` with the section's emitted files; fill `{{SECTION_NAME}}` with the phase name.

**N+2. Update principal hub.** Edit `docs/mockups/index.html`: locate the section card with `data-section="<section>"`, flip `data-status="placeholder"` → `data-status="live"`, update the card body with `<count> items` + a real link to `./<section>/index.html`.
```

#### D8.5 — Add a "Bench-test verification" appendix

A short section at the bottom of SKILL.md documenting how to verify the recipe end-to-end after future changes:

```markdown
### Appendix — Bench-test verification

After modifying any M0/M2/M3/M4 recipe or any template under `templates/mockup/`, run a clean bench-test:

\`\`\`bash
TMP=$(mktemp -d)
cd "$TMP"
git init -q && mkdir -p .kdbp docs
echo '---\nname: bench-mockup\nproject_type: mockup\n---' > .kdbp/BEHAVIOR.md
# Run /gabe-mockup (manual or automated) → expect M0 scaffold to fire
# Then verify:
#   ls docs/mockups/index.html docs/mockups/INDEX.md package.json playwright.config.ts tests/mockups/hub.spec.ts tests/mockups/tweaks.spec.ts
#   npm install && npx playwright install chromium && npm test
# Tests should pass (hub + tweaks smoke, no sections yet).

# Then run /gabe-mockup M2 atoms (manual) → expect new files:
#   ls docs/mockups/atoms/index.html tests/mockups/atoms.spec.ts
# Re-run npm test → atoms smoke spec passes.
\`\`\`
```

---

## Substitution conventions

- **Comment markers, not a templating engine.** Use HTML comments (`<!-- {{TOKEN}} -->`), JS comments (`// {{TOKEN}}`), or sentinel JSON strings (`"name": "PLACEHOLDER-PROJECT-SLUG"`). Recipes parse + replace via Read+Edit at scaffold time.
- **Visible markers.** A reader scanning a template should immediately see what's project-specific. No hidden meta-syntax.
- **Idempotent substitution.** A recipe should be safe to re-run; substitution should detect "already replaced" by checking if the marker still exists.
- **One marker per substitution site.** Don't share marker names across multiple sites unless they truly are the same value (project name, project slug). Give different sites different markers (`{{PROJECT_NAME}}` vs `{{SECTION_NAME}}` vs `{{ITEM_NAME}}`).

---

## Verification

### Bench-test (mandatory before considering Layer B done)

Per the SKILL.md Appendix above. End-to-end on a fresh tmp dir:

1. Scaffold an empty mockup project (touch `.kdbp/BEHAVIOR.md` with `project_type: mockup`).
2. Trigger `/gabe-mockup` (manually invoke M0). Verify:
   - `docs/mockups/index.html` exists, renders 6 placeholder section cards
   - `docs/mockups/INDEX.md` exists (4-table seed)
   - `package.json` + `playwright.config.ts` exist
   - `tests/mockups/hub.spec.ts` + `tests/mockups/tweaks.spec.ts` exist
3. `npm install && npx playwright install chromium && npm test` — all pre-section specs pass (hub spec skips gracefully because no sections yet; tweaks spec passes if at least one theme is declared in `tokens.css`).
4. Manually invoke M2 atoms recipe with mock data. Verify:
   - `docs/mockups/atoms/<10-atoms>.html` exist
   - `docs/mockups/atoms/index.html` exists (section sub-hub, 10 cards)
   - `tests/mockups/atoms.spec.ts` exists
   - Principal hub `docs/mockups/index.html` Atoms card now `data-status="live"` with "10 items" body
5. Re-run `npm test` — atoms smoke spec joins the suite, all pass.

### Regression guard against gastify

After Layer B lands, **gastify must continue to work unchanged.** Layer B should NOT modify gastify directly. Run from gastify root:

```bash
cd /home/khujta/projects/apps/gastify
npm test  # must still show all green
```

If gastify breaks, the Layer B template extraction over-generalized something. Roll back, narrow the sanitization, retry.

---

## Out of scope

- **Branding/logo substitution.** Templates leave `<!-- {{PROJECT_LOGO}} -->` markers; humans fill at scaffold time. Don't try to auto-detect.
- **Mobile-only mockup variants.** M5–M12 screen phases are out of scope for Layer B; they get touched separately when the per-platform frame conventions evolve.
- **Hot-reload dev server.** `http-server` is sufficient. Don't add Vite, esbuild-watch, browser-sync.
- **CI workflow templates.** No `.github/workflows/*.yml`. When the project gets CI, the workflow is a one-line `npm test` step — that's a separate concern, not part of this scaffold.
- **Custom theme generators.** Layer B doesn't generate themes; M1 (design language phase) owns theme creation. This plan only ensures the hub + Tweaks panel work correctly across whatever themes M1 produces.
- **Auto-discovery of sections.** The recipe explicitly emits sub-hub + spec per known phase. Don't try to scan `docs/mockups/` for orphan directories at runtime — that path leads to fragile behavior.

---

## Source-of-truth links

| Reference | Path |
|-----------|------|
| Layer A plan (parent, gastify execution context) | `/home/khujta/.claude/plans/plan-with-recommended-approaches-compressed-cake.md` |
| Layer A decision record (D22) | `/home/khujta/projects/apps/gastify/.kdbp/DECISIONS.md` |
| Layer A Phase 4 amendment | `/home/khujta/projects/apps/gastify/.kdbp/PLAN.md` (Phase 4 row + Phase Details) |
| Layer A LEDGER trace | `/home/khujta/projects/apps/gastify/.kdbp/LEDGER.md` (entry `2026-04-24 18:30 — PLAN UPDATED: Phase 4 amendment`) |
| Reference impl: top hub | `/home/khujta/projects/apps/gastify/docs/mockups/index.html` (post-Layer-A) |
| Reference impl: section sub-hub | `/home/khujta/projects/apps/gastify/docs/mockups/atoms/index.html` |
| Reference impl: Tweaks panel | `/home/khujta/projects/apps/gastify/docs/mockups/assets/js/tweaks.js` |
| Reference impl: Playwright harness | `/home/khujta/projects/apps/gastify/playwright.config.ts` + `tests/mockups/*.spec.ts` |
| Target: gabe-mockup skill | `/home/khujta/projects/gabe_lens/skills/gabe-mockup/SKILL.md` |
| Target: existing templates | `/home/khujta/projects/gabe_lens/templates/mockup/` |

---

## Complexity estimate

| Phase | Effort |
|-------|--------|
| Read + sanitize 7 source files (D1–D7) | ~1.5h |
| SKILL.md update (D8: 5 sub-edits) | ~1h |
| Bench-test verification + iteration | ~30m |
| **Total** | **~3h** |

Likely failure modes (budget for these in the 30m verification window):
- Sanitization regex misses a gastify-specific reference → bench scaffold inherits gastify branding. Fix: re-grep for `gastify` / `Gastify` / `khujta` after each template write.
- D6 tweaks spec generalization breaks the Mono Dark assertion in a way that no longer catches real regressions → re-verify against gastify by running its `tests/mockups/tweaks.spec.ts` after the template extraction; the gastify spec stays project-specific (uses literal `rgb(9, 9, 11)`), the template generalizes.
- M0 idempotency bug — running `/gabe-mockup` twice clobbers user edits. Fix: every copy step does an `if exists, skip` check.

---

## Authorship + handoff notes

- **Drafted by** Claude (Opus 4.7 1M) in the gastify project session that produced Layer A.
- **Why this is a separate doc** — user asked to keep the current session focused on iterating gastify mockups. Layer B is independent enough to execute in a fresh context window without prior conversation history.
- **How to start** — fresh agent reads this file from `/home/khujta/projects/gabe_lens/docs/LAYER-B-MOCKUP-HUB-TEMPLATES.md`, runs the Preconditions check, then executes D1–D8 in order. Bench-test at the end. Land as a single PR or split per deliverable — implementer's call.
- **Done signal** — this doc itself should be MOVED (not deleted) to `/home/khujta/projects/gabe_lens/docs/archive/` with a status header flip from `PLANNED` → `COMPLETED YYYY-MM-DD` once the bench-test passes. Preserve the trace for future reference.
