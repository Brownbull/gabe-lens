---
name: gabe-init
description: "Initialize a project with KDBP stack — creates .kdbp/, installs hooks, configures by project type. Usage: /gabe-init [project-name]"
---

# Gabe Init

One-command project setup. Wraps three operations into a single flow.

## Procedure

### Step 1: Create .kdbp/ directory

Run the equivalent of `/gabe-align init [project-name]`:

1. If `.kdbp/` already exists, show status and ask: "Reset, update, or skip init?"
   - **reset** — wipe `.kdbp/` and start fresh (destructive, loses LEDGER history and any active plan)
   - **update** — keep existing files, add missing KDBP files/directories from the current template set, verify and install missing hooks. Non-destructive. No existing files modified.
   - **skip** — do nothing (exit init)

   If user picks **update**, run Step 1.5 (Update Mode) and then skip to Step 2 (hook check).
   If user picks **reset**, continue to step 2 below (full init).
   If user picks **skip**, exit.

2. If no project name in $ARGUMENTS, ask: "Project name?"
3. Ask: "What does this project do?" (one sentence for BEHAVIOR.md `domain`)
4. Ask: "Maturity level?" → `mvp` (default) | `enterprise` | `scale`
5. Ask: "Tech stack?" (comma-separated, e.g., "python, fastapi, react")
6. Create `.kdbp/` with these files:

```
.kdbp/
├── BEHAVIOR.md      # From answers above
├── VALUES.md        # Project values (empty template — user adds during first session)
├── DECISIONS.md     # Append-only architecture decision table
├── PENDING.md       # Deferred items (empty)
├── LEDGER.md        # Checkpoint history (empty)
├── MAINTENANCE.md   # Quarterly human checklist
├── DOCS.md          # Doc drift mappings (from project type, used by CHECK 7)
├── PLAN.md          # Active plan (empty template — populated by /gabe-plan)
├── KNOWLEDGE.md     # Human knowledge map (topics tracked by /gabe-teach)
├── STRUCTURE.md     # Per-project folder conventions (checked by gabe-commit CHECK 9)
└── archive/         # Archived plans (completed_, defer_, cancelled_)
```

**BEHAVIOR.md** — generate from answers:
```yaml
---
name: [project-name]
domain: [from answer]
maturity: [mvp|enterprise|scale]
tech: [from answer]
created: [today's date]
---
```

**VALUES.md** — start with:
```markdown
# Project Values

<!-- Add 3-7 project-specific values. Format: -->
<!-- - **V1 — [Name]:** [One sentence] `[session|story|epic]` -->
```

**DECISIONS.md** — use template from `~/.claude/templates/gabe/DECISIONS.md`

**PENDING.md** — start with:
```markdown
# Deferred Items

| # | Date | Source | Finding | File | Scale | Priority | Impact | Times Deferred | Status |
|---|------|--------|---------|------|-------|----------|--------|----------------|--------|
```

**LEDGER.md** — start empty:
```markdown
# Session Ledger
```

**MAINTENANCE.md** — use template from `~/.claude/templates/gabe/MAINTENANCE.md`

**PLAN.md** — use template from `~/.claude/templates/gabe/PLAN.md`

**KNOWLEDGE.md** — use template from `~/.claude/templates/gabe/KNOWLEDGE.md`

**STRUCTURE.md** — use template from `~/.claude/templates/gabe/STRUCTURE.md`:
- The base template has MVP patterns + disallowed patterns active
- Based on the project type selected in Step 3, uncomment the matching stack-specific block (`Agent App`, `Web App`, `CLI`, `Library`)
- Leave other blocks commented out as reference

