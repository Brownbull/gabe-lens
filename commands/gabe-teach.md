---
name: gabe-teach
description: "Consolidate the human's architect-level understanding of recent changes. Organizes topics under gravity wells (architectural sections). Detects WHY/WHEN/WHERE topics from commits, explains with analogies, verifies with Socratic questions, tracks in .kdbp/KNOWLEDGE.md. Usage: /gabe-teach [brief|topics|status|wells|init-wells|history|story|free]"
---

# Gabe Teach

Countermeasure for "the human can't keep up with AI-paced changes." Keeps the human at architect-level understanding: WHY decisions were made, WHEN patterns apply, WHERE files belong. Topics are anchored to **gravity wells** (architectural sections of the app) so the human builds a map before individual details.

## Procedure

### Step 0: Detect mode

Parse `$ARGUMENTS`:

| Mode | Purpose |
|------|---------|
| `brief` | Newcomer-onboarding snapshot: app purpose + wells overview + recent activity |
| `topics` (default when `.kdbp/` exists) | Session-aware teach loop over recent changes |
| `status` | Show KNOWLEDGE.md summary per well + history timeline |
| `wells` | List/edit wells (rename, merge, archive, view topics per well) |
| `init-wells` | Run the wizard to define gravity wells |
| `history` | Full timeline — plans, phases, commits, sessions, topics |
| `history full` | Unbounded history (default shows last 10 sessions + last 5 plans) |
| `story` | Show cached Storyline, or generate if missing |
| `story refresh` | Force regeneration of Storyline |
| `free [concept]` | Raw analogy generation (invokes `gabe-lens` skill) |

If `.kdbp/` doesn't exist: fall back to `free` with a note: "No KDBP detected. Running in free mode. Run `/gabe-init` to enable knowledge tracking."

### Step 0.5: Foundation Gate

Before `topics`, `status`, `history`, or `story` modes run, verify foundation pieces are in place. Silently pass if all OK; stop and prompt if something's missing.

**Check:**
1. `.kdbp/KNOWLEDGE.md` exists
2. KNOWLEDGE.md has a `## Gravity Wells` section with at least one well row (not just the "Status: uninitialized" placeholder)

**If wells are missing:**

```
FOUNDATION CHECK:
  .kdbp/BEHAVIOR.md          ✅
  .kdbp/KNOWLEDGE.md         ✅
  Gravity Wells defined      ❌ (status: uninitialized)

⚠ /gabe-teach cannot organize topics without gravity wells.
  Topics would land as orphans.

  [init] Run /gabe-teach init-wells now (recommended)
  [skip] Proceed anyway, topics assigned to "G0 Uncategorized"
  [abort] Cancel this /gabe-teach run

Choice:
```

- **init** → run Step 2 (the wizard) inline, then continue with the original mode
- **skip** → create a `G0 Uncategorized` well row automatically, show: `ℹ Topics will land in G0. Run /gabe-teach init-wells when ready to organize.`, continue
- **abort** → stop cleanly

This gate only fires once per project's lifetime — once wells exist, the gate passes silently.

### Step 1: Status mode

If mode is `status`:

1. Read `.kdbp/KNOWLEDGE.md`
2. Show per-well coverage dashboard:
   ```
   KNOWLEDGE MAP — [project name]

   Gravity Wells ([N] defined):

     G1 Guardrails     ▓▓▓▓▓▓░░░░  60% understood  (3/5 topics verified)
     G2 LLM Pipeline   ▓▓░░░░░░░░  20% understood  (1/5)
     G3 API Layer      ░░░░░░░░░░   0% understood  (0/2)
     G4 Frontend       ▓▓▓▓▓░░░░░  50% understood  (1/2)

   Total topics: [N]
     verified:      [N] (avg score X.X/2)
     pending:       [N]
     skipped:       [N]
     already-known: [N]
     stale:         [N]

   Weakest wells to address: [list up to 3]
   Staleness: [N stale topics]
   ```

3. **History timeline (deterministic, zero cost)** — embedded after the dashboard:
   ```
   Recent work:
     📦 Phase 1: Incident Submission + Guardrails (archived 2026-04-16)
        5 sub-phases, all shipped. Topics: T1, T2, T5

     📌 Active plan: Phase 1 Level 2a (Guardrails before LLM)
        Phase 3/5 — Review ⬜ Commit ⬜ Push ⬜

     📝 Recent teach sessions:
        - 2026-04-17: 2 verified, 1 skipped
        - 2026-04-15: 3 verified, 2 skipped, 1 already-known
   ```
   Default bounds: last 5 plans + last 10 sessions. For unbounded view: `/gabe-teach history full`.

