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

     G1 Guardrails     ▓▓▓▓▓▓░░░░  60%  (3/5)  app/agent/guardrails*        · 4 commits <14d
     G2 LLM Pipeline   ▓▓░░░░░░░░  20%  (1/5)  app/agent/pipeline*          · 0 commits <14d
     G3 API Layer      ░░░░░░░░░░   0%  (0/2)  app/api/**                   · 2 commits <14d
     G4 Frontend       ▓▓▓▓▓░░░░░  50%  (1/2)  (paths not set)              · — commits

   Total topics: [N]
     verified:      [N] (avg score X.X/2)
     pending:       [N]
     skipped:       [N]
     already-known: [N]
     stale:         [N]

   Weakest wells to address: [list up to 3]
   Staleness: [N stale topics]
   ```

Per-well row shows: well ID + name, understanding bar, percent understood, verified/total, first Paths glob (truncated to 30 chars, "(paths not set)" if empty), commits_14d count (— if Paths empty). Same pathspec-quoted git log as Step 8a #8.

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

**Step 2b — Propose a starter set.** Aim for 4-7 wells. Each well gets a proposed one-line description, a one-liner analogy (via `gabe-lens` oneliner mode — 5-15 words), anchor path globs, and a Docs path.

```
Suggested gravity wells for [project] (from [sources used]):

  G1 — [Name 1]     — [one-line description]
         ↪ Analogy: "[5-15 word gabe-lens oneliner]"
         ↪ Paths:   app/agent/guardrails*, tests/agent/**
         ↪ Docs:    docs/wells/1-guardrails.md
  G2 — [Name 2]     — [one-line description]
         ↪ Analogy: "[oneliner]"
         ↪ Paths:   app/agent/pipeline*, app/agent/triage*
         ↪ Docs:    docs/wells/2-llm-pipeline.md
  ...

Options:
  [accept]   Use as-is
  [edit N]   Rename/redescribe well N
  [relens N] Regenerate analogy for well N
  [paths N]  Edit path globs for well N
  [docs N]   Edit docs path for well N (or clear to opt out)
  [drop N]   Remove well N
  [add]      Add a new well
  [done]     Finish — write wells to KNOWLEDGE.md
```

Path globs are proposed heuristically: (1) folders matching the well name, (2) STRUCTURE.md patterns whose description aligns with the well, (3) top 3 paths from recent commits if signals are sparse. Globs are deliberately loose — `app/api/**` beats `app/api/main.py` for durability.

Docs paths follow the convention `docs/wells/{n}-{slug}.md` where `n` is the well's numeric ID and `slug` is the lowercased, hyphenated Name (e.g., "LLM Pipeline" → `llm-pipeline`). User can edit or clear via `[docs N]` — clearing means "opt out, no docs tracked for this well".

The analogy is generated via one `gabe-lens` call per well in `oneliner` mode. If a well's description is trivial (e.g., "Tests"), the analogy may be the description itself — don't force poetry on what's already clear.

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

Replace the `Status: uninitialized.` placeholder with the populated Gravity Wells table, including the `Analogy`, `Paths`, and `Docs` columns. Update topic rows with their assigned wells. Log to LEDGER.md:
```
## [YYYY-MM-DD HH:MM] — /gabe-teach init-wells
WELLS: [N] defined | RETAGGED: [M] topics
```

**Step 2e — Scaffold doc stubs (always prompt).**

After writing KNOWLEDGE.md, offer to scaffold one markdown stub per well with a non-empty Docs path:

```
DOC STUB SCAFFOLDING

  Scaffold [N] doc stubs in docs/wells/? (wells opted-out with empty Docs: [M] skipped)

    docs/wells/1-guardrails.md      (will create)
    docs/wells/2-llm-pipeline.md    (will create)
    docs/wells/3-api.md             (will create)
    ...

  [y]    Scaffold all listed stubs
  [n]    Skip scaffolding (you can create docs manually or run /gabe-teach wells → [docs N] later)
  [pick] Selectively choose which stubs to create
```

**Stub content** (deterministic, zero LLM cost):

```markdown
# [Well Name] — [Analogy in quotes]

> [Description]

**Paths:** [Paths globs]

---

## Purpose

<!-- 2-3 sentences: what this section of the application does and why it exists. -->
<!-- Populated manually by the human, or auto-appended from verified /gabe-teach topics. -->

## Key Decisions

<!-- Load-bearing choices for this well. Each entry: date + one-line title + 1-2 paragraph rationale. -->
<!-- Example:
### 2026-04-15 — Guardrails run before the LLM, not after
Reasoning: ...
-->

## Topics (auto-appended)

<!-- /gabe-teach topics appends verified topic summaries here on first run. -->
<!-- Do not edit the structure below this line; edit individual entries freely. -->
```

The `## Topics (auto-appended)` section is the landing zone for Phase B3 auto-append. The `## Purpose` and `## Key Decisions` sections are for human authoring.

**Skip scaffolding** for wells that already have a file at their Docs path — never overwrite. Report: `ℹ Skipped [N] stubs (file already exists)`.

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
  [relens N]  Regenerate analogy via gabe-lens oneliner
  [paths N]   Edit path globs for well N (used by brief activity signals — see wizard below)
  [docs N]    Edit Docs path for well N (clear to opt out; empty = no docs tracked)
  [opendoc N] Print the Docs path + first heading of each section (quick lookup)
  [merge N M] Merge well N into M (topics reassigned to M)
  [archive N] Archive well N (topics move to G0 or user chooses new well)
  [done]      Exit
```

Non-destructive: rename/merge/archive all preserve topic history in the Sessions log.

**`[paths N]` wizard flow:**

```
G3 API Layer — edit Paths

  Current: app/api/**, tests/api/**
  
  Enter new comma-separated globs (or blank line to cancel):
  > app/api/**, app/routes/**, tests/api/**

  Validation:
    ✅ app/api/**        (valid glob)
    ✅ app/routes/**     (valid glob)
    ✅ tests/api/**      (valid glob)

  STRUCTURE check:
    ⚠ app/routes/** is not in .kdbp/STRUCTURE.md Allowed Patterns
      Add to STRUCTURE.md? (recommended — STRUCTURE is the source of truth) [y/n]

  Write changes to KNOWLEDGE.md + re-run activity signals? [y/n]
```

Validation rules (basic syntax check, no LLM):
- Each glob must be non-empty after trim
- Reject absolute paths (must be project-relative)
- Reject patterns containing `..` (no path traversal)
- Warn (non-blocking) if a glob has no matching files in the current repo

On confirm: rewrite the well's Paths cell in KNOWLEDGE.md, recompute `commits_14d` + `last_commit` for that well, display refreshed activity line.

**`[opendoc N]` quick lookup:**

```
G3 API Layer — Docs

  Path:   docs/wells/3-api.md
  Status: ✅ exists (last modified 2026-04-16, 42 lines)

  Sections:
    # API Layer — "Reception desk..."
    ## Purpose            (authored — 2 paragraphs)
    ## Key Decisions      (authored — 3 entries)
    ## Topics (auto-appended)  (2 verified topics)
```

Prints: file path, existence status, line count, last modified date, and the first-heading summary of each `##` section in the file. Deterministic read; no file modification. If the well's Docs column is empty: `ℹ G3 API Layer has no Docs path set. Run [docs N] to assign one.` If the path is set but the file is missing: `⚠ docs/wells/3-api.md not found. Run /gabe-teach init-wells to scaffold, or create manually.`

### Step 4: Topics mode (the main teach flow)

This is the existing flow, with three changes: wells-aware extraction, wells-grouped menu, enriched session logging.

**Step 4a — Foundation gate** (Step 0.5 above). Block or fall through to Step 4b.

**Step 4b — Extract candidate topics.** Same deterministic signals as before (LEDGER commits, commit message prefixes, new files, DECISIONS changes). **New step:** assign each candidate a primary well using the wells' `Paths` column from KNOWLEDGE.md:

| Signal | Well assignment rule |
|--------|---------------------|
| Changed file matches a well's `Paths` glob (most-specific match wins) | Primary well = that well |
| Multiple wells' Paths match (ties broken by glob specificity — longer pattern wins) | Primary well = most specific; add `cross` tag if tie is genuine |
| Commit message explicitly mentions a well's name and no Paths match | Primary well = that well |
| No Paths match AND no name mention | Primary well = G0 Uncategorized |
| Well has empty `Paths` column | Skip that well in path-matching; only name-mention rule applies |

Matching rule: parse comma-separated globs from the Paths column, trim, test each changed file against each glob using standard fnmatch-style globbing (`**` = recursive, `*` = single-segment). If a well has no Paths, it's a valid assignment target only via explicit commit-message mention.

Deduplicate against existing `verified` / `already-known` topics (same as before).

Use one short LLM call to **name** topics (unchanged). Wells are assigned deterministically from Paths — no LLM for that.

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

If user picks `0`: run the **short-brief** variant (Step 8 with `short` flag) inline, then re-show this menu. `0` is orientation, not a topic selection — it doesn't consume from the 3-pick cap.

**Short-brief:** wells block only (≈15 lines), no CONTEXT/OPEN & NEXT/RECENT sections, no COMMANDS footer. Keeps the topics menu flow tight. For the full brief, use `/gabe-teach brief` directly.

**Gate bypass:** When `[0]` is invoked from inside the topics menu, Step 8's foundation gate is SKIPPED (Step 0.5 already passed to reach this menu). The brief runs directly. This is the only case where the gate is bypassed.

Cap: 3 topics per session (prevents quiz fatigue). Same deterministic counting as before.

**Step 4d — Teach each selected topic.** Unchanged from current flow — analogy (via gabe-lens skill) → 2 Socratic questions → classify response (verified / pending / skipped / already-known with sanity check).

**Step 4d.1 — Auto-append verified topic to well's Docs (prompt-first).**

When a topic is classified `verified` in Step 4d:

1. Look up the topic's assigned well in KNOWLEDGE.md
2. If the well's `Docs` column is empty → skip silently (well opted out of doc tracking)
3. If the well's Docs file does NOT exist → skip with one-line warning: `⚠ Can't append: docs/wells/3-api.md not found. Run /gabe-teach wells → [docs N] to fix path, or scaffold via /gabe-teach init-wells.`
4. Otherwise, check the user's append preference (stored in `.kdbp/BEHAVIOR.md` frontmatter as `teach_append: prompt | always | never`, default `prompt`):
   - `always` → append silently, show `✅ Appended T[N] to docs/wells/3-api.md`
   - `never` → skip silently
   - `prompt` → ask:
     ```
     Topic T[N] "[title]" verified. Append to docs/wells/3-api.md?
       [y]      Append this once
       [n]      Skip this once
       [always] Append automatically for every verified topic going forward
       [never]  Never prompt again; don't append
     ```
     `always` and `never` write `teach_append: always` or `teach_append: never` to BEHAVIOR.md frontmatter, so the choice persists across sessions.

**Append format** — inserts a new section under `## Topics (auto-appended)` in the Docs file, preserving any existing content above that heading:

```markdown
### T[N] — [Topic title]

**Class:** [WHY|WHEN|WHERE]  **Verified:** YYYY-MM-DD  **Score:** [X]/2  **Commits:** [hash, hash]

[One-paragraph summary from the teach session — the analogy + key framing delivered in Step 4d, trimmed to ≤120 words]

**Key points:**
- [Socratic answer bullet 1]
- [Socratic answer bullet 2]
```

Purely deterministic — uses data already captured in the teach session. No additional LLM call.

If the section `## Topics (auto-appended)` is missing from the file (user deleted it or wrote doc from scratch), create it at end of file before appending.

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
- Docs appended: T1 → docs/wells/1-guardrails.md  (only when Step 4d.1 succeeded)
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
2. `.kdbp/KNOWLEDGE.md` → Gravity Wells table (Name + Description + Analogy + Paths + Docs), Topics table (Well + Class + Topic + Status + Last Touched), Storyline section (if present)
3. `.kdbp/PLAN.md` → active plan goal + current phase (N of M) + Review/Commit/Push tick states, if `status: active`
4. `.kdbp/LEDGER.md` → last 5 entries (dated section headers + first line of each)
5. `.kdbp/PENDING.md` → open items with status=open, their priority, file, and finding summary
6. `.kdbp/DECISIONS.md` → last 3 decision entries (date + one-line title)
7. `git log --since="14 days ago" --oneline` → project-wide commit count
8. Per well with Paths populated: parse comma-separated globs, trim, pass each as a **separately quoted git pathspec** to avoid shell expansion:
   ```
   git log --since="14 days ago" --oneline -- "app/api/**" "tests/api/**"
   ```
   → well-scoped commit count + most recent commit (hash + date). **Never** interpolate unquoted globs (the shell would expand them locally against CWD).

**Step 8b — Per-well signals (deterministic):**

For each well row in KNOWLEDGE.md:
- `pending_count` = topics in this well with status `pending` or `skipped`
- `verified_count` = topics with status `verified`
- `pending_titles` = topic titles for pending rows (first 3, truncated to 50 chars each)
- `stale_count` = topics with status `stale` (verified >90 days ago)
- `commits_14d` = git commit count in the well's Paths (0 if Paths empty)
- `last_commit` = most recent commit in Paths (`YYYY-MM-DD hash`) or `—` if none
- `health` = derived: `🟢 active` if commits_14d > 0, `🟡 cold` if 0 commits_14d but verified/pending > 0, `🔴 stale` if stale_count > 0 (precedence: stale > cold > active)

No LLM call for this step. Wells with zero Paths show `commits_14d: —` but still render — absence is informative.

**Step 8b.5 — Backfill missing analogies (one-time per well):**

If a well row has an empty `Analogy` column, generate one on the fly via `gabe-lens` in `oneliner` mode (5-15 words). Write the result back to KNOWLEDGE.md so subsequent briefs are free. One LLM call per missing analogy, one-time cost per well.

**Failure fallback:** If the `gabe-lens` call fails (no network, no API key, rate limit, timeout > 10s), do NOT crash the brief. Instead:
1. Write the well's existing `Description` as the Analogy (stripped to ≤15 words)
2. Emit a one-line warning at the top of the brief output: `⚠ Analogy backfill skipped for G[N] (reason: [short cause]) — using description as placeholder`
3. Continue rendering

This keeps brief mode resilient on first post-schema-change runs in restricted environments.

**Step 8b.6 — Backfill missing Paths (heuristic, no LLM):**

If a well row has an empty `Paths` column, run the Step 2a heuristic deterministically:
1. Top-level folders whose name contains or is contained by the well's Name (case-insensitive, hyphen/underscore normalized)
2. STRUCTURE.md Allowed Patterns whose Description text overlaps the well's Description (keyword intersection ≥2 words)
3. Top 3 most-touched paths from `git log --since="30 days ago" --name-only` whose topics in KNOWLEDGE.md are assigned to this well

Take the union (deduplicated), keep the broadest glob per folder (`app/api/**` beats `app/api/main.py`). Write back to KNOWLEDGE.md as a comma-separated list. Emit: `ℹ Paths backfilled for G[N]: [glob list] — review with /gabe-teach wells → [paths N] if wrong`

If the heuristic produces zero hits, leave Paths empty and emit: `⚠ Could not infer Paths for G[N] — run /gabe-teach wells → [paths N]`

**Step 8c — Output format** (tight, ~50 lines including context blocks):

```
GABE TEACH BRIEF — [project name]

App:        [BEHAVIOR.md `domain` field]
Stack:      [BEHAVIOR.md `tech` field]
Maturity:   [mvp | enterprise | scale]
Active:     [PLAN.md goal] — Phase [N]/[M]  Review [✅/⬜] Commit [✅/⬜] Push [✅/⬜]
            (or "No active plan" if PLAN.md status != active)

GRAVITY WELLS ([N] defined)

  G1 [Name]: "[gabe-lens oneliner]"  [health icon+label]
     [description] · [paths or "paths not set"] · last: [YYYY-MM-DD hash] or "—"
     Docs: [Docs path]    (or "⚠ no doc" if Docs column empty, or "⚠ docs/wells/1-x.md missing" if path set but file doesn't exist)
     Pending: "[title 1]", "[title 2]", "[title 3]"        (or "none" if 0 pending)
     [⚠ [stale_count] stale  — only shown if stale_count > 0]

  G2 [Name]: "[oneliner]"  [health]
     [description] · [paths] · last: [date hash]
     Docs: [Docs path]
     Pending: ...
  ...

CONTEXT

  Story so far:
    [first 1-2 sentences of KNOWLEDGE.md ## Storyline — see placeholder rule below]
    (run /gabe-teach story for full narrative)
    — OR — "No storyline yet. Run /gabe-teach story to generate one."

  Placeholder detection: treat the Storyline section as EMPTY if its body (after the `## Storyline` heading, excluding HTML comments) either:
    - Is whitespace-only
    - Starts with the literal phrase "No storyline generated yet"
    - Contains fewer than 80 characters of non-comment content
  In any of those cases, show the fallback sentence, not the placeholder.

  Key decisions:
    [date] — [DECISIONS.md entry title 1]
    [date] — [title 2]
    [date] — [title 3]
    — OR — "No decisions recorded yet."

OPEN & NEXT

  Deferred items (PENDING.md):
    D[N] ([priority])  [short finding]  — [file]
    ... (up to 3 highest-priority open items)
    — OR — "No open deferred items."

  Suggested next actions:
    [tailored hint 1 based on signals below]
    [tailored hint 2]
    [tailored hint 3]

RECENT PROJECT ACTIVITY (last 14 days)

  [N] commits | [M] teach sessions | [K] plan phases shipped

  From LEDGER.md:
    - [date] [first line of entry]
    - ... (up to 5)

COMMANDS
  /gabe-teach topics    /gabe-teach wells    /gabe-teach story    /gabe-teach history
```

**Step 8c.1 — Suggested next actions logic** (deterministic, pick first 2-3 that apply):

| Signal | Hint |
|--------|------|
| Any well with pending_count ≥ 3 | `High-pending wells: [list] → /gabe-teach topics` |
| Any stale_count > 0 across wells | `Stale knowledge in [wells] → /gabe-teach topics (auto-refreshes)` |
| No active plan | `No active plan → /gabe-plan to set one` |
| PENDING.md has ≥ 3 open items | `[N] deferred items backing up → /gabe-review to triage` |
| No storyline AND ≥ 3 archived plans | `Enough history for a story → /gabe-teach story` |
| Wells exist but all have empty Paths | `Wells lack path globs (activity signals disabled) → /gabe-teach wells + [paths N]` |
| ≥ 1 well has empty Docs AND wasn't opted out explicitly | `Wells without docs: [list] → /gabe-teach wells → [docs N]` |
| PENDING.md has open Layer-3 doc-drift findings | `Doc drift on wells: [list] → /gabe-review` |
| Nothing above applies | `Looking healthy. Consider /gabe-health for deeper audit.` |

**Step 8d — Missing data graceful degradation:**

| Missing | Behavior |
|---------|----------|
| BEHAVIOR.md `domain:` field | `App: (not set — add \`domain:\` to BEHAVIOR.md frontmatter)` |
| PLAN.md absent OR status != active | `Active: No active plan` |
| LEDGER.md absent or empty | Skip the "From LEDGER.md" block; show scalar commit count |
| PENDING.md absent or all-closed | `Deferred items: none` |
| DECISIONS.md absent or empty | `Key decisions: none recorded` |
| Well has empty Paths | Show `paths not set` inline; `last: —`; health falls through to cold/stale using topic signals only |
| Well has empty Docs | Show `Docs: ⚠ no doc` inline; OPEN & NEXT rule flags "Wells without docs: [list]" |
| Well has non-empty Docs but file missing | Show `Docs: ⚠ docs/wells/1-x.md missing` inline; suggest `/gabe-teach init-wells` or manual create |
| No wells | Foundation gate blocks before Step 8a |

**Step 8e — No persistence (except backfills):**

Brief mode is read-only except for one-time Analogy backfill (Step 8b.5) and one-time Paths backfill (Step 8b.6). It does NOT write plans, decisions, topics, or activity. Safe to re-run anytime.

**Step 8f — Short-brief variant (for in-menu invocation):**

When brief is invoked with `short` flag (from `[0]` in topics menu):
- Render only the GRAVITY WELLS block
- Skip App/Stack/Maturity/Active header
- Skip CONTEXT, OPEN & NEXT, RECENT PROJECT ACTIVITY, COMMANDS sections
- Keep Analogy+Paths backfill logic (they're load-bearing for the wells block itself)
- Target output: ≤20 lines total

**Note on LLM usage:**

Brief is deterministic once analogies are cached. First run after adding the Analogy column fires one gabe-lens call per well missing an analogy; cached thereafter. For narrative depth, `/gabe-teach story` remains the LLM-backed companion.

**Principle — progressive-depth analogies everywhere:**

Whenever `/gabe-teach` surfaces a concept that a newcomer or fatigued operator might not grasp instantly, attach a `gabe-lens` oneliner by default. Escalate to `brief` mode if the oneliner can't carry the weight, and only use full analogy when the concept is genuinely load-bearing. This applies to wells (here), to topics in `topics` mode (optional add-on), and to any future surface where the suite presents architectural terms. Cheap cognitive insurance.

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
