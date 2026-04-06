---
name: gabe-align
description: "Alignment guardian — manual pre-flight checks (shallow/standard/deep) plus automatic values + scenario checks at commit/PR boundaries. Usage: /gabe-align [mode] [target] or /gabe-align init [project]"
metadata:
  version: 2.0.0
---

# Gabe Align — Alignment Guardian

## Purpose

Two responsibilities:

1. **Manual alignment checks** — test proposed work against curated values BEFORE building. Three modes: shallow (quick), standard (full), deep (full + brief).
2. **Automatic checkpoint** — at commit/PR boundaries, evaluate values + test scenario coverage. Fires via hooks, no manual invocation needed.

---

## Modes

### Manual Checks

| Mode | Alias | Values Checked | Output | Use Case |
|------|-------|---------------|--------|----------|
| **shallow** | `sf`, `bf` | Core only (A1-A3) + project values | 3-5 lines inline | Quick sanity check, auto-trigger in gabe-roast |
| **standard** | (default) | All Standard (A1-A7+) + project values | Full alignment document | Before design, implementation, or non-trivial tasks |
| **deep** | `dp` | All + brief | Alignment document + alignment brief | Greenfield projects, new architectures, major decisions |

### Automatic Checkpoint

Fires at `git commit` / `gh pr create` via hook. Runs:
1. Values evaluation (user-level + project-level) — like shallow but with all loaded values
2. Scenario check — 3 realistic user scenarios per changed source file, check test coverage
3. Inline output — no separate document, just a summary before the commit proceeds

### Subcommands

| Command | What it does |
|---------|-------------|
| `/gabe-align init [name]` | Create `.kdbp/` with BEHAVIOR.md + VALUES.md (interactive) |
| `/gabe-align init-user` | Create `~/.kdbp/VALUES.md` (interactive) |
| `/gabe-align status` | Show current values (user + project) |
| `/gabe-align migrate` | Convert old `_kdbp/` to new `.kdbp/` format |
| `/gabe-align evolve` | Review value PASS/CONCERN frequency, suggest changes |

---

## Required Inputs (Manual Checks)

### 1. Target — What to check

| Input Type | Example |
|---|---|
| **Intent** | "build a memory system for my agents" |
| **File** | `/docs/architecture.md` |
| **Folder** | `/src/services/` |
| **Task reference** | `dev-story 42`, `code-review PR-17` |
| **Context** | "this conversation" |

### Artifact Discovery

When the target references a task/story/ticket:
1. Look for `sprint-status.yaml`, `TASKS.md`, `STORIES.md`, or similar in the current project root
2. If found, parse and locate the referenced task
3. If not found, ask: "I can't find a task tracking file. Where should I look? Or paste the task description."
4. If the task references other files (PRD, architecture doc, test plan), read those too

---

## Value Sources

Values load from three locations. All are read. Project-level has highest priority but doesn't replace others — they stack.

### Structural Values (part of the skill)

```
skills/gabe-align/VALUES.md — A1-A7 alignment values
```

Used in standard and deep modes. These are universal structural guards (user cognition, alternatives, validation before scale, etc.).

### User-Level Values (always loaded)

```
~/.kdbp/VALUES.md — Universal values, all projects
```

Created by `/gabe-align init-user`. Applied at every checkpoint and every manual check. Example:
```markdown
# User Values
- **U1 — Verify Before Shipping:** Taste the dish before serving
- **U2 — Say Why:** Transparent reasoning — never output without context
- **U3 — Two Roads:** Show alternatives before committing to foundational decisions
```

### Project-Level Values (loaded on top)

```
.kdbp/VALUES.md — Project-specific values
```

Created by `/gabe-align init`. Only loaded when working in that project. Example:
```markdown
# Project Values
- **V1 — One New Thing:** One new thing, rest familiar
- **V2 — Nothing Rots:** Use what's expiring before what's exciting
- **V5 — Health Walls:** Health constraints are walls, not suggestions
```

### At Checkpoint / Check Time

All loaded values are evaluated:
- Shallow: project (V*) + user (U*) values only
- Standard: project (V*) + user (U*) + structural (A1-A7)
- Deep: all + alignment brief
- Automatic checkpoint: project (V*) + user (U*) + scenario check

---

## Procedure (Manual Checks)

### Before Checking

1. Read `skills/gabe-align/VALUES.md` fully (structural A1-A7)
2. Read `~/.kdbp/VALUES.md` if exists (user values)
3. Read `.kdbp/VALUES.md` if exists (project values)
4. Identify mode from invocation (shallow / standard / deep)
5. Identify target and context type
6. If existing artifact: locate and read ALL referenced files
7. If available, load cognitive profile from `~/.claude/gabe-lens-profile.md`

### During Checking

