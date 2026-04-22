---
name: gabe-plan
description: "KDBP-aware planning with lifecycle management + tier decision per phase (MVP/enterprise/scale). Creates plans in .kdbp/PLAN.md, detects active plans, archives completed/deferred/cancelled plans. Usage: /gabe-plan [goal] [--full-catalog]"
---

# Gabe Plan

KDBP-aware planner. Same planning logic as `/plan`, but persists to `.kdbp/PLAN.md` with lifecycle management + per-phase tier decision (MVP / Enterprise / Scale) with trade-off matrix.

> **Rendering note.** Output templates in this spec wrapped in bare triple-backtick fences are spec-meta delimiters — render their contents as plain markdown at runtime. Tagged fences (```yaml, ```json, ```bash) stay fenced. See `gabe-docs/SKILL.md` § "Runtime output rendering convention".

**Flags:**

| Flag | Meaning |
|------|---------|
| `--full-catalog` | Skip Layer 2 LLM dimension filter. Render ALL dimensions of matched sections. Default: filtered. |

## Procedure

### Step 0: Validate KDBP

1. Check `.kdbp/` exists. If not: "No KDBP found. Run `/gabe-init` first or use `/plan` for a stateless plan." — stop.
2. If `.kdbp/archive/` doesn't exist, create it.
3. If `.kdbp/PLAN.md` doesn't exist, create it from template.

### Step 1: Check for active plan

Read `.kdbp/PLAN.md`. If it contains `status: active`:

1. Show the active plan summary:
   ```
   ACTIVE PLAN DETECTED:
     Goal: [goal from plan]
     Phase: [current phase]
     Created: [date]
     Last Updated: [date]
   ```

2. Ask: "What do you want to do with the current plan?"
   - `[complete]` — Archive as completed
   - `[defer]` — Archive as deferred + add to PENDING.md
   - `[cancel]` — Archive as cancelled
   - `[continue]` — Keep working on current plan (stop gabe-plan, don't create new)
   - `[replace]` — Archive as cancelled + create new plan

3. Execute the chosen action (see Step 6 for archive mechanics).

4. If `continue`: stop here. If anything else: proceed to Step 2.

### Step 2: Gather context

1. Read `.kdbp/BEHAVIOR.md` for `maturity`, `domain`, `tech`.
2. If no goal in $ARGUMENTS, ask: "What are you planning to build or change?"
3. Read `.kdbp/PENDING.md` — surface any open items related to the goal (show max 5).

### Step 3: Plan

Execute the standard planning process:

1. **Restate requirements** — Clarify what needs to be built, in context of the project domain and maturity.
2. **Break into phases** — Specific, actionable steps. Each phase has:
   - Name
   - Description (one sentence)
   - Key files likely affected
   - Estimated complexity: low / medium / high
   - **Types** — phase type tags (drives Step 3.5 section assembly). Examples: `[ai-agent, integration]`, `[data-migration, multi-tenant]`, `[user-facing, client-state]`. See `~/.claude/templates/gabe/tier-sections/tier-section-index.md` for canonical tag list.
3. **Identify dependencies** between phases.
4. **Assess risks** — Flag anything that could block progress.
5. **Present the plan** and WAIT for user confirmation.

If user says "modify": adjust and re-present. If "no" or "cancel": stop without writing.

### Step 3.5: Tier decision per phase — MVP / Enterprise / Scale

After the user confirms the phase list (Step 3), run the tier-decision flow **per phase in order**. This is the premature-optimization gate — every phase picks a tier, sees the trade-offs explicitly, and logs what is being traded away.

**Rationale:** Code at the wrong tier rots fast. Over-engineered MVPs become unmaintainable; under-engineered Scale phases leak data. The tier decision makes the choice active and logged, not implicit and forgotten. Aligns with user value U2 (Plan Light, Build Real).

#### 3.5.1 — Assemble the matrix per phase

For each phase:

1. **Read phase `types: [...]` tag list.**
2. **Load section files:**
   - Always: `~/.claude/templates/gabe/tier-sections/core.md`
   - For each matched tag, load the corresponding section file per `tier-section-index.md` mapping.
3. **Layer 2 — Dimension filter (skip if `--full-catalog` flag set):**
   - LLM (Haiku, cheap per U6) reads phase Description + types + typical code signals → picks relevant dimensions per non-Core section.
   - **Core always renders all 4 dimensions unfiltered.** Layer 3 rule.
   - Suppressed dimensions logged to DECISIONS.md (see 3.5.4) with one-line reason each.
4. **Grade override (Layer hybrid):**
   - LLM may re-score any Δ cell per phase context. Default Δ stays unless LLM has specific reason (phase is bigger-than-typical, unusual risk, etc.).
   - Each override logged to DECISIONS.md with reason.
5. **Prototype-tag detection:** Ask user `Is this phase a throwaway prototype? [y/N]`. Default: no. If `y`, apply Δ shift per `tier-delta-scale.md` (XL→L, L→M, M→S, S→S floor).

#### 3.5.2 — Render the decision prompt

Render combined matrix. Each section gets its own 6-col table (Dimension | MVP | Δ(M→E) | Enterprise | Δ(E→S) | Scale). Row width enforced at 110 chars (20/20/6/20/6/19 content budget). Section files already obey this; renderer must not widen.

Render format:

```
PHASE N — [phase name]
TYPES: [tag list]
PROTOTYPE: [yes|no]

SECTION: Core
| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Testing              | happy path           | L      | + edges              | M      | + fuzz + load eval  |
| ...

SECTION: [section name]
| ... dimensions filtered per 3.5.1 step 3 ...

[more sections ...]

────────────────────────────────────────────────────────────────────────────────────────────────────
Effort (rough)      | 2h                   |        | 1d                   |        | 3d+                 |
Net Δ deferred      | 0                    |        | [L × n, XL × n]      |        | [L × n, M × n]      |

Pick tier: [mvp | enterprise | scale]
Default: mvp (cheap, honest baseline — escalation requires reason).

Reason (optional):
```

**Effort footer guideline:**
- MVP: 1-4h typical
- Enterprise: 1-3d typical
- Scale: 3d+ typical

Numbers are reference, not oracle. LLM tailors per phase complexity.

**Δ deferred rollup:** Sum all Δ(M→E) cells for MVP column, all Δ(E→S) for Enterprise column. Shows what's being traded for the faster tier. "MVP: L × 4, XL × 2 deferred" means picking MVP accepts 4 Large and 2 Critical risks.

#### 3.5.3 — User picks tier

Wait for user input:
- `mvp` / `enterprise` / `scale` — tier selected
- `--full-catalog` typed inline — re-render without Layer 2 suppression, user picks again
- `show-all` — alias for `--full-catalog`
- `edit-types` — user revises phase types, restart from 3.5.1
- `abort` — exit /gabe-plan without writing PLAN.md

**Default recommendation:**
- If user types nothing or `default`: recommend **mvp**. Cheap, honest, escape hatch always available via escalation at execute time.

**Escalation reason required for Enterprise + Scale:**
- If user picks `enterprise` or `scale`, prompt: "Why this tier over mvp? (one sentence)"
- Reason goes to DECISIONS.md for audit. Blocks silent over-engineering.

**De-escalation free:**
- `mvp` pick needs no justification. "Plan light, build real" default.

#### 3.5.4 — Log to DECISIONS.md

Append one entry per phase:

```markdown
## D[next_id] — Phase [N] tier: [chosen] (YYYY-MM-DD)

**Phase:** [phase name]
**Types:** [tag list]
**Tier chosen:** [mvp | enterprise | scale]
**Prototype:** [yes | no]
**Reason:** [user reason, or "default MVP pick per U2" if mvp with no reason]

### Sections rendered
- Core (always)
- [section X]: [N dims, M suppressed] → see "Dimensions suppressed" below

### Dimensions suppressed (Layer 2 filter)
- [section.dim] — reason: [LLM reason]
- [section.dim] — reason: [LLM reason]

### Grade overrides (if any)
- [section.dim].Δ(M→E): default [X] → override [Y]. Reason: [LLM reason]

### Δ deferred by tier choice
- L × [count], XL × [count], M × [count], S × [count]
- Load-bearing items skipped (Δ = XL or L on M→E if mvp chosen):
  - [section.dim]: [consequence phrase from Scale column]

### Review trigger (when to escalate this phase)
- [suggested condition — e.g., "when prod traffic > 100 req/day", "when 2nd incident hits", "when we add 3rd integration partner"]

### Status
- accepted
```

`D[next_id]`: read DECISIONS.md, compute max existing ID + 1. If file missing, start at `D1`.

#### 3.5.5 — Store tier in PLAN.md phase row

PLAN.md Phases table now includes `Tier` column (see Step 4 template). Write the chosen tier into the row.

Also write a `## Phase Details` block per phase with:
- Types list
- Tier chosen
- Prototype flag
- Sections considered
- Suppressed dimensions count
- Link to DECISIONS.md entry (`See D[id] for accepted trade-offs`)

### Step 4: Write plan to `.kdbp/PLAN.md`

Only after user confirms. Write with this structure:

```markdown
# Active Plan

<!-- status: active -->

## Goal

[One sentence goal]

## Context

- **Maturity:** [from BEHAVIOR.md]
- **Domain:** [from BEHAVIOR.md]
- **Created:** [YYYY-MM-DD]
- **Last Updated:** [YYYY-MM-DD]

## Phases

| # | Phase | Description | Tier | Complexity | Exec | Review | Commit | Push |
|---|-------|-------------|------|------------|------|--------|--------|------|
| 1 | [name] | [description] | mvp | low/med/high | ⬜ | ⬜ | ⬜ | ⬜ |
| 2 | [name] | [description] | ent | low/med/high | ⬜ | ⬜ | ⬜ | ⬜ |
| 3 | [name] | [description] | scale | low/med/high | ⬜ | ⬜ | ⬜ | ⬜ |

<!-- Exec is written by /gabe-execute: ⬜ not started, 🔄 in progress, ✅ complete -->
<!-- Review/Commit/Push auto-ticked by /gabe-review, /gabe-commit, /gabe-push -->
<!-- A phase is complete when all four status columns are ✅ -->
<!-- /gabe-next routes to the next command based on column state (Exec → Review → Commit → Push → advance phase) -->
<!-- Tier column values: mvp | ent | scale. Read by /gabe-execute (tier-cap) and /gabe-review (TIER_DRIFT finding). -->
<!-- Manual override is fine — edit cells by hand any time -->
<!-- Legacy plans with a single Status column still work; auto-tick is a silent no-op -->
<!-- Legacy plans without Tier column: /gabe-execute reads tier=mvp default; /gabe-review skips TIER_DRIFT silently -->

## Phase Details

### Phase 1 — [name]
- **Types:** [tag list, e.g. `ai-agent, integration`]
- **Tier:** [mvp | ent | scale]
- **Prototype:** [yes | no]
- **Sections considered:** Core, [matched sections]
- **Suppressed dimensions:** [count, or "none" if --full-catalog was used]
- **Trade-offs accepted:** See DECISIONS.md [D-id]

### Phase 2 — [name]
...


## Current Phase

Phase 1: [name]

## Dependencies

- [phase X depends on phase Y because...]

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| [risk] | high/medium/low | [mitigation] |

## Notes

[Any additional context from the planning conversation]
```

### Step 5: Log to LEDGER.md

Append to `.kdbp/LEDGER.md`:

```
## [YYYY-MM-DD HH:MM] — PLAN CREATED: [goal]
PHASES: [N] | COMPLEXITY: [overall] | MATURITY: [project-level from BEHAVIOR.md]
TIERS: mvp × [n], ent × [n], scale × [n] | PROTOTYPES: [n]
DECISIONS: D[first] → D[last] ([N] phase tier decisions logged)
```

Tier distribution gives a quick read on "how much we're trying to do." A plan of 6 phases with 5 scale + 1 ent is a warning sign — over-scoping detectable at plan creation, before code hits.

### Step 6: Archive mechanics

When archiving a plan (from Step 1 or when completing later):

**6a. Build archive filename:**
```
.kdbp/archive/{prefix}_PLAN_{YYYY-MM-DD}_{slug}.md
```
- `prefix`: `completed`, `defer`, or `cancelled`
- `slug`: 2-4 word slug from the plan goal (lowercase, hyphens)
- Example: `.kdbp/archive/completed_PLAN_2026-04-15_add-auth-pipeline.md`

**6b. Move the plan:**
- Copy `.kdbp/PLAN.md` content to the archive file
- Change `<!-- status: active -->` to `<!-- status: {prefix} -->`
- Add `## Archived` section at the bottom:
  ```
  ## Archived
  - **Resolution:** completed | deferred | cancelled
  - **Date:** [YYYY-MM-DD]
  - **Reason:** [user's reason if given, or "Goal achieved" for completed]
  ```
- Reset `.kdbp/PLAN.md` to the empty template:
  ```markdown
  # Active Plan

  <!-- status: none -->
  <!-- When no plan is active, this file stays as-is. gabe-plan writes here. -->
  <!-- Archived plans go to .kdbp/archive/ with prefix: completed_, defer_, cancelled_ -->

  No active plan. Run `/gabe-plan [goal]` to create one.
  ```

**6c. For `defer` only — add to PENDING.md:**

Add a row to `.kdbp/PENDING.md`:

| # | Date | Source | Finding | File | Scale | Priority | Impact | Times Deferred | Status |
|---|------|--------|---------|------|-------|----------|--------|----------------|--------|
| P[N] | [date] | gabe-plan | Plan deferred: "[goal]" | .kdbp/archive/defer_PLAN_...md | [maturity] | [ask user: high/medium/low, default medium] | [ask user: high/moderate/low, default moderate] | 1 | open |

**6d. Log to LEDGER.md:**

```
## [YYYY-MM-DD HH:MM] — PLAN {COMPLETED|DEFERRED|CANCELLED}: [goal]
ARCHIVE: .kdbp/archive/{filename}
PHASES COMPLETED: [N of M]
```

### Step 7: Show result

```
GABE PLAN: [goal]

STATUS: ✅ Plan written to .kdbp/PLAN.md
PHASES: [N] phases | Current: Phase 1 — [name] (tier: [mvp/ent/scale])
TRACKERS: Exec ⬜ | Review ⬜ | Commit ⬜ | Push ⬜ (auto-ticked as phases advance)
TIERS: mvp × [n], ent × [n], scale × [n] | PROTOTYPES: [n]
DECISIONS: D[first] → D[last] logged (per-phase tier trade-offs)
LEDGER: ✅ logged

Next steps:
  1. Start Phase 1 — [brief description] — tier [mvp/ent/scale]
  2. Run /gabe-execute to implement. Tasks capped to chosen tier.
  3. Escalate mid-phase via /gabe-execute if tier underscoped (logged to DECISIONS.md).
  4. Run /gabe-plan when done to archive as completed.
```

### Updating an active plan mid-work

If the user runs `/gabe-plan update` or `/gabe-plan status`:

- **`update`**: Read `.kdbp/PLAN.md`, ask what changed, update the plan in-place, bump `Last Updated` date, log to LEDGER:
  ```
  ## [date] [time] — PLAN UPDATED: [goal]
  CHANGE: [brief description of what changed]
  ```

- **`status`**: Read `.kdbp/PLAN.md`, show current state:
  ```
  PLAN STATUS: [goal]
  Phase: [current] of [total]
  Completed: [list]
  Remaining: [list]
  Last Updated: [date] ([N days ago])
  ```
  If last updated >14 days ago, add: "⚠ Plan may be stale. Run `/gabe-plan update` to refresh."

---

## Shared: auto-tick phase column (used by /gabe-execute, /gabe-review, /gabe-commit, /gabe-push)

This logic is invoked by the four trigger commands to update the Phases table in `.kdbp/PLAN.md` when a phase gate passes. Idempotent and silent on mismatch.

### Procedure

1. **Preconditions (all must hold; otherwise exit silently, no error):**
   - `.kdbp/PLAN.md` exists
   - File contains `<!-- status: active -->`
   - File contains a `## Current Phase` section
   - The Phases table header includes the target column name (`Exec`, `Review`, `Commit`, or `Push`) — **detection is by column name, not position**. If the plan uses the legacy `Status` column, this logic no-ops so old plans keep working. If the `Exec` column is missing on a pre-v2.9 plan, `/gabe-execute` auto-tick is a silent no-op.

2. **Find the target row:**
   - Parse `## Current Phase` — extract the leading integer N from a line like `Phase 3: [name]`
   - In the Phases table, locate the row where the first data column equals N

3. **Tick the cell:**
   - Target column is determined by caller: `Exec` / `Review` / `Commit` / `Push`
   - For `Review` / `Commit` / `Push`: binary ⬜ → ✅. If already `✅`, exit silently (idempotent).
   - For `Exec`: tri-state ⬜ → 🔄 → ✅. Caller passes the target state (`start` writes 🔄, `complete` writes ✅). If already at or past the target state, exit silently.

4. **Bump Last Updated:**
   - In the Context section, replace the `- **Last Updated:** ...` line with today's date (`YYYY-MM-DD`)

5. **Exit. Do NOT:**
   - Advance the Current Phase (manual via `/gabe-plan update` or automatic via `/gabe-next`)
   - Log to LEDGER.md from this helper (callers already log their primary action)
   - Modify any other column or row

### Implementation note

Keep this logic local to each command (short awk/sed block ~15 lines). Duplication is clearer than indirection here. A shared shell script would need to be installed alongside the commands, which adds install complexity for a small benefit.

---

### Staleness detection

When reading PLAN.md at Step 1, also check `Last Updated`:
- >14 days: show `⚠ Plan last updated [N] days ago`
- >30 days: show `⚠ STALE PLAN — last updated [N] days ago. Consider: [complete] [defer] [cancel] [update]`

### Scope integration (if SCOPE.md + ROADMAP.md exist)

When `.kdbp/SCOPE.md` and `.kdbp/ROADMAP.md` exist (project scoped via `/gabe-scope`):

1. **Read ROADMAP.md first.** Find target phase by ID (integer or decimal). Extract `Goal`, `Why (business intent)`, `Depends-on`, `Parallel-with`, `Covers REQs`.
2. **Read SCOPE.md REQ blocks.** For each REQ-NN in Covers REQs, read `Description` + `Acceptance signal` at anchor `{#req-NN}`.
3. **Use as plan context.** Each REQ's Acceptance signal becomes a mandatory verification item in the Current Phase's plan. Goal-backward: plan must produce evidence satisfying every Covers REQ's acceptance.
4. **Constraint check.** Read SCOPE.md §9 Constraints + §10 Architecture Posture. Plan must align with declared tech stack, budget, topology.
5. **Dependency gate.** If phase is `pending` but any Depends-on phase is not `complete`, warn and ask whether to proceed anyway.

**Refusal cases:**
- SCOPE.md `status: pivoted` — confirm which version to target before planning.
- ROADMAP.md references a phase ID absent from SCOPE.md — stale roadmap, suggest `/gabe-scope-change`.

**Never write** to SCOPE.md or ROADMAP.md. PLAN.md is the only write target.

$ARGUMENTS
