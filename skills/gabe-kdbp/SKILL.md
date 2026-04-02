---
name: gabe-kdbp
description: "Lightweight alignment guardian. Loads project values at session start, watches for drift signals (gravity wells, scope creep, refactor-without-test), and suggests the right Gabe tool at the right moment. Usage: /gabe-kdbp init [project-name]"
metadata:
  version: 1.0.0
---

# Gabe KDBP — Alignment Guardian Skill

## Purpose

Watch for alignment drift during development sessions. Load project values at session start, silently monitor file edits for drift signals, and suggest the right Gabe tool when something looks off. Record what happened in a session ledger.

This skill does NOT run workflows, enforce rules, or block tool execution. It watches and suggests — a foreman who taps your shoulder, not a guard who blocks the door.

---

## When to Use

### Initialize a project
```
/gabe-kdbp init [project-name]
```
Creates `.kdbp/` directory with BEHAVIOR.md, VALUES.md, config.yaml, and LEDGER.md. Interactive — asks about project domain, maturity, and core values.

### Check status
```
/gabe-kdbp status
```
Shows current session state: edit counts, gravity wells, test gaps, scope breaches.

### View ledger
```
/gabe-kdbp ledger
```
Shows recent session history from LEDGER.md.

### Manual alignment check
```
/gabe-kdbp check
```
Runs all 4 checks immediately against current session state and reports findings.

---

## Project Files

When initialized, creates this structure in the project root:

```
.kdbp/
├── BEHAVIOR.md          # What this project is, domain, maturity, active focus
├── VALUES.md            # Value handles — one-liners that survive compaction
├── DEPENDENCY-MAP.md    # Which files are in scope (optional, created manually)
├── config.yaml          # Watcher thresholds
├── deferred-cr.md       # Deferred code review items (shared with gabe-cr)
└── LEDGER.md            # Session log (auto-appended)
```

**Total footprint:** ~5-10KB per project.

---

## BEHAVIOR.md Format

```yaml
---
name: [project-behavior-name]
domain: [what the project does]
maturity: mvp | enterprise | scale
tech: [comma-separated stack]
created: [date]
---
```

Followed by markdown describing the project's purpose, active focus, and constraints. Keep it under 500 words — it's loaded into context at session start.

---

## VALUES.md Format

Each value is a one-liner handle that survives context compaction and late-night fatigue.

```markdown
# Values

- **V1 — [Name]:** [One sentence that a tired developer can read and immediately know what to do]
- **V2 — [Name]:** [Same format]
- ...
```

Guidelines for writing value handles:
- Maximum 7 values (cognitive limit)
- Each must be testable: you can look at a piece of work and say "this passes V1" or "this violates V1"
- Use the project's language, not abstract principles
- Start with 3 core values, add more only when you discover a recurring drift pattern

### Starter Values (suggested during init)

| Value | Handle | When to use |
|---|---|---|
| V1 — User First | Every decision starts from "does this help the user?" | Always |
| V2 — Test What Branches | Every new error handling path gets a test in the same PR | When adding try/catch, fallbacks, fail-open |
| V3 — Ship Small | Prefer 3 small PRs over 1 large PR | When scope grows |

The user chooses which to keep, modify, or replace during init.

---

## config.yaml Format

```yaml
# Watcher thresholds
gravity_well_edits: 5        # Same file edited N+ times → suggest /gabe-assess
drift_check_interval: 20     # Every N total edits → suggest /gabe-align shadow
refactor_test_gap: 3          # Src file edited N+ times without .test. edit → warn
scope_creep: true             # Check DEPENDENCY-MAP.md if it exists

# Session state location
state_dir: /tmp               # Where session state JSON is stored
```

---

## The 4 Checks

### Check 1: Gravity Well

**Signal:** Same file edited `gravity_well_edits` times (default: 5)
**Meaning:** You're either stuck in a local optimum or the file is growing too complex.
**Suggestion:**
```
🔄 Gravity well: [file] edited [N] times this session.
   Are you stuck, or is this file doing too much?
   Consider: /gabe-assess [file]
```

### Check 2: Scope Creep

**Signal:** File edited that's NOT in DEPENDENCY-MAP.md (if the map exists)
**Meaning:** Work is spreading beyond the planned scope.
**Suggestion:**
```
📡 Scope signal: [file] is outside your dependency map.
   Intentional tangent or accidental drift?
   Consider: /gabe-assess [describe the tangent]
```

Only fires if `.kdbp/DEPENDENCY-MAP.md` exists. If no map, this check is silently skipped.

### Check 3: Periodic Alignment

**Signal:** Every `drift_check_interval` total edits (default: 20)
**Meaning:** Scheduled pause to check direction.
**Suggestion:**
```
📐 Alignment checkpoint: [N] edits since session start.
   Quick check — still heading where you intended?
   Consider: /gabe-align shadow
```

