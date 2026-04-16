---
name: gabe-help
description: "Context-aware guide for the Gabe Suite. Detects project state, shows what's configured, and suggests the right workflow. Usage: /gabe-help"
metadata:
  version: 1.0.0
---

# Gabe Help — Suite Entry Point

## Purpose

Answer one question: **"What should I do next with the Gabe Suite?"**

Scan the current project environment, detect what's configured, what's missing, and where the user is in their workflow. Then recommend specific commands with reasoning.

This is NOT a man page. It reads the actual state and gives contextual advice.

---

## Procedure

### Step 1: Environment Scan

Check each probe silently. Do NOT run commands that modify anything.

| Probe | How | Result |
|-------|-----|--------|
| **Git repo** | Check if `.git/` exists | yes / no |
| **Uncommitted changes** | `git status --porcelain` (if git repo) | count of changed files, or clean |
| **Alignment initialized** | Check if `.kdbp/` or `.kdbp/VALUES.md` exists | yes (with maturity from BEHAVIOR.md) / no |
| **User values** | Check if `~/.kdbp/VALUES.md` exists | yes (count of values) / no |
| **Cognitive profile** | Check if `~/.claude/gabe-lens-profile.md` exists | yes (suit name) / no |
| **Checkpoint ledger** | Check if `.kdbp/LEDGER.md` exists | yes (count of entries) / no |
| **Deferred items** | Check `.kdbp/deferred-cr.md` or `.planning/deferred-cr.md` | count of unresolved items / none |
| **GSD planning** | Check if `.planning/PROJECT.md` exists | yes / no |
| **Active phase** | Look for `.planning/phases/*/PLAN.md` without `VERIFICATION.md` | phase number or none |

### Step 2: Classify Situation

Based on the scan, classify into one of these situations:

| Situation | Conditions | Primary recommendation |
|-----------|------------|----------------------|
| **New machine** | No `~/.kdbp/VALUES.md`, no `~/.claude/gabe-lens-profile.md` | Set up user-level tools first |
| **New project** | Git repo exists, no `.kdbp/` | Initialize alignment |
| **Configured, idle** | `.kdbp/` exists, no uncommitted changes, no active phase | Start work or run health check |
| **Mid-work** | Uncommitted changes exist | Review before committing |
| **Pre-PR** | Changes staged or branch ahead of main | Review + prepare to ship |
| **Deferred debt** | Deferred items exist (any count) | Surface and triage deferred items |
| **Post-milestone** | GSD planning exists, no active phase | Retro + health check |

Multiple situations can be true simultaneously (e.g., "mid-work" + "deferred debt"). List all that apply, ordered by priority.

### Step 3: Output

```
GABE HELP — [project name from BEHAVIOR.md or directory name]

┌─ Environment ───────────────────────────────────────┐
│ Git repo:        ✅ [branch name]                    │
│ Changes:         [N files modified | clean]          │
│ Alignment:       ✅ Initialized (maturity: MVP)      │
│                  or ❌ Not initialized                │
│ User values:     ✅ N values | ❌ Not set up          │
│ Cognitive suit:  ✅ Spatial-Analogical | ❌ Default    │
│ Checkpoints:     ✅ N entries | ❌ No ledger           │
│ Deferred items:  ⚠️ N pending | ✅ None               │
│ GSD planning:    ✅ Phase N active | ❌ Not found      │
└─────────────────────────────────────────────────────┘

Situation: [classified situation(s)]

Suggested next:

  1. /command — [why this, based on current state]
  2. /command — [why this]
  3. /command — [why this]
```

---

## Recommendation Logic

### New Machine (first-time setup)

```
1. /gabe-lens calibrate     — Find your cognitive suit (one-time, ~3 min)
2. /gabe-align init-user    — Set your universal values (one-time, ~5 min)
3. /gabe-align init [name]  — Initialize this project (if in a project)
```

### New Project (no .kdbp/)

