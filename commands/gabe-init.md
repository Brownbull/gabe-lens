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

**DECISIONS.md** — use template from `cherry-pick/kdbp/templates/DECISIONS.md`

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

**MAINTENANCE.md** — use template from `cherry-pick/kdbp/templates/MAINTENANCE.md`

**PLAN.md** — use template from `cherry-pick/kdbp/templates/PLAN.md`

**KNOWLEDGE.md** — use template from `cherry-pick/kdbp/templates/KNOWLEDGE.md`

**archive/** — create empty directory: `mkdir -p .kdbp/archive`

**DOCS.md** — use template from `cherry-pick/kdbp/templates/DOCS.md`:
- Select the section matching the project type chosen in Step 3
- Agent app → use the Agent App section
- Web app → use the Web App section
- CLI → use the CLI section
- Library → use the Library section
- Remove commented-out sections for other project types

### Step 1.5: Update Mode (only when user picked `update`)

Non-destructive top-up of an existing `.kdbp/` directory. Never overwrites, never deletes.

1. **Scan what's missing.** Compare the existing `.kdbp/` contents against the current template set:
   - Expected files: `BEHAVIOR.md`, `VALUES.md`, `DECISIONS.md`, `PENDING.md`, `LEDGER.md`, `MAINTENANCE.md`, `DOCS.md`, `PLAN.md`, `KNOWLEDGE.md`
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
   - For each missing template file: copy from `cherry-pick/kdbp/templates/[FILE]`
   - For `archive/`: run `mkdir -p .kdbp/archive`
   - For `DOCS.md` specifically: if missing, do NOT auto-select a project type — ask: "Project type? (agent-app | web-app | cli | library)" and use that section
   - Skip any file that already exists (never overwrite)

4. **Do NOT touch:**
   - `BEHAVIOR.md` — already has maturity, domain, tech (preserves user customization)
   - `VALUES.md` — user-authored content
   - Any file with existing content
   - Files outside the expected template set

5. **After file top-up, continue to Step 2 (hook check).** The hook check runs for both reset and update paths.

6. **After Step 2, skip Steps 3-4** (project type + readiness report). Instead show a condensed Update Report:
   ```
   UPDATE COMPLETE
     Files added:    [list]
     Directories:    [list]
     Hooks installed: [N] / [total]
     Preserved:      [count of files left untouched]
   ```

### Step 2: Check hooks

Check `~/.claude/settings.json` for these hooks:
- SessionStart hook (contains `KDBP Active`)
- SessionStart plan awareness (contains `ACTIVE PLAN` or `gabe-plan`)
- SessionStart knowledge awareness (contains `KNOWLEDGE:` or `gabe-teach`)
- PreToolUse checkpoint hook (contains `KDBP CHECKPOINT`)
- PostToolUse ledger writer (contains `LEDGER.md`)
- Stop session-end reminder (contains `SESSION-END REMINDER`)

For each missing hook:
- Show what will be added
- Ask: "Install? [Y/n]"
- If yes: read settings.json, parse JSON, append hook to the appropriate array, write back

If all hooks present: "All 6 KDBP hooks installed."

### Step 3: Project type

Ask: "Project type?"

For ALL project types, create doc stubs if they don't already exist:

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

Reference: arch-ref-lib Tier 9 (AI Agent Applications)
```

### Step 4: Show readiness report

```
✅ .kdbp/ initialized (9 files + archive/)
✅ Hooks installed (6/6)
✅ Project type: [type]
✅ Maturity: [mvp|enterprise|scale]
✅ DOCS.md: [N] mappings loaded for [project-type]
✅ Doc stubs: [list of created doc files]

Next steps:
  1. Add project-specific values to .kdbp/VALUES.md
  2. Run /gabe-plan to create your first plan
  3. Start building — hooks will checkpoint automatically at commit
  4. After commits/pushes, run /gabe-teach to stay architect-level current with changes
  5. Run /gabe-health anytime for codebase health check
  6. Customize .kdbp/DOCS.md if your project structure differs from the standard
```

$ARGUMENTS