4. If stale count > 0: suggest `/gabe-teach topics` to refresh stale items.

5. Stop.

### Step 2: Init-wells mode (the wizard)

Invoked by `/gabe-teach init-wells` OR selected during the foundation gate.

**Step 2a — Scan for signals.** In priority order:

| Priority | Source | What to extract |
|----------|--------|----------------|
| 1 | `docs/architecture.md` | All `## ` (H2) headings |
| 2 | `.kdbp/STRUCTURE.md` Allowed Patterns | Folder patterns already established for this project (bundled per-project artifact) |
| 3 | Top-level folders | `app/`, `frontend/`, `backend/`, `tests/`, `infra/`, etc. |
| 4 | `.kdbp/DECISIONS.md` | Architectural areas mentioned in decisions |
| 5 | `package.json` / `pyproject.toml` scripts | Reveals layers (build, test, lint, deploy) |

**Step 2b — Propose a starter set.** Aim for 4-7 wells. Each well gets a proposed one-line description.

```
Suggested gravity wells for [project] (from [sources used]):

  G1 — [Name 1]     — [one-line description]
  G2 — [Name 2]     — [one-line description]
  G3 — [Name 3]     — [one-line description]
  G4 — [Name 4]     — [one-line description]
  G5 — [Name 5]     — [one-line description]

Options:
  [accept] Use as-is
  [edit N] Rename/redescribe well N
  [drop N] Remove well N
  [add]    Add a new well
  [done]   Finish — write wells to KNOWLEDGE.md
```

Interactive until user says `done`. Soft cap:

- **>7 wells:** warn but allow: `⚠ [N] wells exceeds Miller's number (7). Consider merging related wells. Proceed? [y/n]`
- **<3 wells:** warn: `⚠ Only [N] wells — unusual for a project with [N] folders. Are you sure? [y/n]`

**Step 2c — Retag existing topics (if any).**

If KNOWLEDGE.md already has topic rows (e.g., user ran `/gabe-teach` before defining wells and chose "skip"), walk them one at a time:

```
[1/N] Topic: "Why guardrails run before the LLM" (currently G0 Uncategorized)

  Proposed well: G1 Guardrails
  Other options: G2 LLM Pipeline, G3 API Layer, ...

  [accept] Use proposed    [N] Pick well by ID    [skip] Leave as G0
```

**Step 2d — Write to KNOWLEDGE.md.**

Replace the `Status: uninitialized.` placeholder with the populated Gravity Wells table. Update topic rows with their assigned wells. Log to LEDGER.md:
```
## [YYYY-MM-DD HH:MM] — /gabe-teach init-wells
WELLS: [N] defined | RETAGGED: [M] topics
```

### Step 3: Wells mode

If mode is `wells`:

```
GRAVITY WELLS — [project name]

  G1 Guardrails     — [description]        [3 verified / 5 total]
  G2 LLM Pipeline   — [description]        [1 verified / 5 total]
  ...

Actions:
  [view N]    Show topics in well N
  [rename N]  Rename well N (topics stay assigned)
  [redesc N]  Edit description
  [merge N M] Merge well N into M (topics reassigned to M)
  [archive N] Archive well N (topics move to G0 or user chooses new well)
  [done]      Exit
```

Non-destructive: rename/merge/archive all preserve topic history in the Sessions log.

### Step 4: Topics mode (the main teach flow)

This is the existing flow, with three changes: wells-aware extraction, wells-grouped menu, enriched session logging.

**Step 4a — Foundation gate** (Step 0.5 above). Block or fall through to Step 4b.

**Step 4b — Extract candidate topics.** Same deterministic signals as before (LEDGER commits, commit message prefixes, new files, DECISIONS changes). **New step:** assign each candidate a primary well:

