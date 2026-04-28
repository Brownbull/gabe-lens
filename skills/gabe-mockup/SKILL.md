---
name: gabe-mockup
description: "Playbook for /gabe-mockup execute phases — mockup-project 13-phase recipes (tokens → atoms → molecules → flows+INDEX → screens → handoff). Documents tokens.css discipline, Tweaks panel, state-tabs component, per-platform frame rules, HANDOFF.json emission, and optional ui-ux-pro-max enrichment. Consumed by /gabe-mockup Step 3."
---

# Gabe Mockup — Playbook

Per-phase recipes for `/gabe-mockup` execute step. Covers the canonical 13-phase `mockup-project` preset. Each recipe assumes PLAN.md is already written; this skill only governs HOW each Exec step runs.

**Attribution.** `HANDOFF.schema.json` format is a derivative of pbakaus/impeccable `DESIGN.json` v2 (Apache License 2.0). Per §4(c): the derivative schema carries a `NOTICE` line in its file header. Gabe Suite does not bundle impeccable code — only the schema shape for interop.

## Shared conventions (all phases)

### Tokens CSS discipline

- **Canonical install path (greenfield):** `docs/mockups/assets/css/tokens.css`. Lives under `assets/` alongside fonts/, icons/, tokens/ (taxonomy data).
- **Legacy port:** projects may already have a locked canonical shell (e.g., gastify has `docs/mockups/assets/css/desktop-shell.css` as P1 exit artifact). Keep it; don't rename. tweaks.js detects themes from any loaded stylesheet containing `[data-theme="X"]` selectors — no filename coupling.
- Runtime selectors: `[data-theme="<name>"][data-mode="light|dark"]` for theme + mode, `[data-font="<family>"]` for font swap, `[data-density="compact|regular|comfy"]` for spacing scale, `[data-radius="tight|medium|loose"]` for radii. Set by tweaks.js on `<body>`.
- **Every screen, atom, molecule, wireframe** imports the canonical CSS via `<link rel="stylesheet" href="../assets/css/<name>.css">` (path depth relative from `screens/<x>.html` etc. — all canonical content dirs are 1 level deep, so `../assets/css/...` works uniformly).
- **Forbidden patterns:** hex/RGB literals in screen HTML, per-screen `:root { --bg: ... }` blocks, theme-specific CSS files scattered outside `assets/css/`.

### Tweaks panel

- Fixed right-edge panel (280px expanded, 48px collapsed). Mirrors the Claude.ai Artifacts Tweaks widget. Controls: Theme / Mode / Primary override / Font family / Text scale / Density / Corner radius / Collapse sidebar.
- **Single-script include** — tweaks.js injects its own `<style>` block + `<div id="tweaks-panel">` at boot. Every mockup adds ONE line:
  ```html
  <script src="../assets/js/tweaks.js" defer></script>
  ```
  No separate panel HTML file, no `<link>`, no `<div>` required from the screen author.
- tweaks.js is self-contained — no dependency on any specific CSS filename. It walks `document.styleSheets` to discover `[data-theme="X"]` and `[data-font="X"]` values for the dropdowns. Consumer loads whatever tokens CSS they have; the panel adapts.
- **Every mockup includes the Tweaks panel.** No opt-out. Variants (light/dark side-by-side) are DEPRECATED — users switch modes via Tweaks.

### Hub + sub-hub navigation

- **Principal hub:** `docs/mockups/index.html` — section-card grid (Design System · Atoms · Molecules · Flows · Screens · Handoff). Each card has `data-status="placeholder|live"`; placeholder = "not yet built", live = "N items, click to enter". Section recipes flip the status when their phase emits.
- **Section sub-hubs:** every section that produces many files (atoms, molecules, flows, screens) gets its own `<section>/index.html` — same card-grid layout. Card per item with: name, 1-line description, variants list, inline preview HTML (real DOM, NOT iframe).
- **Section-aware breadcrumb:** `tweaks.js` reads `location.pathname` at boot. On `/<section>/<name>.html` → injects "← <Section> index" link to `./index.html`. On `/<section>/index.html` → injects "← Mockups home" link to `../index.html`. On top-level `/<name>.html` (e.g. `/design-system.html`) → injects "← Mockups home" link to `./index.html`. Top hub (`/index.html`) injects nothing (it IS home).
- **Token discipline reminder:** principal hub + section sub-hubs use the canonical CSS via `<link rel="stylesheet" href="<canonical-path>">`. Never inline `:root` blocks; never per-page font/color overrides. Theme + font picker on the Tweaks panel must work uniformly across hub + sections.
- **Templates:** `templates/mockup/index.html` (principal) + `templates/mockup/section-index.html` (sub-hub). Recipes copy + substitute project-specific markers at scaffold time.

### Test harness scaffold

- **Goal:** every mockup project ships with a working Playwright smoke suite that catches "JS works but CSS doesn't react" regressions.
- **Files:** `package.json` (devDeps `@playwright/test` + `http-server`), `playwright.config.ts` (webServer + chromium), `tests/mockups/{hub,tweaks}.spec.ts` (always present), `tests/mockups/<section>.spec.ts` (one per emitted section).
- **Templates:** `templates/mockup/package.json`, `templates/mockup/playwright.config.ts`, `templates/mockup/tests/mockups/{hub,tweaks}.spec.ts`, `templates/mockup/tests/mockups/section-smoke.spec.ts.tmpl`.
- **Static server:** Playwright config uses `http-server docs/mockups -p 4173`. Avoids `file://` protocol issues with `cssRules` introspection + `@import` resolution.
- **Run:** `npm install && npm test` (after `npx playwright install chromium` once).

### React port (shared convention for `spike` mode)

When `/gabe-mockup spike <component>` translates a static mockup into a working React component, three rules are non-negotiable:

