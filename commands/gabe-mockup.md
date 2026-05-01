---
name: gabe-mockup
description: "Mockup/UX workflow command — peer to /gabe-execute, handles legacy HTML mockup phases and React + Storybook mockup work for React-first apps. On empty project: dispatches to /gabe-plan --preset=mockup-project. On active mockup plan: executes current phase via gabe-mockup skill playbook. Mutually redirects with /gabe-execute for wrong plan type. Usage: /gabe-mockup [goal|react-story <screen-or-batch>] [--reconfigure] [--dry-run] [--platforms=web,mobile-web,native-mobile] [--themes=N]"
---

# Gabe Mockup

Full command (not wrapper) — owns the Exec step for phases whose types fall inside the **mockup-tag set**: `{design-system, ui-kit, mockup-flows, mockup-index, mockup-docs, mockup-validation}`. Reads `.kdbp/PLAN.md`, routes to plan-creation or phase-execute based on state. `/gabe-execute` covers the code equivalent; the two mutually redirect.

**Design principle.** Mockup projects need different execution recipes than code projects. Legacy mockup projects still decompose into HTML/CSS render-then-audit cycles across platform variants. React-first projects decompose into real frontend components, screen compositions, traceable Storybook stories, option/spike stories, browser checks, and frontend tests. `/gabe-mockup` keeps the same PLAN.md state machine (Exec / Review / Commit / Push) but uses the `gabe-mockup/SKILL.md` playbook for the Exec step.

## Procedure

### Step 0: Parse args + validate

Parse `$ARGUMENTS`:

| Token | Meaning |
|-------|---------|
| _(empty)_ | Execute current phase OR start plan wizard if no active plan |
| _goal string_ | No active plan: create new mockup plan with goal. Active plan: appended as phase context |
| `--reconfigure` | Re-run M1 tokens/design-language phase from scratch |
| `--dry-run` | Print plan + proposed actions without writing files or committing |
| `--platforms=web,mobile-web,native-mobile` | Platform variants to produce per screen. Default `web,mobile-web`. Used by `--preset=mockup-project` emission |
| `--themes=N` | Number of candidate themes in M1. Default 3. Used by preset emission |
| `react-story <screen-or-batch>` | Implement a React-first screen or batch in `apps/web` with Storybook stories instead of new static HTML |

**Preconditions:**

1. `.kdbp/` exists → else print `⚠ No KDBP. Run /gabe-init first and pick project_type=mockup.` and exit.
2. If `.kdbp/PLAN.md` exists and `<!-- status: active -->` → parse `<!-- project_type: ... -->`:
   - `mockup` → proceed to Step 2 (execute phase).
   - `hybrid` → proceed to Step 1.5 (hybrid dispatch).
   - `code` → print `⚠ Code plan active — use /gabe-execute instead. To start a mockup plan, /gabe-plan replace first.` and exit 0.
3. If `.kdbp/PLAN.md` exists but `<!-- status: none -->` or file placeholder → proceed to Step 1 (plan creation).
4. If no PLAN.md → create from template and proceed to Step 1.

### Step 1: Plan creation (when no active plan)

Dispatch to `/gabe-plan --preset=mockup-project "$GOAL" --platforms=... --themes=...`. Pass remaining args through. `/gabe-plan` handles the interview, emits the 13-phase template, writes `<!-- project_type: mockup -->` to frontmatter. Returns here with `status: active`.

If `$ARGUMENTS` has no goal string: prompt `What are you designing? (one sentence — e.g., "Personal expense tracker dashboard + capture flows")`. Pass that to `/gabe-plan`.

After `/gabe-plan` completes, print `✓ Mockup plan created. Run /gabe-next to dispatch first phase.` and exit. Do NOT auto-execute — user reviews plan first.

### Step 1.5: Hybrid dispatch

When `project_type=hybrid`, route to Exec command based on target phase types:

1. Read Current Phase pointer → integer N.
2. Parse target row's types list from `Types` column OR `## Phase Details → Phase N → types:` YAML.
3. Apply rule: if `types ⊆ mockup-tag-set` → proceed to Step 2 (mockup execute). Else print `⚠ Phase N is code-type. Use /gabe-execute instead.` and exit 0.

Mockup-tag set: `{design-system, ui-kit, mockup-flows, mockup-index, mockup-docs, mockup-validation}`.