### Check 4: Refactor Without Test

**Signal:** Source file edited `refactor_test_gap` times AND no corresponding `.test.` or `.spec.` file edited in same session.
**Meaning:** Heavy modification without test updates — coverage gap forming.
**Detection logic:**
- Track edits to files in `src/`, `lib/`, `app/`, `functions/src/`, or any non-test source directory
- For each file with N+ edits, check if `[filename].test.[ext]` or `[filename].spec.[ext]` was edited
- Also check if any file in `__tests__/` or `tests/` matching the module name was edited
**Suggestion:**
```
🧪 Test gap: [file] edited [N] times but no test file touched.
   New branches without tests become invisible production risks.
   Consider: /gabe-cr or /gabe-roast qa [file]
```

---

## Bookend Pattern

### Session Start (Bookend In)

When the user starts a session in a project that has `.kdbp/`:

1. Read `.kdbp/BEHAVIOR.md` — extract name, domain, maturity, active focus
2. Read `.kdbp/VALUES.md` — extract value handles
3. Initialize session state (edit counts, timestamps)
4. Append session start entry to `.kdbp/LEDGER.md`
5. Surface to the user:

```
📋 KDBP Active — [behavior name] ([domain])
   Maturity: [mvp|enterprise|scale]
   Values: [V1 one-liner] | [V2 one-liner] | [V3 one-liner]
   Focus: [active focus from BEHAVIOR.md]
   Deferred CR items: [N pending, M escalated]
```

### Session End (Bookend Out)

When the session ends or the user runs `/gabe-kdbp status`:

1. Compute session summary from state
2. Append to `.kdbp/LEDGER.md`:

```markdown
## [date] [time] — Session End
- Edits: [total] across [file count] files
- Gravity wells: [list of files with 5+ edits, or "none"]
- Test gaps: [list of src files with no test edit, or "none"]
- Scope breaches: [list of files outside dep map, or "none"]
- Alignment checks: [count of periodic checks that fired]
- Type F signals: [YES if any gravity wells, test gaps, or scope breaches | "none"]
```

---

## Hook Installation

To run automatically (recommended), add these hooks to `.claude/settings.json` or the project's `.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "if [ -d .kdbp ]; then echo '{\"additionalContext\": \"KDBP: Load .kdbp/BEHAVIOR.md and .kdbp/VALUES.md at session start. Surface project values to user.\"}'; fi",
        "timeout": 3000
      }]
    }]
  }
}
```

Alternatively, the checks can be run manually via `/gabe-kdbp check` at any time without hooks.

---

## DEPENDENCY-MAP.md Format

```markdown
# Dependency Map — [Feature/Epic Name]

## In Scope
- src/pages/RecipeDetailPage.tsx
- src/components/RecipeCard.tsx
- src/services/recipes.ts

## Shared (touch with caution)
- src/services/pantry.ts
- firestore.staging.rules

## Out of Scope
- functions/src/ (backend changes not planned this phase)
```

This file is manually created/updated when starting a new feature or phase. It's optional — if absent, Check 2 (scope creep) is silently skipped.

---

## Error Taxonomy (Reference)

Inherited from KDBP Full — useful context for understanding what Type F means:

| Type | Name | Caught by |
|------|------|-----------|
| A | Syntax/Build | Build tools, CI |
| B | Logic | Tests, code review |
| C | Integration | E2E tests |
| D | Performance | Profiling, /ag-perf |
| E | UX | /gabe-roast UX perspective |
| **F** | **Alignment** | **/gabe-align, /gabe-kdbp watcher** |

Type F is the only error that survives all other checks — technically correct code heading in the wrong direction. That's what this skill exists to catch.

---

## Integration with Gabe Suite

| KDBP Signal | Gabe Tool Suggested | Why |
|-------------|-------------------|-----|
| Gravity well (5+ edits) | `/gabe-assess` | Stuck in a local optimum? Check blast radius. |
| Scope creep (outside dep map) | `/gabe-assess` | Tangent or drift? Check impact. |
| Periodic alignment (every N edits) | `/gabe-align shadow` | Quick values check — still on track? |
| Refactor without test | `/gabe-cr` or `/gabe-roast qa` | Coverage gap forming — price the risk. |
| Session end with Type F signals | `/gabe-roast architect` | Step-back roast of the session's output. |
| Major decision point (manual) | `/gabe-align standard` | Full alignment check before committing. |

---

## What This Does NOT Do

- Does NOT run code reviews (use /gabe-cr, CE:review, or BMad code-review)
- Does NOT plan features (use GSD or CE workflows)
- Does NOT enforce rules (all checks are advisory, never block)
- Does NOT replace CLAUDE.md (values live in .kdbp/)
- Does NOT require any specific framework, tech stack, or workflow engine
- Does NOT require hooks to function (can be run manually via /gabe-kdbp check)
