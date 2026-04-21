---
name: gabe-plan
description: "KDBP-aware planning with lifecycle management. Creates plans in .kdbp/PLAN.md, detects active plans, archives completed/deferred/cancelled plans. Usage: /gabe-plan [goal]"
---

# Gabe Plan

KDBP-aware planner. Same planning logic as `/plan`, but persists to `.kdbp/PLAN.md` with lifecycle management.

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
3. **Identify dependencies** between phases.
4. **Assess risks** — Flag anything that could block progress.
5. **Present the plan** and WAIT for user confirmation.

If user says "modify": adjust and re-present. If "no" or "cancel": stop without writing.

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

| # | Phase | Description | Complexity | Exec | Review | Commit | Push |
|---|-------|-------------|------------|------|--------|--------|------|
| 1 | [name] | [description] | low/med/high | ⬜ | ⬜ | ⬜ | ⬜ |
| 2 | [name] | [description] | low/med/high | ⬜ | ⬜ | ⬜ | ⬜ |
| 3 | [name] | [description] | low/med/high | ⬜ | ⬜ | ⬜ | ⬜ |

<!-- Exec is written by /gabe-execute: ⬜ not started, 🔄 in progress, ✅ complete -->
<!-- Review/Commit/Push auto-ticked by /gabe-review, /gabe-commit, /gabe-push -->
<!-- A phase is complete when all four columns are ✅ -->
<!-- /gabe-next routes to the next command based on column state (Exec → Review → Commit → Push → advance phase) -->
<!-- Manual override is fine — edit cells by hand any time -->
<!-- Legacy plans with a single Status column still work; auto-tick is a silent no-op -->


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
PHASES: [N] | COMPLEXITY: [overall] | MATURITY: [mvp/enterprise/scale]
```

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
PHASES: [N] phases | Current: Phase 1 — [name]
TRACKERS: Review ⬜ | Commit ⬜ | Push ⬜ (auto-ticked by gabe-review/commit/push)
MATURITY: [mvp/enterprise/scale]
LEDGER: ✅ logged

Next steps:
  1. Start Phase 1 — [brief description]
  2. Run /gabe-review, /gabe-commit, /gabe-push as you progress — they tick the row
  3. Run /gabe-plan when done to archive as completed
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

$ARGUMENTS