### Step 2: Load execution context

1. Read `.kdbp/PLAN.md`:
   - Current Phase pointer → integer N
   - Target phase row: Phase name, Description, Tier, Complexity, Exec state
   - `types` list for phase (drives skill playbook recipe selection)
   - Phase Details YAML → `phase_tier`, `dim_overrides`, `sections_considered`
2. Read `.kdbp/BEHAVIOR.md`:
   - `maturity`, `domain`, `tech` (informational — used by skill M1 recipe)
   - `project_type` (should match PLAN.md `project_type`)
3. Read `.kdbp/ENTITIES.md` if phase includes `mockup-index` type — CRUD matrix seed source.
4. Read `.kdbp/SCOPE.md` REQs list — referenced by screen-phase recipes to verify REQ coverage.
5. Load `gabe-mockup/SKILL.md` playbook (project-local at `skills/gabe-mockup/SKILL.md` OR global at `~/.claude/skills/gabe-mockup/SKILL.md` OR `~/.agents/skills/gabe-mockup/SKILL.md`).

### Step 2.5: React-first workflow detection

If `docs/rebuild/ux/REACT-STORYBOOK-WORKFLOW.md` and `apps/web/package.json` both exist, default new screen and batch work to the skill playbook's `react-story` mode unless the user explicitly requests legacy HTML. In this mode:

1. Do not create new `docs/mockups/**/*.html` files. Existing HTML is read-only visual reference/archive.
2. Read `docs/rebuild/ux/STORYBOOK-STRUCTURE.md` when present and treat it as the local taxonomy contract.
3. Implement production React/Tailwind UI in the physical taxonomy when adopted: shared pieces under `apps/web/src/design-system/{atoms,molecules,organisms}`, feature pieces under `apps/web/src/features/<area>/{components,screens,model,spikes}`, and stories beside the implementation.
4. Use `shared/design-tokens.ts` as the token source and extend `apps/web/tailwind.config.ts` from it.
5. Use Storybook as the mockup viewer and source-code correspondence map. Shared primitives and app chrome live under `Design System/`; product-specific pieces live under `Features/<Area>/Components`; composed screens live under `Features/<Area>/Screens`; active playgrounds live under `Features/<Area>/Spikes`; `Flows/` is only for real multi-screen journey stories.
6. Prefer one responsive screen implementation with curated mobile/tablet/desktop story snapshots and controls instead of separate per-platform screen implementations.
7. Use direct aliases such as `@app/*`, `@design-system/*`, `@features/*`, `@lib/*`, and `@shared/*` when the project defines them.
8. When the user asks to compare layouts or decide between approaches, create story-only options first and keep current production defaults unchanged until the user chooses.
9. When a screen area is uncertain, allow component-first spikes: isolated component stories, then a composed spike story, then wire the approved/recommended version into the real screen only when requested.
10. For shared chrome/component extraction, expose the contract in component stories before broadly rewriting screens.
11. Run the app verification gate from `apps/web`: `npm run typecheck`, `npm run build`, `npm run build-storybook`, and `npm run test-storybook`. If present, also run a Storybook navigation/browser smoke script such as `npm run test:storybook-navigation`, inspect `storybook-static/index.json` for taxonomy/source correspondence, and save screenshot evidence for visual changes, options, or spikes.

### Step 3: Dispatch to phase recipe

The skill playbook defines recipes keyed by phase `types`. Dispatch table:

| Phase types contain | Recipe | Output location |
|---------------------|--------|-----------------|
| React-first workflow marker + `apps/web/package.json` | React + Storybook recipe (`react-story`) | `apps/web/src/design-system/**`, `apps/web/src/features/**`, `*.stories.tsx`, Storybook config/scripts, browser-check evidence |
| `design-system` (M1) | Tokens + stress-test matrix recipe | `docs/mockups/{tokens.css, explorations/, stress-*.html}` |
| `design-system` + `ui-kit` (M2/M3) | Atoms / molecules recipe | `docs/mockups/{atoms,molecules}/` |
| `mockup-flows` + `mockup-index` (M4) | Flows + INDEX seed recipe | `docs/mockups/{flows/, INDEX.md}` + populate ENTITIES.md CRUD |
| `user-facing` AND (M5+) screen phases | Wireframe → hi-fi recipe | `docs/mockups/{wireframes/, screens/}` |
| `mockup-docs` + `mockup-validation` (M13) | Handoff + audit recipe | `docs/mockups/{HANDOFF.json, SCREEN-SPECS.md, COMPONENT-LIBRARY.md}` |

