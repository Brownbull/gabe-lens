---
name: gabe-execute
description: "Execute the Current Phase of .kdbp/PLAN.md — implement tasks, checkpoint at commits, write Exec column state. Interactive commit checkpoints by default; auto mode with --auto-commit. Usage: /gabe-execute [task|all|<phase-number>] [--auto-commit] [--dry-run]"
---

# Gabe Execute

Executes phase tasks from `.kdbp/PLAN.md`. Complements `/gabe-plan` (write plan) and `/gabe-commit` (quality gate). This command owns the **implementation** step — reading the plan, writing code, checkpointing at commit boundaries, and advancing Exec state.

**Design principle — auto-run with commit checkpoints.** Between `/gabe-plan` and `/gabe-commit`, there's a gap: someone has to write the code. Before `/gabe-execute`, that someone was the human orchestrating raw prompts. Now the command reads Current Phase, runs all tasks in it, and checkpoints only at commit boundaries (per D2 decision — user-gated by default, `--auto-commit` batches).

**Scope default.** Single phase. Arg overrides: `task` = single next task only, `all` = all remaining phases (autonomous), `<N>` = jump to phase N regardless of Current Phase pointer.

## Procedure

### Step 0: Parse args + validate

Parse `$ARGUMENTS`:

| Token | Meaning |
|-------|---------|
| _(empty)_ | Execute Current Phase (default — per D1 recommend B) |
| `task` | Execute one task only, then stop |
| `all` | Execute all phases in order until plan complete (autonomous mode) |
| `<N>` (integer) | Execute phase N regardless of Current Phase pointer |
| `--auto-commit` | Skip per-task commit prompts, commit per task automatically (per D2 override A) |
| `--dry-run` | Print plan + proposed actions without writing code or committing |

**Preconditions:**

1. `.kdbp/` exists → else print `⚠ No KDBP. Run /gabe-init first.` and exit.
2. `.kdbp/PLAN.md` contains `<!-- status: active -->` → else print `ℹ No active plan. Run /gabe-plan [goal] first.` and exit.
3. Phases table includes `Exec` column → else print legacy warning and exit (do not auto-migrate; recommend `/gabe-plan update` or manual edit).

### Step 1: Load execution context

1. Read `.kdbp/PLAN.md`:
   - Current Phase pointer → integer N (or arg override)
   - Target phase row: Phase name, Description, Complexity, Exec state
   - Scope section (if present) → list of Modified/New files
   - References section → docs/code pointers for this phase
   - Checkpoint section → verification commands
2. Read `.kdbp/BEHAVIOR.md`:
   - `maturity` (mvp/enterprise/scale) — gates test strictness
   - `execute_default_mode: interactive | auto` (optional, default `auto`)
3. Read `.kdbp/KNOWLEDGE.md` Gravity Wells table — determine which well(s) this phase touches (informational, appears in commit body).
4. Read `.kdbp/PENDING.md` — surface any open items whose `File` matches target phase's Scope files (informational prompt before starting).

### Step 2: Decompose phase into tasks

A phase row in PLAN.md is one-line per step. Real execution needs finer granularity. Decompose the phase into tasks by reading the phase's Description + Scope + References:

**Deterministic decomposition heuristics (no LLM needed):**

1. If phase description contains comma-separated or semicolon-separated atomic actions → each is a task
2. If Scope lists distinct files with distinct purposes → each file's work is a task
3. If References points to multiple external specs → each spec mapping is a task
4. Otherwise: single-task phase (the whole phase is one task)

**LLM decomposition** (only if heuristics yield <2 or >10 tasks):

- Prompt: "Given this phase description + scope + references, list 2-6 tasks that cover it. Each task must be independently testable and committable."
- Model: Haiku (cheap classification, per U6 value)
- Output: numbered list of tasks

**Present the task list** to the user with the Universal Action Menu on first phase only:

```
GABE EXECUTE — Phase N: [name]
EXEC STATE: ⬜ → 🔄
COMPLEXITY: [low/medium/high]
TASKS ([K]):
  T1. [task description]
  T2. [task description]
  T3. [task description]

CHECKPOINT CADENCE: per-task (D2.C default) | per-phase (--auto-commit)
PENDING ITEMS IN SCOPE: [N or none]

Proceed? [go] / [edit-tasks] / [abort]
```

- `go` → begin Step 3
- `edit-tasks` → user edits task list inline, re-present
- `abort` → exit without state change

### Step 3: Tick Exec → 🔄