8. For each applicable value (based on mode tier):
   a. State the value handle
   b. Apply the test question to the target
   c. Produce verdict: PASS, CONCERN, or FAIL
   d. If CONCERN or FAIL: explain WHAT specifically is misaligned and WHY
9. Check each value independently — don't let other results influence assessment
10. Be specific. "Violates A4" is not enough. State what's misaligned concretely.
11. Don't pad. If all values pass, say so. A forced CONCERN is worse than an honest PASS.

### After Checking

12. Produce the output format for the selected mode
13. If any value FAILs in standard or deep mode: list specific action items
14. If the check reveals a gap no existing value covers: propose a new value
15. If deep mode: produce the alignment brief
16. The alignment result IS the deliverable. Do not proceed to the task itself.

---

## Output Formats

### Shallow Mode

```
ALIGN (shallow): [target name]
U1 ✓ | U2 ✓ | V1 ✓ | V2 ⚠ [one-line concern] | A1 ✓ | A2 ✓ | A3 ✓
Status: PASS | PROCEED WITH CONCERNS | DO NOT PROCEED
```

### Standard Mode

```
GABE ALIGN: [target name]
Date: YYYY-MM-DD

VALUES CHECKED: N
PASS: X | CONCERN: Y | FAIL: Z

U1 ✓ PASS — [one-line explanation]
V1 ✓ PASS — [one-line explanation]
V2 ⚠ CONCERN — [explanation + what to do about it]
A1 ✓ PASS — [one-line explanation]
A2 ✗ FAIL — [explanation + what the alternative looks like]
...

ACTION ITEMS:
1. [specific action for each concern/failure]

ALIGNMENT: PROCEED | PROCEED WITH CONCERNS | DO NOT PROCEED
```

### Deep Mode

Same as Standard, plus:

```
═══ ALIGNMENT BRIEF ═══

## Intent
[Restated for clarity — what we're trying to achieve]

## Cognitive Profile Constraints
[From gabe-lens suit. What this means for structural decisions.]

## Structural Risks
[Risks identified by value checks — what's likely to go wrong]

## Recommended Approach
[Based on value alignment, what direction to take]

## Open Questions
[Must be resolved before designing]

## Values to Watch
[Which values are most at risk during implementation]
```

### Automatic Checkpoint (at commit/PR)

```
📋 KDBP Checkpoint — Pre-Commit

Values (U=user, V=project):
  U1 — Verify Before Shipping: ✅ PASS
  U2 — Say Why: ⚠️ CONCERN — new error message gives no context
  V1 — One New Thing: ✅ PASS

Test Scenarios:
  suggestRecipes.ts:
    ✅ User with pantry items gets suggestions
    ❌ Empty pantry → shows what? (no test)
    ❌ Rate limit hit → user sees what? (no test)

Action: 2 untested scenarios + 1 value concern.
  Fix now, or commit and track as deferred: /gabe-review deferred
```

---

## Scenario Check (Automatic Checkpoint Only)

At commit/PR boundaries, after evaluating values, Claude reads the modified source files and their test files:

**For each feature or behavior added/changed in the diff:**
1. Name 3 realistic scenarios a user would hit (including error states, empty data, edge conditions)
2. Check if each scenario has a corresponding test
3. Report COVERED or NOT COVERED per scenario

**What counts as a "realistic scenario":**
- NOT contrived inputs or theoretical edge cases
- YES conditions a real user of THIS application would hit
- Think: empty data, network failure, duplicate action, slow dependency, missing permissions

**Skip the scenario check when:**
- Only `.md`, `.json`, `.yaml`, or config files changed (no source code)
- Trivial fix (single-line typo, import fix)

---

## Project Files

```
.kdbp/
├── BEHAVIOR.md     # Project name, domain, maturity, active focus (~500 words)
├── VALUES.md       # Project-specific value handles (3-7 values)
└── deferred-cr.md  # Shared with gabe-review (created on first deferral)
```

User-level:
```
~/.kdbp/
└── VALUES.md       # Universal value handles (3-5 values)
```

### BEHAVIOR.md Format

```yaml
---
name: [project-behavior-name]
domain: [what the project does]
maturity: mvp | enterprise | scale
tech: [comma-separated stack]
created: [date]
---
```

Followed by markdown describing purpose, active focus, and constraints. Keep under 500 words.

### VALUES.md Format

```markdown
# [User|Project] Values

- **[ID] — [Name]:** [One sentence a tired developer can read and immediately know what to do]
```

Rules:
- Maximum 7 per level (user: 3-5, project: 3-7)
- Each must be testable: you can look at a diff and say PASS or CONCERN
- Use the project's language, not abstract principles
- User-level IDs: U1, U2, U3...
- Project-level IDs: V1, V2, V3...

---

## Init Subcommand

### `/gabe-align init [project-name]`