```
1. /gabe-align init [name]  — Set values + behavior + maturity for this project
2. /gabe-health             — Baseline: know where the fragile spots are
3. /gabe-lens annotate [key-file] — Gabe Blocks for the hardest parts (optional)
```

### Configured, Idle

```
1. /gabe-health             — Periodic check: has anything drifted?
2. /gabe-review deferred    — Any accumulated debt to address?
3. /gabe-align evolve       — Review value patterns from checkpoint history
```

### Mid-Work (uncommitted changes)

```
1. /gabe-review             — Risk-price your current changes before committing
2. /gabe-review brief       — Quick confidence score if you want speed
3. /gabe-align shallow      — Quick values check on what you're about to ship
```

### Pre-PR (branch ahead of main)

```
1. /gabe-review             — Full review with confidence score + triage
2. /gabe-push               — Push, create PR, watch CI, promote
3. /gabe-roast [perspective] [target] — Stress-test from a specific angle
```

### Post-Commit (committed, not pushed)

```
1. /gabe-push               — Push, create PR, watch CI
2. /gabe-review             — Double-check before shipping (if not done yet)
3. /gabe-assess bf [feature] — Quick impact check on what you're about to ship
```

### Deferred Debt (pending deferred items)

```
1. /gabe-review deferred    — See the backlog with confidence cost per item
2. /gabe-review fix         — Fix all deferred items in one pass
3. /gabe-health             — Check if deferred items cluster in fragile areas
```

### Post-Milestone

```
1. /gabe-health             — Full analysis: gods, churn, coupling, bugs, scope
2. /gabe-align evolve       — Review value patterns, graduate or tighten
3. /gabe-review deferred    — Clear any accumulated debt before next milestone
```

---

## Behavior Rules

1. **Read-only.** gabe-help never modifies files, creates directories, or writes output files. It only reads and recommends.
2. **Fast.** The scan should take < 5 seconds. Don't read file contents unless needed (e.g., maturity from BEHAVIOR.md frontmatter, suit from profile).
3. **No redundancy.** If the user just ran `/gabe-review`, don't suggest `/gabe-review` again. Check the conversation context.
4. **Honest gaps.** If something isn't set up, say so directly. Don't hedge with "you might want to consider." Say: "Not initialized. Run `/gabe-align init`."
5. **Max 5 suggestions.** More than 5 is noise. Pick the highest-value actions for the current state.
6. **Show the full suite on request.** If the user asks "what tools are available?" or similar, show the complete list:

```
The Gabe Suite — 10 tools (7 skills + 3 commands):

| Tool | Command | What it does |
|------|---------|-------------|
| gabe-help | /gabe-help | You are here. Context-aware guide. |
| gabe-lens | /gabe-lens [concept] | Cognitive translation — analogies, maps, constraint boxes |
| gabe-align | /gabe-align [mode] | Alignment guardian — values check + auto-checkpoint |
| gabe-assess | /gabe-assess [change] | Change impact — blast radius, maturity scope, prerequisites |
| gabe-roast | /gabe-roast [perspective] [target] | Adversarial gap review from a specific viewpoint |
| gabe-review | /gabe-review [target] | Code review with risk pricing + confidence score + triage |
| gabe-health | /gabe-health [focus] | Codebase structural health — gods, churn, coupling, bugs |
| gabe-init | /gabe-init [name] | Project setup — .kdbp/, hooks, project type, maturity |
| gabe-commit | /gabe-commit [msg] | Commit quality gate — deterministic checks, triage |
| gabe-push | /gabe-push | Push, create PR, watch CI, branch promotion |
```

---

## Integration

| From | Trigger | What gabe-help adds |
|------|---------|-------------------|
| User runs `/gabe-help` | Direct invocation | Full scan + recommendations |
| User seems lost | "What should I do?", "Where do I start?" | Suggest `/gabe-help` |
| Post-install | After `install.sh` runs | Suggest `/gabe-help` as first command |