Before writing any code, update PLAN.md Exec cell to `🔄` for the target row. Use shared auto-tick procedure from `/gabe-plan` with target state = `start`. Bump Last Updated.

### Step 4: Execute tasks

For each task T_i in order:

1. **Announce task:**
   ```
   ▶ T[i]/[K]: [description]
   ```

2. **Implement:**
   - Write/edit files per task scope
   - Follow project conventions (read CLAUDE.md, existing patterns)
   - Respect Scope section — only modify listed files unless deviation flagged (Step 6)

3. **Run task-local verification:**
   - Lint the changed files (project tool from BEHAVIOR.md: ruff / biome / etc)
   - Types on changed files
   - Unit tests that exercise changed code (scoped, not full suite)
   - If verification fails → fix in-loop, retry up to 2 times, then halt with `[retry] / [skip-task] / [abort]`

4. **Checkpoint (D2 decision):**
   - Default (interactive, no `--auto-commit`):
     ```
     T[i] verification ✅

     Files changed:
       - app/agent/triage.py (+42 / -8)
       - tests/test_triage.py (+28 / -0)

     [commit] — run /gabe-commit for this task
     [continue] — proceed to T[i+1] without committing (batch later)
     [stop] — halt phase exec here, keep Exec=🔄
     ```
   - Auto mode (`--auto-commit`): proceed to commit without prompt. Skip to Step 4.5.

4.5. **Commit (when user picks `commit` or `--auto-commit` active):**
   - Invoke `/gabe-commit` inline. Pass generated commit message subject + body (see Step 5).
   - If `/gabe-commit` blocks on findings → user resolves per normal gabe-commit triage. Exec resumes after commit returns 0.
   - If user picks `defer` on a gabe-commit finding → it lands in PENDING.md, Exec continues.

### Step 5: Commit message enrichment (D2 — gabe-lens brief + before/after)

When `/gabe-execute` generates a commit message, body includes:

```
<subject>: <conventional type(scope): one-line>

<paragraph 1: what changed — plain language, 1-2 sentences>

Before:
<3-6 line snippet or structured description of prior behavior>

After:
<3-6 line snippet or structured description of new behavior>

Phase: N — [phase name]
Task: T[i]/[K] — [task description]
```

**Generation rules:**

- **Subject**: Conventional commit (feat/fix/refactor/chore/etc). Derived from task description.
- **Paragraph 1 (gabe-lens brief)**: 1-2 sentence explanation of the *why* and *how it maps*. Uses gabe-lens analogy style only if the change is conceptual (not mechanical). Skip analogy for renames/moves/typo fixes.
- **Before / After**: Concrete contrast. For code changes: 3-6 lines of pseudocode or actual snippet showing the behavior delta. For config/docs: structured description (`"triage agent used rule-based keyword matching"` → `"triage agent uses PydanticAI with TriageResult output_type and 4-tier fallback"`).
- **Phase/Task footer**: Always appended. Makes retroactive phase reconstruction trivial.

**Model**: Haiku for mechanical changes (renames, moves, small refactors). Sonnet for conceptual changes (new pattern, new abstraction, architectural shift). Per U6 value — route by task complexity, never expose to user.

**Example body:**

```
feat(triage): wire PydanticAI agent with 4-tier fallback chain

Triage now enforces output shape mechanically via PydanticAI's output_type
rather than hoping the LLM returns valid JSON. A 4-tier fallback (regex
extract → rule-based → safe default) guarantees the pipeline never crashes
and never returns empty.

Before:
  result = triage_incident(title, desc)
  # rule-based keyword matching; returns None on mismatch

After:
  result = await run_triage(title, desc)
  # PydanticAI Agent(output_type=TriageResult, retries=2)
  # on exhaustion: regex-extract → rule-based → P3 safe default
  # tier fired logged via structlog tier=1|2|3|4

Phase: 2 — PydanticAI Agent
Task: T2/6 — New app/agent/triage_agent.py with Agent + fallback wrapper
```

### Step 6: Deviation handling (D3)

If during execution, the task reveals PLAN.md is incomplete, wrong, or needs restructure:

**Structural deviation (per D3.A — halt):**

Halt conditions — any of these:
- Task needs to split into 2+ tasks, changing phase task count
- New phase must be added (insert phase N.5 or append after current plan)
- Scope section needs new file not currently listed
- Phase dependency order is wrong (this phase needs something from a later phase)
- Risk surfaced that's not in Risks table

