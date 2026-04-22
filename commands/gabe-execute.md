---
name: gabe-execute
description: "Execute the Current Phase of .kdbp/PLAN.md — implement tasks, checkpoint at commits, write Exec column state. Interactive commit checkpoints by default; auto mode with --auto-commit. Usage: /gabe-execute [task|all|<phase-number>] [--auto-commit] [--dry-run]"
---

# Gabe Execute

Executes phase tasks from `.kdbp/PLAN.md`. Complements `/gabe-plan` (write plan) and `/gabe-commit` (quality gate). This command owns the **implementation** step — reading the plan, writing code, checkpointing at commit boundaries, and advancing Exec state.

**Design principle — auto-run with commit checkpoints.** Between `/gabe-plan` and `/gabe-commit`, there's a gap: someone has to write the code. Before `/gabe-execute`, that someone was the human orchestrating raw prompts. Now the command reads Current Phase, runs all tasks in it, and checkpoints only at commit boundaries (per D2 decision — user-gated by default, `--auto-commit` batches).

**Scope default.** Single phase. Arg overrides: `task` = single next task only, `all` = all remaining phases (autonomous), `<N>` = jump to phase N regardless of Current Phase pointer.

> **Rendering note.** Output templates in this spec wrapped in bare triple-backtick fences are spec-meta delimiters — render their contents as plain markdown at runtime. See `gabe-docs/SKILL.md` § "Runtime output rendering convention".

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
   - Target phase row: Phase name, Description, **Tier**, Complexity, Exec state
   - **Tier column lookup:**
     - If Tier cell = `mvp` / `ent` / `scale` → use it directly
     - If Tier cell missing (legacy plan, pre-v2.10) → default `mvp` silently. Do NOT prompt user mid-execute.
     - Prototype flag: read from `## Phase Details → Phase N → Prototype:` entry. Default: `no`.
   - Scope section (if present) → list of Modified/New files
   - References section → docs/code pointers for this phase
   - Checkpoint section → verification commands
2. Read `.kdbp/BEHAVIOR.md`:
   - `maturity` (mvp/enterprise/scale) — project-level baseline (separate from per-phase Tier)
   - `execute_default_mode: interactive | auto` (optional, default `auto`)
