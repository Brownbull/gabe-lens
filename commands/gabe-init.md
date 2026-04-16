---
name: gabe-init
description: "Initialize a project with KDBP stack — creates .kdbp/, installs hooks, configures by project type. Usage: /gabe-init [project-name]"
---

# Gabe Init

One-command project setup. Wraps three operations into a single flow.

## Procedure

### Step 1: Create .kdbp/ directory

Run the equivalent of `/gabe-align init [project-name]`:

1. If `.kdbp/` already exists, show status and ask: "Reset or skip init?"
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
└── DOCS.md          # Doc drift mappings (from project type, used by CHECK 7)
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

**DOCS.md** — use template from `cherry-pick/kdbp/templates/DOCS.md`:
- Select the section matching the project type chosen in Step 3
- Agent app → use the Agent App section
- Web app → use the Web App section
- CLI → use the CLI section
- Library → use the Library section
- Remove commented-out sections for other project types

### Step 2: Check hooks

Check `~/.claude/settings.json` for these hooks:
- SessionStart hook (contains `KDBP Active`)
- PreToolUse checkpoint hook (contains `KDBP CHECKPOINT`)
- PostToolUse ledger writer (contains `LEDGER.md`)
- Stop session-end reminder (contains `SESSION-END REMINDER`)

For each missing hook:
- Show what will be added
- Ask: "Install? [Y/n]"
- If yes: read settings.json, parse JSON, append hook to the appropriate array, write back

If all hooks present: "All 4 KDBP hooks installed."

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
✅ .kdbp/ initialized (7 files)
✅ Hooks installed (4/4)
✅ Project type: [type]
✅ Maturity: [mvp|enterprise|scale]
✅ DOCS.md: [N] mappings loaded for [project-type]
✅ Doc stubs: [list of created doc files]

Next steps:
  1. Add project-specific values to .kdbp/VALUES.md
  2. Start building — hooks will checkpoint automatically at commit
  3. Run /gabe-health anytime for codebase health check
  4. Customize .kdbp/DOCS.md if your project structure differs from the standard
```

$ARGUMENTS