Creates `.kdbp/` in the current project. Interactive:

1. "What does this project do?" → generates BEHAVIOR.md
2. "What's the last mistake that slipped through?" → suggests a value
3. "What decision do you keep revisiting?" → suggests a value
4. "What keeps breaking between sprints?" → suggests a value
5. Presents suggested values + the user-level values (if they exist)
6. User picks, modifies, or replaces → writes VALUES.md

### `/gabe-align init-user`

Creates `~/.kdbp/VALUES.md` if it doesn't exist. Same discovery questions but aimed at cross-project patterns.

### `/gabe-align migrate`

Reads old `_kdbp/behaviors/*/VALUES.md` and `BEHAVIOR.md`. Copies values and behavior into new `.kdbp/` format. Discards workflows, commands, hooks, protocol docs.

### `/gabe-align evolve`

Reviews recent checkpoint results. Counts per-value PASS/CONCERN frequency. Suggests:
- Values violated 3+ times → "Reword, escalate, or accept?"
- Values passing 10+ times → "Internalized — graduate out, or keep as safety net?"

---

## New Value Proposal

When a check reveals a gap no existing value covers:

1. Surface it: "No existing value addresses [specific concern]"
2. Propose:
   ```
   [U/V/A]X — "[handle]"
   Guards against: [what]
   Test: "[question]"
   Tier: [Core / Standard / Extended]
   ```
3. User approves, rejects, or modifies
4. If approved: added to the appropriate VALUES.md

---

## Hook Installation

Two entries in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "VALUES=''; if [ -f ~/.kdbp/VALUES.md ]; then VALUES=\"USER_VALUES=$(head -20 ~/.kdbp/VALUES.md)\"; fi; if [ -f .kdbp/VALUES.md ]; then VALUES=\"$VALUES PROJECT_VALUES=$(head -20 .kdbp/VALUES.md)\"; fi; if [ -f .kdbp/BEHAVIOR.md ]; then VALUES=\"$VALUES BEHAVIOR=$(head -10 .kdbp/BEHAVIOR.md)\"; fi; if [ -n \"$VALUES\" ]; then echo \"{\\\"additionalContext\\\": \\\"KDBP Active. $VALUES\\\"}\"; fi",
        "timeout": 3000
      }]
    }],
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "TOOL_INPUT=$(cat); if echo \"$TOOL_INPUT\" | grep -qE '\"command\".*git commit|\"command\".*gh pr'; then if [ -f ~/.kdbp/VALUES.md ] || [ -f .kdbp/VALUES.md ]; then echo '{\"additionalContext\": \"KDBP CHECKPOINT: Before committing, evaluate all values (from ~/.kdbp/VALUES.md and .kdbp/VALUES.md) against git diff. For each changed source file, name 3 realistic user scenarios (including errors, empty data, edge conditions) and check if each has a test. Report per-value PASS/CONCERN and per-scenario COVERED/NOT COVERED. If untested scenarios exist, suggest writing tests before committing.\"}'; fi; fi",
        "timeout": 3000
      }]
    }]
  }
}
```

---

## Integration with Gabe Suite

### Pre-roast gate

Before executing any roast, gabe-roast runs a shallow alignment:
1. Read target
2. Run gabe-align shallow (core values A1-A3 + project values)
3. If all PASS: proceed to roast
4. If CONCERN: print warning, proceed
5. If FAIL: print warning + "Foundational alignment issue. Consider /gabe-align standard. Proceed? [y/n]"

### Cross-tool suggestions

| Checkpoint result | Suggested action |
|-------------------|-----------------|
| All values PASS, all scenarios COVERED | Commit freely |
| Value CONCERN | Review the diff for that value. Fix or accept. |
| Untested scenarios | Write tests for ❌ scenarios. Or: `/gabe-roast qa [file]` |
| Both CONCERN + untested | `/gabe-review` for full risk-priced review |
| Alignment doubt (wrong direction?) | `/gabe-align standard` for full check |

---

## Error Taxonomy (Reference)

| Type | Name | Caught by |
|------|------|-----------|
| A | Syntax/Build | Build tools, CI |
| B | Logic | Tests, code review |
| C | Integration | E2E tests |
| D | Performance | Profiling, /ag-perf |
| E | UX | /gabe-roast UX perspective |
| **F** | **Alignment** | **Values check (this tool)** |
| **G** | **Coverage** | **Scenario check (this tool)** |

---

## When to Use

**Always use for:**
- New projects or architectures (deep mode)
- Before first roast on any artifact (shallow, auto)
- Starting work on a new epic or major feature

**Automatic (no action needed):**
- At every `git commit` and `gh pr create` — hook fires checkpoint

**Don't use for:**
- Trivial bug fixes or typo corrections
- Tasks where alignment was already checked and nothing changed