1. **Single source of truth for tokens.** `frontend/src/styles/tokens.css` re-exports the canonical mockup CSS via `@import "@mockups/assets/css/<canonical>.css"` (resolved through a Vite alias to `docs/mockups/`). React-side stylesheets MUST consume `var(--*)` tokens — never hex literals, never per-component `:root` blocks. If a token isn't defined yet, add it to the canonical CSS, not to a React file.
2. **DOM mirrors the HTML mockup verbatim.** Same class names (`.<component>`, `.<component>-icon`, etc.), same variant convention (`is-success` className, NOT `data-variant`), same ARIA roles. The molecule's existing CSS rules apply unchanged because selectors are identical. Class-name divergence between mockup and React is a refactor, not a port.
3. **JSDoc `@see` backref every component file.** `@see <relative-path-to-mockup-html>` followed by `@see <relative-path-to-COMPONENT-LIBRARY.md>`. Mockup HTML is the spec; React is the implementation; backrefs survive renames and make lineage findable.

**Animation handling:** CSS transitions on mount work cleanly. For unmount, the component sets an `is-leaving` class that triggers an exit transition, then a 200ms `setTimeout` calls back via `onDismiss(id)`. No animation library required at spike scale; if a future component needs richer choreography, introduce `<TransitionGroup>` or Framer Motion at THAT time.

**Leaf vs. system-layer rule of thumb:** a component needs the `--system` flag (Provider + Container + hook) when **multiple instances appear concurrently** at runtime — toast queue, modal stack, drawer stack. Singleton-per-screen molecules (cards, banners, forms) are leaf-only.

### State-tabs component (multi-state screens)

- Promoted from `gastify-single-scan-states.html` pattern to suite standard.
- Multi-state screens MUST use one shared phone frame (mobile) / one edge-to-edge surface (desktop) + a state-tabs row that toggles `.state-content.active` class via JS.
- **Forbidden pattern:** stacking multiple phone frames vertically, one per state/variant. Creates visual inconsistency (gastify `login.html` drift).
- State-tabs live at `docs/mockups/molecules/state-tabs.html` (produced in M3).
- DOM flexibility: tweaks.js state-tabs driver accepts both ARIA (`[role="tablist"] > [role="tab"]`) and legacy (`.state-tabs > .state-tab[data-state]`) shapes. Authors pick whichever reads cleaner.

### Per-platform frame rules

**Mobile screens:**

| Scenario | Behavior |
|---|---|
| Single-state | ONE phone frame, 390×844 min-height. Content > 844 → scroll inside frame (`overflow-y: auto`). Content < 844 → pad to 844 min so frame doesn't collapse |
| Multi-state | ONE shared phone frame + state-tabs row above frame. Frame height rules apply |
| Multi-variant | Use Tweaks panel to switch variants at runtime. No side-by-side variant frames |

**Tablet screens:**