| Signal | Well assignment rule |
|--------|---------------------|
| File path matches well's folder pattern (if configured) | Primary well = that well |
| Commit message mentions a well's name | Primary well = that well |
| Ambiguous (file touches two wells' folders) | Primary well = first match; add `cross` tag |
| No match | Primary well = G0 Uncategorized |

Deduplicate against existing `verified` / `already-known` topics (same as before).

Use one short LLM call to **name** topics (unchanged). Wells are assigned deterministically from path signals — no LLM for that.

**Step 4c — Present menu, grouped by well.**

```
TEACH: Topics from recent changes

Commits covered: [N] since [date]
Active plan: [plan name], Phase [N] of [M]

  [0] BRIEF — Newcomer-onboarding snapshot (app purpose + wells overview + recent activity)

Guardrails (G1) — [N] pending
  [1] WHY   — Why guardrails run before the LLM
  [2] WHEN  — When to return matched pattern names vs boolean

API Layer (G3) — [N] pending
  [3] WHY   — Why 202 Accepted + BackgroundTask
  [4] WHERE — Why uploads/ lives at project root, not under app/

Frontend (G4) — [N] pending
  [5] WHY   — Why we expanded guardrails 15 → 25 patterns + sanitization

Pick up to 3:
  - Brief orient:  "0" (shows brief, then re-prompts for topic picks)
  - Individual:    "1,3,5" or just "3"
  - Whole well:    "all G1" or "all G3"
  - All pending:   "all"
  - Skip session:  "skip"
```

If user picks `0`: run Step 8 (Brief mode) inline, then re-show this menu. `0` is orientation, not a topic selection — it doesn't consume from the 3-pick cap.

Cap: 3 topics per session (prevents quiz fatigue). Same deterministic counting as before.

**Step 4d — Teach each selected topic.** Unchanged from current flow — analogy (via gabe-lens skill) → 2 Socratic questions → classify response (verified / pending / skipped / already-known with sanity check).

**Step 4e — Update KNOWLEDGE.md.** Writes rows with the `Well` column populated. Tags column populated with `cross` if flagged.

**Step 4f — Log session** (enriched):
```
### [YYYY-MM-DD] — /gabe-teach topics (post-commit)
- Wells active: [list of well IDs + names]
- Commits covered: [list]
- Plan reference: [plan name + current phase from .kdbp/PLAN.md]
- Presented: T1, T2, T3
- Verified: T1 (2/2)
- Skipped: T2
```

**Step 4g — Log to LEDGER.md** (unchanged except includes wells count):
```
## [YYYY-MM-DD HH:MM] — /gabe-teach
TOPICS: presented N, verified M, skipped K, already-known J
WELLS: [N] | PENDING: [count after this session]
```

### Step 5: History mode

If mode is `history`:

Bounded view (default): last 5 plans + last 10 sessions. Full view: `/gabe-teach history full`.

Sources (deterministic, zero LLM cost):
- `.kdbp/archive/` — archived plans (completed/deferred/cancelled)
- `.kdbp/PLAN.md` — active plan + phase trackers
- `.kdbp/LEDGER.md` — session checkpoints + commits
- KNOWLEDGE.md Sessions section — past teach runs

Output format:
```
WORK HISTORY — [project name]

📦 Completed plans:
  ✅ [Plan name] (archived YYYY-MM-DD)
     [N] phases shipped. Topics spawned: [list or count]
  ⏸ [Plan name] (deferred YYYY-MM-DD → PENDING #D[N])
     [N of M] phases shipped before defer
  ❌ [Plan name] (cancelled YYYY-MM-DD)

📌 Active plan: [current plan goal]
  Phase [N]: [name]    Review [✅|⬜]  Commit [✅|⬜]  Push [✅|⬜]
  ...

📝 Recent teach sessions:
  - [date]: [verified] verified, [skipped] skipped, [already] already-known
  ...

Topic → plan mapping (last 20 topics):
  T1 (G1, verified)  ← [plan name], Phase 1, commit abc1234
  T2 (G3, pending)   ← [plan name], Phase 3, commit def5678
  ...
```

### Step 6: Story mode

If mode is `story`:

Check for an existing `## Storyline` section in KNOWLEDGE.md:
- If cached and <3 new archives since generation: show cached, add a note `(generated [date], [N] archives old)`
- If missing OR `refresh` subarg given OR ≥3 new archives: regenerate via one LLM call

**Generation (when fired):**
1. Read all completed plans from `.kdbp/archive/` (completed only, not deferred/cancelled)
2. Read the active plan's goal + phase progression from PLAN.md
3. Send to an LLM as context with this framing:
   - "Write a 150-250 word narrative analogy of what has been built in this project. Use concrete language. Thread the plans together — what was the throughline? What belief held each decision together? End with the single load-bearing thesis."
4. Write the result to KNOWLEDGE.md's `## Storyline` section with a generation date

Output format:
```
STORYLINE — [project name]
Generated: [date] (based on [N] archived plans + current active plan)

[the narrative]

Run /gabe-teach story refresh to regenerate.
```

Auto-refresh trigger: on any `/gabe-teach topics` run, check archive count. If ≥3 new archives since last Storyline generation, append a one-line suggestion to the teach output: `ℹ Storyline may be stale ([N] new archives since last generation). Run /gabe-teach story refresh when ready.`

### Step 7: Free mode (unchanged)

If mode is `free [concept]`: invoke `gabe-lens` skill directly. No KDBP interaction.

### Step 8: Brief mode

Invoked by `/gabe-teach brief` OR by picking `[0] Brief` in the Step 4c topics menu.

Read-only orientation snapshot. A newcomer (dev who knows the language/stack but not this project) should be able to get current after reading it. Always regenerated (cheap, deterministic except optional LLM call — see note).

**Foundation gate applies** (Step 0.5) — if wells aren't defined, the same prompt appears before brief runs. Without wells there's nothing meaningful to summarize.

**Step 8a — Gather inputs (all deterministic):**

1. `.kdbp/BEHAVIOR.md` frontmatter → `domain:` (one-liner), `maturity:`, `tech:`
2. `.kdbp/KNOWLEDGE.md` → Gravity Wells table (rows), Topics table (rows with Well + Status + Last Touched columns)
3. `.kdbp/PLAN.md` → active plan goal + current phase (N of M) + Review/Commit/Push tick states, if `status: active`
4. `.kdbp/LEDGER.md` → last 5 entries (dated section headers + first line of each)
5. `git log --since="14 days ago" --oneline` → recent commit count (scalar only)

**Step 8b — Per-well activity signal (deterministic):**

For each well row in KNOWLEDGE.md:
- `pending_count` = topics in this well with status `pending` or `skipped`
- `verified_count` = topics with status `verified`
- `recent_touched` = topics whose `Last Touched` date is within 14 days
- `stale_count` = topics with status `stale` (verified >90 days ago)

No LLM call for this step. If a well has zero activity and zero topics, still show it — the brief is about orientation, absence is informative.

**Step 8c — Output format** (one-page tight brief, ~30 lines):

```
GABE TEACH BRIEF — [project name from .kdbp/ parent folder or BEHAVIOR.md name]

App:        [BEHAVIOR.md `domain` field]
Stack:      [BEHAVIOR.md `tech` field]
Maturity:   [mvp | enterprise | scale]
Active:     [PLAN.md goal] — Phase [N]/[M] [Review ✅/⬜ Commit ✅/⬜ Push ✅/⬜]
            (or "No active plan" if PLAN.md status != active)

GRAVITY WELLS ([N] defined)

  G1 [Name]
     [description]
     Activity: [pending_count] pending, [verified_count] verified, [recent_touched] touched <14d
     [⚠ [stale_count] stale  — only shown if stale_count > 0]

  G2 [Name]
     [description]
     Activity: ...
  ...

RECENT PROJECT ACTIVITY (last 14 days)

  [N] commits | [M] teach sessions | [K] plan phases shipped

  From LEDGER.md:
    - [date] [first line of entry]
    - [date] [first line]
    - ... (up to 5)

NEXT STEPS
  /gabe-teach topics          — start a teach session on pending topics
  /gabe-teach wells           — drill into a specific well
  /gabe-teach story           — read the project's narrative arc
  /gabe-teach history         — full timeline of plans and phases
```

**Step 8d — Missing data graceful degradation:**

| Missing | Behavior |
|---------|----------|
| BEHAVIOR.md `domain:` field | Show `App: (not set — add \`domain:\` to .kdbp/BEHAVIOR.md frontmatter)` |
| PLAN.md absent OR status != active | `Active: No active plan` |
| LEDGER.md absent or empty | Skip the "From LEDGER.md" block, show commit count only |
| No wells (foundation gate caught this) | Gate blocks before reaching Step 8a |

**Step 8e — No persistence:**

Brief mode does NOT write to KNOWLEDGE.md, LEDGER.md, or anywhere. It's read-only orientation. This keeps it cheap to re-run at any time without side effects.

**Note on LLM usage:**

Brief mode is fully deterministic by default. The `App:` line comes from BEHAVIOR.md, well descriptions from KNOWLEDGE.md. No LLM call is required. If the user wants a richer narrative, `/gabe-teach story` is the LLM-backed companion.

---

## Staleness handling (unchanged)

When reading KNOWLEDGE.md in `topics` or `status` modes, also compute staleness:
- Topics verified >90 days ago → mark `stale`, re-surface in next `topics` menu
- If >3 stale topics exist → show warning at top of menu: `⚠ [N] topics verified >90 days ago. Knowledge can drift.`

## Already-known sanity check (unchanged)

When the human claims `already-known`, DO NOT mark immediately. Ask ONE targeted question:
- If correct → `already-known` with note `sanity-checked`
- If wrong → `pending`, explain correctly, note `claimed known but missed X`

## Interaction with other gabe commands

- Called after `/gabe-commit` if N new topics detected (suggestion, not blocking)
- Called after `/gabe-push` if pending topics >= 2 (suggestion, not blocking)
- `/gabe-teach status` is zero-cost — run anytime
- Does NOT run during `/gabe-plan` — planning is forward-looking, teaching is retrospective

$ARGUMENTS