Halt prompt:
```
⚠ DEVIATION DETECTED (structural)
TASK: T[i] — [description]
ISSUE: [what's wrong with PLAN.md]

Options:
  [update-plan] — run /gabe-plan update inline, then resume exec
  [split-task]  — split T[i] into sub-tasks inline, continue this phase only
  [skip-task]   — skip T[i], mark as deferred in PENDING.md
  [abort]       — halt exec, leave Exec=🔄, manual intervention
```

**Minor deviation (per D3.C — log + continue):**

Log conditions — any of these:
- Task needs a small extra change not in Scope (e.g., update one import, add one constant)
- Implementation variance from Description (e.g., used dict not list, inlined vs helper)
- A Risk from the Risks table fired and was mitigated as documented

Action: Append to `.kdbp/DEVIATIONS.md` (create if missing). One line per deviation:

```
| Date | Phase | Task | Type | Note |
|------|-------|------|------|------|
| 2026-04-21 | 2 | T2 | scope-creep | Added retry import to pipeline.py (not in Scope) |
```

No prompt. Continue execution.

### Step 7: Phase complete

When last task T_K commits successfully:

1. Tick Exec cell: 🔄 → ✅ via shared auto-tick (target state = `complete`)
2. Bump Last Updated
3. Append to `.kdbp/LEDGER.md`:
   ```
   ## [YYYY-MM-DD HH:MM] — PHASE EXEC COMPLETE: Phase N — [name]
   TASKS: [K] tasks, [K] commits
   DEVIATIONS: [N structural, M minor] (see DEVIATIONS.md if any)
   ```
4. If scope arg was `all` → advance Current Phase to N+1 and re-enter Step 1. Else → print summary and exit:
   ```
   ✅ GABE EXECUTE — Phase N complete
   EXEC: ✅  REVIEW: ⬜  COMMIT: ✅  PUSH: ⬜

   Next: /gabe-review (unreviewed code) or /gabe-next to route automatically.
   ```

### Step 8: Interrupts + resume

If user aborts mid-phase (`stop`, `abort`, or Ctrl+C):

- Exec column stays at `🔄` — signals "in progress, not done"
- Committed tasks stay committed (don't revert)
- Next `/gabe-execute` invocation detects `🔄` state and prompts:
  ```
  ℹ PLAN: Phase N — [name] is in progress (Exec=🔄)
  Completed tasks: T1, T2
  Remaining: T3, T4, T5
  Resume? [resume] / [restart-phase] / [abort]
  ```

Never silently re-run completed tasks.

## Model + cost

Per U6 (Route by Task, Not by User):

| Decision | Model | Reason |
|----------|-------|--------|
| Task decomposition (when heuristics fail) | Haiku | Classification, cheap (~$0.001) |
| Code implementation | Sonnet | Main development work (best coding model) |
| Commit message — mechanical changes | Haiku | Rename/move/typo — trivial summarization |
| Commit message — conceptual changes | Sonnet | Gabe-lens brief + before/after analogy |
| Deviation severity classification | Haiku | Structural vs minor is a simple decision tree |

Per U8 (Measure the Machine): Append to `.kdbp/LEDGER.md` per-phase: `TOKENS: [input]+[output] ($[cost])`. Skip in dry-run.

## Non-goals

- Does NOT replace `/gabe-commit` — it invokes it
- Does NOT replace `/gabe-review` — surfaces findings via `/gabe-commit` which already runs deterministic checks
- Does NOT auto-push — that's `/gabe-push`
- Does NOT write architectural docs — `/gabe-teach` handles architect-level consolidation post-commit

## Example session

```
$ /gabe-execute
ℹ PLAN: Phase 2 — PydanticAI triage agent (Exec ⬜ → 🔄)
TASKS (3):
  T1. Upgrade TriageResult schema in app/agent/triage.py
  T2. New app/agent/triage_agent.py with Agent + fallback wrapper
  T3. Add pydantic-ai to pyproject.toml

Proceed? [go]

▶ T1/3: Upgrade TriageResult schema
[implementation happens]
T1 verification ✅

Files changed:
  - app/agent/triage.py (+42 / -8)

[commit] — Running /gabe-commit...
✅ commit ab12cd3 — feat(triage): upgrade TriageResult schema to V2

▶ T2/3: New app/agent/triage_agent.py
[...continues...]

✅ GABE EXECUTE — Phase 2 complete
EXEC: ✅  REVIEW: ⬜  COMMIT: ✅  PUSH: ⬜
Next: /gabe-review or /gabe-next
```

$ARGUMENTS