**archive/** — create empty directory: `mkdir -p .kdbp/archive`

**DOCS.md** — use template from `~/.claude/templates/gabe/DOCS.md`:
- Select the section matching the project type chosen in Step 3
- Agent app → use the Agent App section
- Web app → use the Web App section
- CLI → use the CLI section
- Library → use the Library section
- Remove commented-out sections for other project types

### Step 1.5: Update Mode (only when user picked `update`)

Non-destructive top-up of an existing `.kdbp/` directory. Never overwrites, never deletes.

1. **Scan what's missing.** Compare the existing `.kdbp/` contents against the current template set:
   - Expected files: `BEHAVIOR.md`, `VALUES.md`, `DECISIONS.md`, `PENDING.md`, `LEDGER.md`, `MAINTENANCE.md`, `DOCS.md`, `PLAN.md`, `KNOWLEDGE.md`, `STRUCTURE.md`
   - Expected directory: `archive/`
   - Note: project-specific files like `PUSH.md` or historical `PLAN-PHASE-N.md` are NOT in the expected set — leave them untouched.

2. **Report findings before acting:**
   ```
   UPDATE MODE — [project name]

   Present (9):    BEHAVIOR, VALUES, DECISIONS, PENDING, LEDGER, MAINTENANCE, DOCS, PUSH, PLAN-PHASE-1
   Missing (3):    PLAN.md, KNOWLEDGE.md, archive/
   Unrecognized:   PLAN-PHASE-1.md (not in template set — will keep as-is)

   Proceed with top-up? (y/n)
   ```

3. **If confirmed, create only missing items:**
   - For each missing template file: copy from `~/.claude/templates/gabe/[FILE]`
   - For `archive/`: run `mkdir -p .kdbp/archive`
   - For `DOCS.md` specifically: if missing, do NOT auto-select a project type — ask: "Project type? (agent-app | web-app | cli | library)" and use that section
   - Skip any file that already exists (never overwrite)

4. **Do NOT touch:**
   - `BEHAVIOR.md` — already has maturity, domain, tech (preserves user customization)
   - `VALUES.md` — user-authored content
   - Any file with existing content
   - Files outside the expected template set

5. **After file top-up, run Step 1.6 (schema migration) before Step 2.**

6. **After Step 2, skip Steps 3-4** (project type + readiness report). Instead show a condensed Update Report:
   ```
   UPDATE COMPLETE
     Files added:    [list]
     Directories:    [list]
     Schema migrations: [list or "none"]
     Hooks installed: [N] / [total]
     Preserved:      [count of files left untouched]
   ```

### Step 1.6: Schema migration (non-destructive, only when `update` picked)

Template files can evolve with new columns. Existing `.kdbp/` files predating those changes need column-level top-up (not file replacement — that would destroy user data).

**Current migrations:**

| Target | Old shape | New shape | Detection |
|--------|-----------|-----------|-----------|
| `.kdbp/KNOWLEDGE.md` Gravity Wells table | 4-6 columns (any subset of new cols missing) | 7 columns: `# \| Name \| Description \| Analogy \| Paths \| Docs \| Topics` | Header row missing any of `Analogy`, `Paths`, or `Docs` between `Description` and `Topics` |
| `.kdbp/KNOWLEDGE.md` Topics table | 10 columns (no ArchConcepts) | 11 columns: `# \| Well \| Class \| Topic \| Status \| Tags \| ArchConcepts \| Last Touched \| Verified Date \| Score \| Source` | Header row missing `ArchConcepts` between `Tags` and `Last Touched` |
| `~/.claude/gabe-arch/STATE.md` | Missing | Present | File doesn't exist at `~/.claude/gabe-arch/STATE.md` |
| `~/.claude/gabe-arch/HISTORY.md` | Missing | Present | File doesn't exist at `~/.claude/gabe-arch/HISTORY.md` |

**Procedure for KNOWLEDGE.md wells migration:**

1. **Backup first:** copy file to `.kdbp/archive/KNOWLEDGE.md.pre-migrate-YYYYMMDD-HHMM.md`
2. **Preview the change:**
   ```
   SCHEMA MIGRATION — .kdbp/KNOWLEDGE.md
     Wells table: [current] cols → 7 cols (adds [list of missing: Analogy, Paths, Docs])
     Rows affected: [N]
     Backup: .kdbp/archive/KNOWLEDGE.md.pre-migrate-20260417-1805.md
   
     Proceed? (y/n)
   ```
3. **On confirm:** rewrite the wells table header AND each row with empty cells inserted for whichever columns are missing (Analogy, Paths, Docs). Preserve the `#`, `Name`, `Description`, `Topics` cells exactly.
4. **On skip/decline:** leave file as-is; warn that `/gabe-teach brief` may show "paths not set" / "no doc" and will backfill Analogy on first run.
5. **Follow-up hint** after successful migration: `ℹ Run /gabe-teach brief to backfill Analogy (via gabe-lens) and Paths (heuristic) for existing wells. Then /gabe-teach wells → [docs N] to assign doc paths, or /gabe-teach init-wells to rerun the full wizard including doc-stub scaffolding.`

**Procedure for KNOWLEDGE.md Topics table migration (ArchConcepts):**

1. Backup (same archive path as the wells migration — single backup per `update` run is fine).
2. **Preview:**
   ```
   SCHEMA MIGRATION — .kdbp/KNOWLEDGE.md
     Topics table: 10 cols → 11 cols (adds ArchConcepts between Tags and Last Touched)
     Topic rows affected: [N]
     Proceed? (y/n)
   ```
3. **On confirm:** rewrite the Topics header AND each existing topic row with an empty `ArchConcepts` cell inserted between `Tags` and `Last Touched`. Preserve all other cells exactly.
4. **On skip/decline:** leave file as-is; `/gabe-teach topics` will still function, just without architecture tagging for this project until the column is added.
5. Follow-up hint: `ℹ Existing topics were not retroactively tagged with arch concepts — only new topics surfaced after migration get tags. Run /gabe-teach topics to start building the architecture knowledge graph.`

**Procedure for ~/.claude/gabe-arch/ global state:**

1. If `~/.claude/gabe-arch/` does not exist, create it: `mkdir -p ~/.claude/gabe-arch`
2. If `~/.claude/gabe-arch/STATE.md` is missing, copy the template: `cp ~/.claude/templates/gabe/gabe-arch-STATE.md ~/.claude/gabe-arch/STATE.md`
3. If `~/.claude/gabe-arch/HISTORY.md` is missing, copy the template: `cp ~/.claude/templates/gabe/gabe-arch-HISTORY.md ~/.claude/gabe-arch/HISTORY.md`
4. These files are user-global (all projects share them), created lazily — never overwritten if already present.
5. During `reset` mode, do NOT touch `~/.claude/gabe-arch/` — the user's cross-project learning state is never lost by a per-project reset.

**No LLM calls during migration** — purely structural rewrite. Backfill happens later, on first brief run.

### Step 2: Check hooks

Check `~/.claude/settings.json` for these hooks:
- SessionStart hook (contains `KDBP Active`)
- SessionStart plan awareness (contains `ACTIVE PLAN` or `gabe-plan`)
- SessionStart knowledge awareness (contains `KNOWLEDGE:` or `gabe-teach`)
- PreToolUse checkpoint hook (contains `KDBP CHECKPOINT`)
- PostToolUse ledger writer (contains `LEDGER.md`)
- PostToolUse structure warning (contains `STRUCTURE:` — new-file placement)
- Stop session-end reminder (contains `SESSION-END REMINDER`)

For each missing hook:
- Show what will be added
- Ask: "Install? [Y/n]"
- If yes: read settings.json, parse JSON, append hook to the appropriate array, write back

If all hooks present: "All 7 KDBP hooks installed."

### Step 3: Project type

Ask: "Project type?"

For ALL project types, create doc stubs if they don't already exist. **Every stub gets a standards-reference marker as the first non-heading line**, pointing to the `gabe-docs` skill so downstream edits (by humans or by `/gabe-teach` auto-append) follow the house style:

```markdown
<!-- Standards: see ~/.claude/skills/gabe-docs/SKILL.md (CommonMark + Mermaid + analogy-first) -->
```

- **Agent app**:
  - `docs/architecture.md` with headings: `# Architecture`, `## Data Model`, `## API Contracts`, `## API Endpoints`, `## Integrations`
  - `docs/AGENTS_USE.md` with headings: `# Agent Documentation`, `## Agent Design`, `## Tools`, `## Prompts`, `## Safety`, `## Context Engineering`
  - `docs/SCALING.md` with headings: `# Scaling`, `## Observability`
  - Add U4-U8 to project VALUES.md + show agent blueprint checklist (see below)

- **Web app**:
  - `docs/architecture.md` with headings: `# Architecture`, `## Data Model`, `## API Contracts`, `## API Endpoints`

- **CLI**:
  - Ensure README.md has sections: `## Usage`, `## Installation`, `## Commands`

- **Library**:
  - `docs/api.md` with heading: `# API Reference`
  - Ensure README.md has sections: `## Installation`, `## Skills`, `## Commands`

For each stub, place the standards marker as an HTML comment on the second line (directly below the `# Heading` line). Skip the marker for README.md since those already exist and may have upstream conventions.

If **agent app** selected, also:
1. Add to `.kdbp/VALUES.md`:
```markdown
- **V1 — Enforce Output Structure:** Use PydanticAI output_type or equivalent. Never prompt-only. `story`
- **V2 — Stream Progress:** Any AI processing >5s must show real-time progress via SSE. `story`
- **V3 — Route by Cost:** Cheap model for classification, premium for reasoning. `story`
- **V4 — Measure Every Run:** Track cost, latency, token usage per pipeline run. `story`
```

2. Show the agent blueprint checklist:
```
Agent Application Checklist:
  □ 1. INTAKE      — Validate input, assign ID, return 202 Accepted
  □ 2. GUARDRAILS  — Regex patterns for prompt injection, boundary markers
  □ 3. CLASSIFY    — Cheap model (Gemini Flash) for severity/category
  □ 4. AGENT       — Premium model (Claude Sonnet) with tools + output_type
  □ 5. OUTPUT      — Schema-enforced response, fallback chain
  □ 6. DISPATCH    — Real integration (Linear/Slack/email)
  □ 7. STREAM      — SSE progress events
  □ 8. STATE       — PostgreSQL + Redis
  □ 9. OBSERVE     — Langfuse traces + Prometheus metrics

Each stage maps to a folder in STRUCTURE.md (api/guardrails/, api/agents/,
api/services/, api/observability/). Stages 1-5 are MVP; 6-9 are Enterprise.
```

### Step 4: Show readiness report

```
✅ .kdbp/ initialized (10 files + archive/)
✅ Hooks installed (7/7)
✅ Project type: [type]
✅ Maturity: [mvp|enterprise|scale]
✅ DOCS.md: [N] mappings loaded for [project-type]
✅ Doc stubs: [list of created doc files]

Next steps:
  1. Add project-specific values to .kdbp/VALUES.md
  2. Run /gabe-plan to create your first plan
  3. Start building — hooks will checkpoint automatically at commit
  4. Before your first /gabe-teach session, run /gabe-teach init-wells to define
     the architectural sections (gravity wells) topics will anchor to. The teach
     command also prompts for this automatically the first time it runs.
  5. After commits/pushes, run /gabe-teach to stay architect-level current with changes
  6. Run /gabe-health anytime for codebase health check
  7. Customize .kdbp/DOCS.md if your project structure differs from the standard
```

$ARGUMENTS