Each recipe:
1. Prints `GABE MOCKUP — Phase N: [name]` summary with tier / types / prototype flag
2. Lists artifacts to produce + referenced tokens / components / REQs
3. Offers `[go] / [edit-tasks] / [escalate] / [abort]` prompt (mirrors `/gabe-execute` Step 2 UI)
4. On `go`: execute per SKILL.md step-by-step
5. Writes Exec state `🔄` → `✅` on completion (same semantics as `/gabe-execute`)
6. Does NOT commit — hands off to `/gabe-commit` via `/gabe-next` chain

For React-first recipes, Step 3 dispatch also reports whether the work is:

- an implementation batch,
- an option-exploration batch,
- a component-first spike,
- or shared chrome/component extraction.

That intent determines whether production screens should be changed immediately or whether the output should stay in Storybook until the user chooses a direction.

### Step 4: uipro enrichment (optional, M1 only)

When phase is M1 (`design-system`) AND `~/.claude/skills/ui-ux-pro-max/` is installed AND phase is tier `mvp` or `ent`:

1. Skill invokes uipro `search.py` for candidate style families matching the project's goal + domain.
2. Results appended to the stress-test candidate list for user pick.
3. If uipro not installed → skip silently (no hard dependency).

Install prompt surfaces at `/gabe-init` time for `project_type=mockup|hybrid` projects. User can re-install later via `npx uipro-cli init --ai claude`.

### Step 5: `--reconfigure` mode

Walks the M1 design-language phase from scratch:
1. Archives existing `docs/mockups/tokens.css` to `docs/mockups/archive/tokens-YYYY-MM-DD.css`
2. Re-runs M1 recipe (stress matrix + token lock)
3. Updates PLAN.md P1 Exec state → `🔄` until user re-approves
4. Existing screens keep working (tokens.css always present at same path)

Intended for when user wants to swap theme families mid-project without restart.

### Step 6: `--dry-run` mode

Prints:

```
GABE MOCKUP (dry-run)
PROJECT_TYPE: mockup
PHASE: N — [name]
TYPES: [type list]
TIER: [mvp|ent|scale]
RECIPE: [recipe name from Step 3 table]
ARTIFACTS PLANNED:
  - docs/mockups/atoms/button-primary.html
  - docs/mockups/atoms/button-secondary.html
  ...
EXEC STATE: ⬜ → would advance to 🔄
```

No file writes. No state changes. Purely informational.

## Error surfaces

- No active plan + no goal arg → prompt for goal, dispatch to `/gabe-plan --preset=mockup-project`.
- `.kdbp/PLAN.md` project_type mismatch → mutual redirect per Step 0.
- Unknown phase type tag (outside mockup-tag-set AND outside `/gabe-execute` tag universe) → print `⚠ Phase N types [...] not recognized. Add trigger-tag mapping in ~/.claude/templates/gabe/tier-sections/tier-section-index.md` and exit.
- Missing `gabe-mockup/SKILL.md` playbook → print `⚠ Skill playbook missing. Reinstall gabe_lens or restore from git.` and exit.
- React-first marker present but `apps/web/package.json` missing → print `⚠ React Storybook mode requires apps/web/package.json. Use legacy HTML mode or scaffold the web app first.` and exit.
- React-first visual batch completes app checks but lacks browser evidence → print `⚠ React Storybook visual work requires mobile/tablet/desktop browser checks before marking the batch complete.` and leave Exec state incomplete.

## Non-goals

- Does NOT run linters, contrast checkers, or a11y validators directly — those belong to `/gabe-review` and `/gabe-commit` CHECK 7 Layer 4.
- Does NOT emit HANDOFF.json outside M13 phase — handoff is a dedicated phase, not a side effect of every phase.
- Does NOT auto-commit per artifact — same per-phase commit cadence as `/gabe-execute` (D2 default).
- Does NOT replace `/gabe-plan`, `/gabe-review`, `/gabe-commit`, `/gabe-push` — only the Exec step.

$ARGUMENTS