3. Read `.kdbp/KNOWLEDGE.md` Gravity Wells table — determine which well(s) this phase touches (informational, appears in commit body).
4. Read `.kdbp/PENDING.md` — surface any open items whose `File` matches target phase's Scope files (informational prompt before starting).
5. **Load tier cap heuristics** from `.kdbp/DECISIONS.md` (find the phase's D-id entry) OR from `~/.claude/templates/gabe/tier-sections/*.md` `## Tier-cap enforcement` blocks. Used by Step 4.1 escalation gate.

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

**Tier-cap filter:** Before presenting tasks, prune any task that introduces a pattern above the phase's declared tier unless the task description explicitly justifies the escalation. Tier cap heuristics come from each matched section's `## Tier-cap enforcement` block (loaded Step 1.5).

Examples of tier-cap pruning:
- Phase tier = `mvp` + task says "add DI container" → prune (DI = Scale per Core section). Either drop the task, or if load-bearing, surface as escalation candidate via Step 4.1 mid-phase escalation gate.
- Phase tier = `ent` + task says "add circuit breaker" → prune (circuit break = Scale per Core).
- Phase tier = `mvp` + task says "add structured-output fallback chain" → prune (fallback chain = Scale per AI/Agent).

The prune is informational, not silent — show pruned tasks under a separate `Tier-cap pruned (N):` list in the prompt below, so user can escalate if needed.

**Present the task list** to the user with the Universal Action Menu on first phase only:

```
GABE EXECUTE — Phase N: [name]
TIER: [mvp|ent|scale] (prototype: [yes|no])
EXEC STATE: ⬜ → 🔄
COMPLEXITY: [low/medium/high]
TASKS ([K]):
  T1. [task description]
  T2. [task description]
  T3. [task description]

Tier-cap pruned ([P]):
  [pruned task] — reason: [section.dim] is [Ent|Scale] tier
  [pruned task] — reason: ...

CHECKPOINT CADENCE: per-task (D2.C default) | per-phase (--auto-commit)
PENDING ITEMS IN SCOPE: [N or none]

Proceed? [go] / [edit-tasks] / [escalate] / [abort]
```

- `escalate` → jump to Step 4.1 mid-phase escalation gate to promote phase tier + reinstate pruned tasks.

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

### Step 4.1: Mid-phase tier escalation gate

Fires when any of:
- User picks `escalate` at the Step 2 Universal Action Menu
- During Step 4 implementation, a task genuinely requires a pattern above the declared tier (e.g., mvp phase but the external API is flaky enough that retry logic is load-bearing)
- A drift signal from `## Known drift signals` in a loaded section file fires during task implementation

**Escalation prompt:**

```
⚠ TIER ESCALATION REQUESTED — Phase N
CURRENT TIER: [current]
TRIGGER: [task T[i] requires / drift signal / user-requested]
DETAIL: [which section.dim forced the escalation, e.g. "AI/Agent.Structured output needs fallback chain"]

Promote to: [next] / [next+1] / [cancel]

Reason (required — one sentence):
```

**Promotion rules:**
- From `mvp`: may promote to `ent` or `scale`
- From `ent`: may promote to `scale`
- Reason is mandatory. Blank input is refused with: `Escalation requires a reason (one sentence). Silent escalation is not allowed.`

**On accept:**

1. **Update PLAN.md Phases table** — change Tier cell to new tier for phase N. Bump Last Updated.
2. **Append to DECISIONS.md** under the phase's existing D-entry (the one /gabe-plan wrote at Step 3.5.4):
   ```markdown
   ### Tier escalation — YYYY-MM-DD HH:MM
   - **From:** [old tier]
   - **To:** [new tier]
   - **Trigger:** [task T[i] / drift signal / user]
   - **Reason:** [user reason]
   - **Reinstates dimensions:** [list of previously-suppressed or previously-capped dims that now apply at new tier]
   ```
3. **Reinstate pruned tasks** — any tasks previously pruned by Step 2 tier cap that fit within the new tier get added back to the task list.
4. **Log to LEDGER.md:**
   ```
   ## YYYY-MM-DD HH:MM — TIER ESCALATION: Phase N — [name]
   FROM: [old] → TO: [new]
   REASON: [user reason]
   DECISIONS: D[id] updated
   ```
5. Continue Step 4 implementation at the new tier.

**On cancel:**
- Halt phase. Exec stays `🔄`. User needs to either refactor task to stay within tier, build the needed pattern outside `/gabe-execute`, or re-invoke `/gabe-plan` to re-tier and replan.

**De-escalation path (tier → lower):**
Not supported mid-phase. Orphaned higher-tier patterns would require manual cleanup. To de-escalate, use `/gabe-plan update` or edit the Tier cell directly after reverting the over-built code.

### Step 4.5: Commit (when user picks `commit` or `--auto-commit` active):

   **MUST invoke `/gabe-commit` inline.** Raw `git commit` / `git commit -m` at this step is prohibited. `/gabe-commit` is the sole owner of CHECK 6 (deferred), CHECK 7 (doc drift), CHECK 8 (structure), the per-hash `[hash] msg / FINDINGS: N / ACTIONS: …` LEDGER entry, PENDING.md updates, the `/gabe-teach topics` suggestion (Step 6.5), and the auto-tick of the `Commit` column (Step 6.6). Bypassing it silently drops all six responsibilities — the observed failure mode being: `Exec=✅` yet `Commit=⬜`, no `FINDINGS:` lines in LEDGER, no teach trigger, and `docs/AGENTS_USE.md` / `docs/wells/*.md` drift uncaught.

   Procedure:

   1. Build the commit message per Step 5 (Subject + body with Before/After + Phase/Task footer).
   2. Invoke `/gabe-commit "<message>"` — pass the generated message as `$ARGUMENTS` so `/gabe-commit` skips its own message-generation step (gabe-commit Step 1) and honors the Phase/Task footer verbatim.
   3. Handle findings surfaced by `/gabe-commit`:
      - **CRITICAL** → Exec stays `🔄`. Never proceed to T[i+1] with unresolved CRITICAL findings. User must resolve via `fix` / `skip-to-pending` before exec resumes.
      - **HIGH / MEDIUM / LOW** → user picks per-finding action (`fix` / `accept` / `defer`). Exec resumes after `/gabe-commit` returns 0.
      - `defer` → PENDING.md row added with source=`gabe-commit`; Exec continues.
   4. **Confirm Commit column ticked.** After `/gabe-commit` returns 0, re-read `.kdbp/PLAN.md` and verify the current phase's `Commit` cell is `✅`. If still `⬜` (gabe-commit Step 6.6 silent no-op fired), print:
      ```
      ⚠ Commit column not ticked for Phase N — PLAN.md state drift detected.
      Possible causes: legacy plan schema, Current Phase mismatch, or Phases table missing Commit column.
      Fix PLAN.md before continuing.
      ```
      Do not silently continue to T[i+1].

   Do NOT duplicate CHECK 6/7/8 logic inside `/gabe-execute`. Single source of truth = `/gabe-commit`.

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

1. **Invariant: Commit column must be `✅`.** Re-read `.kdbp/PLAN.md` Phases table row for current phase N. If `Commit` is still `⬜` despite all K tasks having committed, halt:
   ```
   ⚠ PHASE COMPLETE BLOCKED — Commit column still ⬜ for Phase N
   Root cause: one or more tasks bypassed /gabe-commit (raw git commit used instead).
   Consequence: doc drift (DOCS.md CHECK 7), deferred items (CHECK 6), and structure (CHECK 8) were not evaluated for this phase.
   Fix:
     1. Run /gabe-commit docs-audit to surface missed doc drift and triage.
     2. Re-invoke /gabe-commit on any uncommitted state so Step 6.6 ticks the column.
     3. Re-run /gabe-execute once Commit = ✅.
   ```
   Do not tick Exec `✅` until the Commit invariant holds. This prevents the cascade failure where Exec advances past a phase that skipped `/gabe-commit`.
2. Tick Exec cell: 🔄 → ✅ via shared auto-tick (target state = `complete`)
3. Bump Last Updated
4. Append to `.kdbp/LEDGER.md`:
   ```
   ## [YYYY-MM-DD HH:MM] — PHASE EXEC COMPLETE: Phase N — [name]
   TIER: [mvp|ent|scale] (escalated from [original]) if escalation happened, else "TIER: [tier]"
   TASKS: [K] tasks, [K] commits
   DEVIATIONS: [N structural, M minor] (see DEVIATIONS.md if any)
   ```
5. **Teach nudge (phase-level).** Deterministic heuristic, zero LLM cost. Suggest `/gabe-teach topics` before `/gabe-next` if ANY of:
   - Phase added ≥2 new files in a new folder (matches `/gabe-commit` Step 6.5 trigger at phase scope)
   - Phase introduced new top-level imports in changed files (e.g. `pydantic-ai`, `langchain`, `ai-sdk`, auth libs — any dep not present before the phase)
   - Phase modified `.kdbp/DECISIONS.md`
   - Phase touched files mapped to a Gravity Well whose Topics column shows `(0 / … / …)` or `(… / 0 / …)` verified — i.e. an architecturally significant well with no consolidated knowledge yet

   If triggered, print (one line):
   ```
   ℹ Phase N introduced new architectural concepts. Run /gabe-teach topics before /gabe-next to consolidate them into KNOWLEDGE.md.
   ```
   This is a redundant safety net — per-commit `/gabe-commit` Step 6.5 already suggests teach, but scroll-loss in bulk commits can lose it.
6. If scope arg was `all` → advance Current Phase to N+1 and re-enter Step 1. Else → print summary and exit:
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
