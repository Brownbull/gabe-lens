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

**Desktop screens:**

| Scenario | Behavior |
|---|---|
| Single-state | No phone frame. Edge-to-edge inside page. Top bar (60px) per `DESKTOP-TEMPLATE.md`. Content scrolls natively |
| Multi-state | State-tabs secondary bar below top bar. JS toggle same as mobile |

---

## Phase recipes

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

**Exit criteria:** every atom self-contained, loads canonical tokens CSS + tweaks.js, renders all its states via Tweaks-driven state-tabs. `INDEX.md` atoms catalog exists.

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

**Exit criteria:** `state-tabs.html` molecule exists + is the canonical pattern. COMPONENT-LIBRARY.md complete.

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

**Exit criteria:** INDEX.md renders with 4+ populated tables. Flow HTMLs exist for every REQ that maps to a journey. CRUD matrix initialized (even if cells blank — filled progressively).

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
- Does NOT couple to any specific framework (React / Vue / Svelte) — output is vanilla HTML + CSS vars + minimal vanilla JS (tweaks.js only).
- Does NOT couple to any specific tokens filename — tweaks.js detects themes from whichever stylesheet exposes `[data-theme="X"]` selectors. Greenfield projects use `assets/css/tokens.css`; legacy ports may retain their existing shell filename.