| Scenario | Behavior |
|---|---|
| Single-state | Content max-width 720px centered, 16px edge padding. Max screen frame 768×1024 (portrait) or 1024×768 (landscape — author's choice per screen). Content > frame height → native vertical scroll |
| Multi-state | Same frame + state-tabs row. State-tabs sit above content (mobile parity) |
| Multi-variant | Tweaks panel for variants. No side-by-side variant frames |

**Desktop screens:**

| Scenario | Behavior |
|---|---|
| Single-state | No phone frame. Edge-to-edge inside page. Top bar (60px) per `DESKTOP-TEMPLATE.md`. Content scrolls natively |
| Multi-state | State-tabs secondary bar below top bar. JS toggle same as mobile |

### Validation gates — screen-level

Frame rules above are honored either by **discipline** (author writes within the rule) or by **automation** (the validator catches violations). The `validate` mode (see Modes below) provides the automation. Conventions:

- **Four check categories,** each with stable-IDs that survive renames/re-runs:
  - **C1 Overflow** (severity: `block`) — `body-overflow`, `container-overflow`, `image-overflow`. Catches content escaping the frame at any of phone/tablet/desktop viewports.
  - **C2 Narrow columns** (severity: `warn`) — `min-column-width` (default <60px), `column-text-overflow` (cell content clipped). Catches "Tipo" columns at 32px holding "Combustible".
  - **C3 Empty content** (severity: `warn`) — `list-emptiness` (table with `<thead>` but 0 `<tbody><tr>`), `placeholder-only` (skeleton density >50% of viewport). Catches transaction screens shipping with zero rows.
  - **C4 KDBP rules** (severity: `varies`) — reads `.kdbp/RULES.md`, applies rules tagged `applies-to: mockup-screens` (or `mockup:<phase>` / `mockup:<screen>`) with optional `detect: dom-selector <css>` evaluator. Tagged-but-no-detector rules emit info-only findings.
- **Severity ladder:** `block` (frame violation, must triage), `warn` (likely violation, review), `info` (informational, no action required by default).
- **Stable-ID hashing:** `sha1(screen + viewport + ruleId + selector)` truncated to 10 chars. Used by `runner.mjs` to dedup findings across runs and preserve user-set Status values (`pending` / `fixed-in-place` / `deferred` / `dismissed`).
- **When the gate fires:**
  1. **On-demand:** `/gabe-mockup validate` (full sweep or filtered subset).
  2. **Inline at phase exit:** every M5–M12 phase ends by running validate over the screens it emitted, unless the next `/gabe-mockup` invocation passes `--skip-validation`. Gate is *review-or-defer*, not *must-fix-to-proceed* — friction-aware, not blocking.
- **Architecture awareness:** validator detects `dynamic` (single file + tweaks.js viewport switcher, e.g., gastify) vs `per-device` (`*-mobile.html` / `*-tablet.html` / `*-desktop.html`, e.g., gustify) and dispatches accordingly. Override via `.kdbp/BEHAVIOR.md` field `mockup_architecture: dynamic|per-device` for mid-migration projects.

---

## Modes

`/gabe-mockup` runs the next phase recipe by default (M0 → M13 sequenced by `.kdbp/PLAN.md`). It also accepts **named modes** via positional argument that bypass the phase ladder for targeted vertical-slice work.

**Dispatch:** the skill reads `$ARGUMENTS`. If the first positional arg matches a known mode name, it runs the mode's recipe instead of advancing the phase ladder. Unknown args fall through to phase mode.

| Mode | Invocation | Purpose |
|---|---|---|
| (default) | `/gabe-mockup` | Advance the phase ladder per PLAN.md |
| `spike` | `/gabe-mockup spike <component>` | Translate one live mockup into a working React component |
| `validate` | `/gabe-mockup validate [<screen>\|--all]` | Run layout sanity checks (C1-C4) over screens × phone/tablet/desktop viewports |

### Mode: `spike`

**Purpose.** Take ONE live mockup (atom or molecule) and produce a shipping React component + minimal Vite/React/TS harness if the project doesn't have one. Keeps tokens as the single source of truth via `@import` from the canonical mockup CSS.

**Invocation:**
```
/gabe-mockup spike <component>            # leaf component only
/gabe-mockup spike <component> --system   # leaf + Provider + Container + hook (queue patterns)
/gabe-mockup spike <component> --framework=react   # only react is implemented
```

**Pre-conditions.**
- `.kdbp/` exists (project initialized via `/gabe-init`).
- `docs/mockups/<section>/<component>.html` exists and is "live" on the principal hub (not placeholder). Section auto-detected by file search across `atoms/`, `molecules/`, `flows/`, `screens/`.
- A canonical tokens CSS file exists under `docs/mockups/assets/css/` exposing `[data-theme="X"]` selectors.

**Outputs (idempotent — re-running skips files that already exist):**
- Scaffold (only if `frontend/package.json` missing): `frontend/{package.json, vite.config.ts, tsconfig.json, index.html, README.md}` + `frontend/src/{main.tsx, App.tsx, styles/tokens.css}`.
- Component leaf: `frontend/src/components/<Component>/{<Component>.tsx, <Component>.css, <Component>.types.ts}`. **Plain `.css` not `.module.css`** — Vite would scope class names with the latter, breaking the DOM-mirroring rule.
- System layer (only with `--system`): `frontend/src/components/<Component>/{<Component>Provider.tsx, <Component>Container.tsx, use<Component>.ts}`.
- Demo: `frontend/src/demo/<Component>Demo.tsx`.
- Recipe doc (only if missing — augmented thereafter): `docs/mockups/REACT-PORT-RECIPE.md`.
- Bookkeeping: append `Spike P14.<N>` row to `.kdbp/PLAN.md`; append a dated entry to `.kdbp/LEDGER.md`; append `frontend/node_modules/`, `frontend/dist/` to `.gitignore` (idempotent grep-then-append).

**Recipe steps.**

1. **S1 — Read source.** Open `docs/mockups/<section>/<component>.html`, the canonical tokens CSS, and the relevant `assets/css/<atoms|molecules>.css` for existing component CSS rules. If the component composes atoms (button, badge, etc.), open those too. Note the exact DOM structure, className convention, ARIA roles, default durations / states from the "Composition" section.
2. **S2 — Detect or scaffold harness.** If `frontend/package.json` exists, skip. Else copy from `templates/mockup/react/` with substitutions:
   - `{{PROJECT_NAME}}` ← `name:` from `.kdbp/BEHAVIOR.md`
   - `{{PROJECT_SLUG}}` ← slugified project name
   - `{{TOKENS_FILENAME}}` ← canonical CSS filename (greenfield: `tokens.css`; legacy port: e.g. `desktop-shell.css`)
   - `{{MOCKUPS_REL_PATH}}` ← path from `frontend/` up to `docs/mockups/` (typically `../docs/mockups`)
   - `{{DEFAULT_THEME}}` / `{{DEFAULT_MODE}}` ← first theme + `light` from canonical CSS (grep `[data-theme="X"]` selectors).
3. **S3 — Emit component leaf.** Copy `templates/mockup/react/src/components/Component.{tsx,css,types.ts}.tmpl` → `frontend/src/components/<Component>/<Component>.{tsx,css,types.ts}` with substitutions:
   - `{{COMPONENT_NAME}}` (PascalCase), `{{COMPONENT_SLUG}}` (kebab-case)
   - `{{COMPONENT_TYPES}}` ← variant union literal (e.g. `"success" | "info" | "warning" | "error"`)
   - `{{DEFAULT_DURATION}}` ← sensible default in ms (or 0 for sticky-by-default components)
   - `{{MOCKUP_HTML_REL_PATH}}` ← from `<Component>.tsx` to mockup HTML (typically `../../../../docs/mockups/<section>/<component>.html`)
   - `{{COMPONENT_LIBRARY_REL_PATH}}` ← same family, pointing to `<section>/COMPONENT-LIBRARY.md` if it exists
   - `{{COMPONENT_CSS_BODY}}` ← inline component CSS rules, copy-ported from the existing canonical CSS (move-or-reference, never duplicate token values).
4. **S4 — System layer (--system only).** Copy `ComponentProvider.tsx.tmpl`, `ComponentContainer.tsx.tmpl`, `useComponent.ts.tmpl` → `<Component>Provider.tsx`, `<Component>Container.tsx`, `use<Component>.ts` with substitutions: `{{PROVIDER_NAME}}` (e.g. `ToastProvider`), `{{CONTAINER_NAME}}` (e.g. `ToastContainer`), `{{HOOK_NAME}}` (e.g. `useToast`), `{{MAX_VISIBLE}}` (default 3 for toast/modal stacks).
5. **S5 — Demo page.** Copy `templates/mockup/react/src/demo/ComponentDemo.tsx.tmpl` → `frontend/src/demo/<Component>Demo.tsx`. Substitute `{{VARIANT_TUPLE}}` (e.g. `["success", "info", "warning", "error"]`), `{{THEME_OPTIONS}}` (rendered `<option>` tags from canonical CSS theme list), `{{HOOK_NAME_FILE}}` (e.g. `useToast`). For leaf-only spikes, the recipe strips `// SYSTEM:` lines and the entire `{/* SYSTEM-START */} ... {/* SYSTEM-END */}` block.
6. **S6 — Visual diff.** `cd frontend && npm install && npm run dev` (port 5173). In a second tab, `npx http-server docs/mockups -p 4173`. Compare each variant in light + dark mode. Acceptable drift: subpixel font rendering, animation timing. Unacceptable: any token-derived value (color, spacing, radius, shadow) — those mean the import chain is broken.
7. **S7 — Recipe doc.** If `docs/mockups/REACT-PORT-RECIPE.md` doesn't exist, copy from `templates/mockup/react/recipe/REACT-PORT-RECIPE.md.tmpl` with substitutions. Always append a row to the "Components ported" table (date, component name, --system flag, notes).
8. **S8 — Bookkeeping.** Append `Spike P14.<N>` row to `.kdbp/PLAN.md` (use the next available `P14.N` index). Append a `## YYYY-MM-DD — SPIKE P14.<N> EXECUTED` block to `.kdbp/LEDGER.md` documenting files emitted + verification result.

**Verification gate (all must pass before S8 marks complete):**
- `npm run dev` boots without errors at localhost:5173.
- Static showcase row in `<Component>Demo` visually matches the HTML mockup at localhost:4173 in both light + dark mode (no token-derived drift).
- For `--system`: dispatch buttons trigger live components that auto-dismiss + hover-pause + queue (max N visible).
- Browser console: zero errors, zero warnings during boot, dispatch, dismiss.
- Existing `npm test` (Playwright) at project root still passes — the React harness must not regress the mockup test suite.

**Idempotency rules.**
- Scaffold step (S2) checks-then-skips per file. Re-running on a project with an existing `frontend/` does not clobber anything.
- Component step (S3) overwrites the component file IF the user passes `--force`; default is to refuse and exit with a "component already ported" message.
- Demo + recipe doc steps: always append to the "Components ported" table; never overwrite previous rows.
- Bookkeeping always appends — never edits prior PLAN.md or LEDGER.md entries.

**Error recovery.**
- **Component HTML missing** → exit with `⚠ <component>.html not found in atoms/, molecules/, flows/, or screens/. Spike requires a live mockup as source.`
- **Component listed as placeholder on principal hub** → exit with `⚠ <component> is marked placeholder on docs/mockups/index.html. Build it first via the appropriate phase recipe.`
- **Token chain @import fails at boot** → likely a path-resolution issue with the Vite alias. Recipe falls back to a deeper relative path with no alias and re-runs S6.
- **`--framework=<other>` passed** → exit with `⚠ Only --framework=react is implemented in this pass. Skipping.` (Reserved API surface.)

### Mode: `validate`

**Purpose.** Run layout sanity checks across every emitted screen × phone/tablet/desktop viewport, catching C1 overflow / C2 narrow-columns / C3 empty-content / C4 KDBP-rule violations. The "sub-agent per screen" semantics are delivered via Playwright spec parallelism — each (screen × viewport) pair runs in an isolated browser context concurrently.

**Invocation:**
```
/gabe-mockup validate                    # interactive: pick a screen from INDEX.md §3
/gabe-mockup validate <screen>           # single screen
/gabe-mockup validate --all              # full sweep
/gabe-mockup validate --phase=M7         # all screens emitted by a specific phase

# flags
--viewports=phone,tablet,desktop         # subset (default: all three)
--severity=block,warn,info               # filter (default: all)
--skip-kdbp                              # disable C4 category
--skip-validation                        # bypass inline gate at next /gabe-mockup phase
```

**Pre-conditions.**
- `.kdbp/` exists (project initialized via `/gabe-init`).
- `docs/mockups/screens/` populated (M5+ underway).
- `playwright.config.ts` exists at project root (validator emits a minimal one from `templates/mockup/playwright.config.ts` if missing).
- Architecture detected as `dynamic` (single-file + tweaks.js viewport switching) OR `per-device` (`*-mobile.html` / `*-tablet.html` / `*-desktop.html`). Override via `.kdbp/BEHAVIOR.md` `mockup_architecture:` field.

**Outputs (idempotent — re-running preserves user-set Status values):**
- Validator harness (only if missing): `tests/mockups/validate/{runner.mjs, screen-validator.spec.ts, rules.json}`.
- Live findings document: `.kdbp/MOCKUP-VALIDATION.md` (rewritten per run; preserves Status of matching stable-IDs).
- Recipe doc (only if missing — augmented thereafter): `docs/mockups/VALIDATE-MODE-RECIPE.md`.
- Bookkeeping: append `Spike P15.<N>` row to `.kdbp/PLAN.md`; append a dated entry to `.kdbp/LEDGER.md`; append `tests/mockups/validate/.cache/` to `.gitignore` (idempotent grep-then-append).

**Recipe steps.**

1. **S1 — Detect architecture + scaffold harness.** Read `.kdbp/BEHAVIOR.md` for `mockup_architecture:` override; else heuristic: probe `docs/mockups/screens/` for per-device suffixes vs `tweaks.js` containing `data-viewport` setter. Record detection reason. If `tests/mockups/validate/` missing, copy from `templates/mockup/validate/` with substitutions:
   - `{{PROJECT_NAME}}` ← `name:` from `.kdbp/BEHAVIOR.md`
   - `{{PROJECT_SLUG}}` ← slugified project name
   - `{{GENERATED_AT}}` ← UTC ISO timestamp
   - `{{ARCHITECTURE_MODE}}` ← `dynamic` or `per-device`
   - `{{ARCHITECTURE_REASON}}` ← detection-reason string
   - `{{VIEWPORT_PHONE_WIDTH}}` ← canonical phone viewport width (e.g., 360 or 390 — derived from canonical CSS or default 390)
   - `{{VIEWPORT_TABLET_WIDTH}}` ← 768 (suite default)
   - `{{VIEWPORT_DESKTOP_WIDTH}}` ← 1440 (suite default)
   - `{{MIN_COLUMN_WIDTH_PX}}` ← 60 (suite default; tunable per project)
   - `{{SCREENS_INDEX_PATH}}` ← `docs/mockups/INDEX.md`
2. **S2 — Walk screens index.** Parse `docs/mockups/INDEX.md` §3 (Screens by section) to enumerate target screens. Apply `--screens` / `--phase` filters. Skip screens matching `rules.json` `skip_screens_pattern` (default: `-empty|-zero|-first-time|-loading|-error|deprecated`).
3. **S3 — Run validator.** `node tests/mockups/validate/runner.mjs` (with passed flags). Runner writes `.cache/screens.json` manifest, invokes `npx playwright test tests/mockups/validate/screen-validator.spec.ts` — Playwright runs each (screen × viewport) test in parallel, writing per-test findings JSON into `.cache/findings/`. Runner aggregates.
4. **S4 — Aggregate + dedupe.** Stamp stable-IDs (`sha1(screen+viewport+ruleId+selector)` truncated to 10 chars). Merge with existing `.kdbp/MOCKUP-VALIDATION.md`: preserve user-set Status values for matching IDs; new findings come in as `pending`.
5. **S5 — Write MOCKUP-VALIDATION.md.** Sections: header (architecture, run timestamp, severity totals), Findings (grouped by screen, status checkbox), Triage Backlog (deferred), Dismissed. Idempotent re-write — same input ⇒ same output (modulo timestamp).
6. **S6 — Triage loop (interactive).** Per pending finding, offer f / d / x / s / e / q action keys (full reference: `~/.claude/templates/gabe/mockup/validate/validate-checklist.md`). Mutate Status column in place. Resumable — file is the source of truth; pick up where you left off next session.

**Verification gate (all must pass before S6 marks complete):**
- Architecture detection emits a non-`unknown` mode with a concrete reason in MOCKUP-VALIDATION.md header.
- `runner.mjs` exits with code 0 (or code 1 if Playwright reports any spec issues — findings are data, not failures, so exit code 1 is acceptable here).
- MOCKUP-VALIDATION.md totals row reflects the actual finding count by severity.
- For at least one finding, the lifecycle works end-to-end: triage with `f` → fix screen → re-run → stable-ID drops off active list (if fix resolves the issue).
- Existing `npm test` (Playwright) at project root still passes — the validate spec must not regress non-validate specs.

**Idempotency rules.**
- Stable-ID hashing means re-runs over the same screens produce the same IDs unless screen content changes (selector match shifts).
- Status values (`fixed-in-place`, `deferred`, `dismissed`) survive re-runs for matching IDs.
- New findings always come in as `pending` so the user is never surprised by silent state changes.
- Old findings whose stable-IDs are no longer present (issue resolved) drop off the active list automatically — no orphan entries.

**Error recovery.**
- **Architecture detection returns `unknown`** → exit with `⚠ Cannot detect mockup architecture. Set 'mockup_architecture: dynamic|per-device' in .kdbp/BEHAVIOR.md.`
- **`docs/mockups/screens/` missing** → exit with `⚠ No screens directory. Run M5+ phase recipes first to emit screens.`
- **`playwright.config.ts` missing** → emit one from `templates/mockup/playwright.config.ts` (substituting project-specific port, mockup root) before continuing S3.
- **Playwright crash (worker error, browser launch failure)** → propagate runner exit code 2; don't write a partial MOCKUP-VALIDATION.md (last-good remains intact).
- **`--phase=M<N>` passed but PLAN.md doesn't enumerate screens by phase** → fall back to `--all` with a console warning.

**Inline gate at M5–M12 phase exit.**

After every M5–M12 phase emits its last screen (before the user's next `/gabe-mockup` invocation), the dispatcher auto-runs `runner.mjs` over the screens emitted in that phase (filtered via `--screens=<phase-screens>`). Findings populate `.kdbp/MOCKUP-VALIDATION.md` as new `pending` entries. The user can then:

- **Triage** any subset (f / d / x).
- **Defer the entire batch** by passing `--skip-validation` to the next `/gabe-mockup` invocation — phase ladder advances; findings stay pending.
- **Disable the gate entirely** for a project by setting `validate_inline_gate: off` in `.kdbp/BEHAVIOR.md`. (Discouraged — the gate is the whole point of having validate codified.)

---

## Phase recipes

### M0 — Scaffold (auto, idempotent)

**Goal:** seed the principal hub + Test harness on `/gabe-mockup` init for a fresh project, and only on the first run. Idempotent: re-runs are no-ops.

**Triggered by:** `/gabe-mockup` Step 0 if `docs/mockups/index.html` does not exist.

**Steps:**

1. **Copy principal hub template.** `templates/mockup/index.html` → `docs/mockups/index.html`. Substitute:
   - `{{PROJECT_NAME}}` ← `name:` from `.kdbp/BEHAVIOR.md`
   - `{{PROJECT_LEDE}}` ← one-liner from `.kdbp/SCOPE.md` §1
   - `{{CANONICAL_CSS}}` ← path to canonical tokens CSS (greenfield: `assets/css/tokens.css`; legacy port: `assets/css/<project>-shell.css`)
   - `{{TWEAKS_JS_PATH}}` ← `assets/js/tweaks.js`
   - `{{THEME_COUNT}}` / `{{PROJECT_META_PILLS}}` ← scaffold-time placeholder; recipe overwrites as M1+ lands.
2. **Copy INDEX.md template.** `templates/mockup/INDEX.md` → `docs/mockups/INDEX.md`. Existing template, already in place.
3. **Copy package.json.** `templates/mockup/package.json` → project root. Substitute `PLACEHOLDER-PROJECT-SLUG` with slugified `name:` from BEHAVIOR.md, `PLACEHOLDER-PROJECT-DESCRIPTION` with SCOPE one-liner. Skip if `package.json` already exists at root (might be a non-mockup project — ask user before overwriting).
4. **Copy playwright.config.ts.** `templates/mockup/playwright.config.ts` → project root.
5. **Copy hub spec.** `templates/mockup/tests/mockups/hub.spec.ts` → `tests/mockups/hub.spec.ts`.
6. **Copy tweaks spec.** `templates/mockup/tests/mockups/tweaks.spec.ts` → `tests/mockups/tweaks.spec.ts`.
7. **Append to `.gitignore`** (idempotent grep-before-append): `node_modules/`, `playwright-report/`, `test-results/`.

**Exit criteria:** `docs/mockups/index.html` renders the section-card hub with 6 placeholder cards. `npm install && npm test` from project root passes (smoke level — no atoms yet, but hub + tweaks specs pass / skip gracefully because no live sections).

### M1 — Design language + tokens (`design-system`)

**Goal:** Produce the multi-theme token matrix + lock canonical tokens CSS.

**Steps:**

1. **Theme strategy decision.** Ask user: port existing themes (if legacy design exists) OR author new themes (if greenfield).
2. **uipro enrichment (optional).** If `~/.claude/skills/ui-ux-pro-max/` installed:
   ```bash
   python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<domain summary>" --domain style -n 5
   ```
   Append top 3-5 candidates to the theme list. If not installed → skip silently.
3. **Author `STRESS-TEST-SPEC.md`** at `docs/mockups/STRESS-TEST-SPEC.md`:
   - 4 canonical screens × N platforms (from PLAN `--platforms`) × 2 modes (light/dark) matrix
   - Minimum viable subset: Dashboard × N platforms × themes — confirms token discipline before full matrix
4. **Render stress matrix.** For each theme × screen × platform × mode, emit HTML at `docs/mockups/explorations/<theme>-<screen>-<platform>.html`. Use `frontend-design` skill OR project-specific design skill (e.g., `gastify-design`).
5. **User reviews candidates.** Pick subset to ship as runtime multi-theme set.
6. **Write tokens CSS:**
   - **Greenfield:** copy `~/.claude/templates/gabe/mockup/tokens.css` to `docs/mockups/assets/css/tokens.css`; extend with all picked themes' vars.
   - **Legacy port:** extend the existing shell (e.g., `docs/mockups/assets/css/<project>-shell.css`) with any new theme vars. DON'T duplicate into a second file. tweaks.js detects themes from whatever stylesheet is loaded — one canonical source per project.
7. **Copy `tweaks.js`** from `~/.claude/templates/gabe/mockup/tweaks.js` to `docs/mockups/assets/js/tweaks.js`. No panel.html file needed — tweaks.js is self-contained.
8. **Write `design-system.html`** at `docs/mockups/design-system.html`: demo page showing 4 stress screens × theme switcher. Include `<link rel="stylesheet" href="./assets/css/<name>.css">` + `<script src="./assets/js/tweaks.js" defer></script>` (note: at root depth, paths start with `./`).

**Exit criteria:** tokens CSS loaded by design-system.html. Tweaks panel switches all themes × modes × fonts × densities × radii live. `/gabe-plan` phase Exec → ✅.

### M2 — Atomic components (`design-system, ui-kit`)

**Goal:** Populate `docs/mockups/atoms/` with ~14 self-contained atom files.

**Steps:**

1. **List atoms** (from tier-section `ui-kit.md` dims): button (5 variants), input (5 variants), pill, badge, avatar, chip, skeleton, progress, spinner. Reference `legacy-reference/claude-design/ui_kits/` if exists.
2. **Per atom, emit file** at `docs/mockups/atoms/<name>.html`:
   - `<link rel="stylesheet" href="../assets/css/<canonical>.css">` (the project's tokens CSS — greenfield: `tokens.css`; legacy port: existing shell filename)
   - `<script src="../assets/js/tweaks.js" defer></script>` (single-script include — panel + state-tabs)
   - Render all state variants (default, hover, focus, disabled, loading, error per tier — MVP=2, Ent=6)
   - Document snippet include pattern at bottom (how screens consume it)
3. **Write `docs/mockups/atoms/INDEX.md`** listing all atoms + their file paths (consumed by wireframe dropdowns in M4+).
4. **Emit section sub-hub.** Copy `templates/mockup/section-index.html` → `docs/mockups/atoms/index.html`. Substitute `{{SECTION_NAME}}="Atoms"`, `{{SECTION_TIER}}` from PLAN.md Phase 2 row, `{{SECTION_DESCRIPTION}}` from atom catalog narrative. Build the card grid by iterating atoms emitted in step 2; for each, fill `{{ITEM_NAME}}`, `{{ITEM_DESCRIPTION}}`, `{{ITEM_VARIANTS}}`, `{{INLINE_PREVIEW_HTML}}` (real DOM example using project tokens). Footer back-link to `../index.html`.
5. **Emit section spec.** Copy `templates/mockup/tests/mockups/section-smoke.spec.ts.tmpl` → `tests/mockups/atoms.spec.ts` (drop the `.tmpl`). Fill `{{SECTION_NAME}}="Atoms"`, `{{SECTION_SLUG}}="atoms"`, `{{ITEMS_ARRAY}}` with the atoms emitted (one entry per atom: `{ name, file, primaryClass }`).
6. **Update principal hub.** Edit `docs/mockups/index.html`: locate `<a class="section-card" data-section="atoms" ...>`, flip `data-status="placeholder"` → `data-status="live"`, replace `href="#"` with `href="atoms/index.html"`, update card body with `<count> atoms · Phase 2 · <tier>`. Also update the principal hub's `{{PROJECT_META_PILLS}}` block to reflect live atoms count.
7. **Update hub.spec.ts.** Edit `tests/mockups/hub.spec.ts`: add `"atoms"` to the `LIVE_SECTIONS` array. The sub-hub specs auto-generate from this list.
8. **Run `npm test`.** Verify: principal hub spec live-cards check passes, atoms sub-hub spec passes, atoms smoke spec passes, no regressions.

**Exit criteria:** every atom self-contained, loads canonical tokens CSS + tweaks.js, renders all its states via Tweaks-driven state-tabs. `INDEX.md` atoms catalog exists. Atoms sub-hub at `docs/mockups/atoms/index.html` lists every atom with inline preview. Principal hub Atoms card flipped to live. `npm test` green.

### M3 — Molecular components (`design-system, ui-kit`)

**Goal:** Compose atoms into molecules + document state matrices.

**Steps:**

1. **List molecules:** cards (transaction, stat, empty, feature, celebration), modals (confirm, form, learning, error, credit), toast, banner, nav (bottom, top, sidebar), FAB, filters, sheets, drawers, forms, **state-tabs** (canonical).
2. **Per molecule, emit file** at `docs/mockups/molecules/<name>.html`:
   - Reference atoms via include OR snippet
   - Full state matrix (all states Ent+ per tier)
   - A11y roles documented inline (`role=`, `aria-*`)
   - Platform-variance notes (Scale tier)
3. **Write `docs/mockups/molecules/COMPONENT-LIBRARY.md`** cataloging molecules + their atoms + state matrix + platform variance.
4. **Emit section sub-hub.** Copy `templates/mockup/section-index.html` → `docs/mockups/molecules/index.html`. Substitute `{{SECTION_NAME}}="Molecules"`, `{{SECTION_TIER}}` from PLAN.md Phase 3 row (typically `Enterprise tier`), `{{SECTION_DESCRIPTION}}` from molecule narrative. One card per molecule with inline preview using real DOM.
5. **Emit section spec.** Copy `templates/mockup/tests/mockups/section-smoke.spec.ts.tmpl` → `tests/mockups/molecules.spec.ts`. Fill `{{SECTION_NAME}}="Molecules"`, `{{SECTION_SLUG}}="molecules"`, `{{ITEMS_ARRAY}}` with molecule entries.
6. **Update principal hub.** Edit `docs/mockups/index.html`: locate `<a class="section-card" data-section="molecules" ...>`, flip `data-status="placeholder"` → `data-status="live"`, replace `href="#"` with `href="molecules/index.html"`, update card body with `<count> molecules · Phase 3 · <tier>`.
7. **Update hub.spec.ts.** Add `"molecules"` to the `LIVE_SECTIONS` array.
8. **Run `npm test`.** Verify principal hub + molecules sub-hub + molecules smoke specs pass.

**Exit criteria:** `state-tabs.html` molecule exists + is the canonical pattern. COMPONENT-LIBRARY.md complete. Molecules sub-hub renders. Principal hub Molecules card flipped to live. `npm test` green.

### M4 — Flows + INDEX + CRUD×entity (`mockup-flows, mockup-index`)

**Goal:** Seed `docs/mockups/INDEX.md` (4 tables) + populate ENTITIES.md CRUD columns + enumerate flows.

**Steps:**

1. **Read `.kdbp/ENTITIES.md`** — entity list (created at `/gabe-init` for mockup/hybrid projects). If missing, create from template + seed from SCOPE.md REQs.
2. **Write `docs/mockups/INDEX.md`** from `templates/mockup/INDEX.md`:
   - §1 Decisions log — port from `.kdbp/DECISIONS.md` D-entries
   - §2 Workflows — list flows F1..Fn with REQ mappings
   - §3 Screens by section — seed with desktop+mobile columns (empty rows for P5-P12 to fill)
   - §4 CRUD × entity — for each entity in ENTITIES.md, 4 columns (Create / View / Update / Delete), cells filled with screen names as P5-P12 lands
   - §5 Component usage — seed (filled in P5-P12)
   - §6 Coverage gaps — initial baseline from AUDIT (if exists)
3. **Enumerate flows.** For each flow, emit `docs/mockups/flows/flow-<N>-<name>.html` walkthrough skeleton (happy path only at MVP tier).
4. **Cross-ref.** INDEX.md §2 links flows by number; flows reference screens; screens reference molecules; molecules reference atoms.
5. **Emit section sub-hub.** Copy `templates/mockup/section-index.html` → `docs/mockups/flows/index.html`. Substitute `{{SECTION_NAME}}="Flows"`, `{{SECTION_TIER}}` from PLAN.md Phase 4 row, `{{SECTION_DESCRIPTION}}="User-journey walkthroughs across multiple screens."`. One card per flow with inline preview = chain of step pills (e.g., `<span class="step">scan</span> → <span class="step">review</span>`). Live cards link to flow walkthrough HTML; planned flows are non-interactive `<div>` blocks.
6. **Emit section spec.** Copy `templates/mockup/tests/mockups/section-smoke.spec.ts.tmpl` → `tests/mockups/flows.spec.ts`. Fill `{{SECTION_NAME}}="Flows"`, `{{SECTION_SLUG}}="flows"`, `{{ITEMS_ARRAY}}` with one entry per LIVE flow (planned flows skipped — they have no walkthrough file yet).
7. **Update principal hub.** Edit `docs/mockups/index.html`: locate `<a class="section-card" data-section="flows" ...>`, flip `data-status="placeholder"` → `data-status="live"`, replace `href="#"` with `href="flows/index.html"`, update card body with `<live count> live flows · <planned count> planned · Phase 4`.
8. **Update hub.spec.ts.** Add `"flows"` to the `LIVE_SECTIONS` array.
9. **Run `npm test`.** Verify principal hub + flows sub-hub + flows smoke specs pass.

**Exit criteria:** INDEX.md renders with 4+ populated tables. Flow HTMLs exist for every REQ that maps to a journey. CRUD matrix initialized (even if cells blank — filled progressively). Flows sub-hub renders 13+ flow cards. Principal hub Flows card flipped to live. `npm test` green.

### M5-M12 — Screen phases (`user-facing, ...`)

**Goal:** Per-section screens (auth / capture / data-view / analytics / groups / settings / edge-states) with desktop + mobile variants each.

**Steps per phase:**

1. **Read phase's REQs covered** from PLAN.md Phase Details.
2. **For each screen in phase scope:**
   a. **Wireframe first.** Emit `docs/mockups/wireframes/<screen>.html` with `data-slot` dropdowns — users pick component options per slot (header: topbar-sidebar / topbar-only / hero-nav; list: compact / spacious; footer: nav-bottom / none). See `templates/mockup/wireframe-template.html`.
   b. **User reviews wireframe + picks components.** Dropdown selection locks the wireframe layout.
   c. **Hi-fi render.** Emit `docs/mockups/screens/<screen>-desktop.html` + `<screen>-mobile.html`. Include tokens.css + Tweaks panel + state-tabs if multi-state.
   d. **Update INDEX.md §3** row with both platform file paths.
   e. **Update INDEX.md §4 CRUD row(s)** for any entity this screen touches.
   f. **Update INDEX.md §5** component usage per screen.
3. **Mid-phase commit-gate.** After every 3-5 screens, `/gabe-commit` chain fires — CHECK 7 Layer 4 surfaces INDEX.md sync warning if missed.
4. **Phase-exit validation gate.** After the last screen lands, dispatcher auto-runs `node tests/mockups/validate/runner.mjs --screens=<phase-screens>` to populate `.kdbp/MOCKUP-VALIDATION.md` with C1–C4 findings. User triages inline (f/d/x/s/e/q action keys per finding) OR passes `--skip-validation` to the next `/gabe-mockup` invocation to defer. Gate is *review-or-defer*, not *must-fix-to-proceed*. See Shared conventions → Validation gates — screen-level, and Modes → `validate`.

**Frame rules:** See Shared conventions → Per-platform frame rules above. No stacked frames. State-tabs for multi-state.

**Exit criteria:** every screen in phase scope has desktop + mobile variants. INDEX.md rows populated. Coverage gaps reduced (visible in INDEX.md §6).

### M13 — Handoff + index hub + audit (`mockup-docs, mockup-validation`)

**Goal:** Emit `HANDOFF.json` against schema + complete audit + a11y pass.

**Steps:**

1. **Assemble HANDOFF.json** at `docs/mockups/HANDOFF.json`. Schema at `~/.claude/templates/gabe/mockup/HANDOFF.schema.json` (Apache-2.0 derivative of impeccable DESIGN.json v2). Fields:
   - `schemaVersion`, `generatedAt`, `title`
   - `colors{}` — every token with role, displayName, description, tonalRamp
   - `typography{}` — per role (display / headline / title / body / label / micro-label): fontFamily, fontSize, fontWeight, lineHeight, letterSpacing
   - `spacing{}`, `radii{}`, `motion{easing, durations}`
   - `components{}` — every atom + molecule with anchor path, states[], rules[]
   - `platformVariance[]` — notes per platform
2. **Validate** against schema (Ajv or jsonschema in Python). Emit validation report.
3. **Complete INDEX.md §6 Coverage gaps.** Cross-check REQ×screen (every REQ has ≥1 screen or explicit not-user-facing tag), cross-screen token parity, component library completeness.
4. **A11y pass.** WCAG AA contrast verification per token pairing (use `color.js` or similar). Focus-ring visible on every interactive. Screen-reader walkthrough recorded at Scale tier.
5. **Write `SCREEN-SPECS.md`** — per-screen: REQ coverage, components used, states documented, data shape stub.
6. **Update INDEX.md §1 Decisions log** with M13 audit entries + D-id link to DECISIONS.md.

**Exit criteria:** HANDOFF.json validates, INDEX.md §6 shows 0 gaps OR documented exceptions, SCREEN-SPECS.md complete, a11y table present. Phase Exec → ✅.

---

## Error recovery

- **Missing canonical tokens CSS** during M2+ phase → recipe aborts with `⚠ M1 not complete — no stylesheet in docs/mockups/assets/css/ defines [data-theme="X"] selectors. Run /gabe-mockup M1 first or --reconfigure.`
- **Atom referenced in molecule but not in atoms/** → recipe surfaces which atom missing + asks to back-port.
- **Screen references molecule not in molecules/** → same surfacing, back-port pattern.
- **ENTITIES.md absent at M4** → recipe creates from template, prompts user to review entity list before populating CRUD.
- **Tier-cap violation** (e.g., MVP-tier phase tries to land multi-theme runtime) → recipe flags + offers escalation prompt (same mechanic as `/gabe-execute` Step 4.1).

## Non-goals

- Does NOT validate a11y contrast automatically during M2-M12 — that's M13's job (explicit audit phase).
- Does NOT auto-generate screens from flows — flow → wireframe → hi-fi is user-gated at each step.
- Does NOT port pixel-perfect screens from Figma — screens are HTML-first reference, not Figma parity.
- **Phase recipes (M0-M13) do NOT couple to any specific framework** — output is vanilla HTML + CSS vars + minimal vanilla JS (tweaks.js only). React port is a separate concern, opt-in via the `spike` mode (see "Modes" above).
- Does NOT couple to any specific tokens filename — tweaks.js detects themes from whichever stylesheet exposes `[data-theme="X"]` selectors. Greenfield projects use `assets/css/tokens.css`; legacy ports may retain their existing shell filename.
- **`validate` mode does NOT block phase advancement** — the inline gate at M5–M12 exit is *review-or-defer*. Findings stay pending in `.kdbp/MOCKUP-VALIDATION.md` until triaged; passing `--skip-validation` to the next `/gabe-mockup` call advances the ladder regardless. Conscious choice: prevent gate friction from grinding iterative screen work to a halt.
- **`validate` mode does NOT do pixel-level visual diffing.** That's a separate `visual-diff` mode for a future pass. C1–C4 are layout-sanity heuristics (overflow, narrow columns, empty content, KDBP rule binding), not screenshot comparison.

---

## Appendix — Bench-test verification

After modifying any M0/M2/M3/M4 recipe or any template under `templates/mockup/`, run a clean bench-test to verify recipes still produce a working scaffold:

```bash
TMP=$(mktemp -d)
cd "$TMP"
git init -q && mkdir -p .kdbp docs

# Minimal BEHAVIOR.md
cat > .kdbp/BEHAVIOR.md <<EOF
---
name: bench-mockup
project_type: mockup
---
EOF

# Run /gabe-mockup (or manually invoke M0 recipe per SKILL.md above)
# Then verify M0 scaffold landed:
ls docs/mockups/index.html docs/mockups/INDEX.md package.json playwright.config.ts \
   tests/mockups/hub.spec.ts tests/mockups/tweaks.spec.ts

# Install + run smoke (no atoms yet, but hub + tweaks specs pass / skip gracefully)
npm install
npx playwright install chromium
npm test  # expect: hub spec live-section check skipped (zero live), tweaks specs pass
```

After the M0 scaffold passes, exercise M2 atoms recipe with mock data:

```bash
# Manually invoke M2 atoms recipe → expect new files:
ls docs/mockups/atoms/index.html docs/mockups/atoms/*.html tests/mockups/atoms.spec.ts
# Check principal hub flipped:
grep 'data-section="atoms" data-status="live"' docs/mockups/index.html
# Re-run npm test:
npm test  # expect: atoms sub-hub spec passes, atoms smoke spec passes
```

**Regression guard against gastify** (the Layer A reference implementation):

```bash
cd /home/khujta/projects/apps/gastify
npm test  # must still show all green; if not, the template extraction over-generalized
```

Failure modes to budget for:
- Sanitization regex misses a project-specific reference → bench scaffold inherits original branding. Fix: re-grep for the source project name after each template write.
- `D6` tweaks spec generalization breaks the visible-effect assertion → re-verify by running gastify's `tests/mockups/tweaks.spec.ts` after the template extraction.
- M0 idempotency bug — running `/gabe-mockup` twice clobbers user edits. Fix: every copy step does an `if exists, skip` check.
