<div align="center">

<img src="assets/gabe-lens-hero.png" alt="gabe-suite" width="600">

# Gabe Suite

**Development suite for Claude Code**

Skills, commands, and hooks for understanding, reviewing, deciding, and shipping — with a knowledge system (KDBP) that tracks values, decisions, and deferred work across sessions.

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude_Code-Plugin-blueviolet.svg?style=flat-square&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IndoaXRlIiBzdHJva2Utd2lkdGg9IjIiPjxwYXRoIGQ9Ik0xMiAyTDIgN2wxMCA1IDEwLTUtMTAtNXoiLz48cGF0aCBkPSJNMiAxN2wxMCA1IDEwLTUiLz48cGF0aCBkPSJNMiAxMmwxMCA1IDEwLTUiLz48L3N2Zz4=)](https://github.com/khujta/gabe-suite)
[![Version](https://img.shields.io/badge/version-2.2.0-green.svg?style=flat-square)](https://github.com/khujta/gabe-suite)
[![GitHub Stars](https://img.shields.io/github/stars/khujta/gabe-suite?style=flat-square&color=yellow)](https://github.com/khujta/gabe-suite/stargazers)

*Not a prompt template. Built from empirical self-observation.*

</div>

> **Name note.** The project/suite is **Gabe Suite**. One of the skills inside it is called **Gabe Lens** (invoked via `/gabe-lens`) — the cognitive-translation layer. They're different things: the suite contains the skill. Previous name for the suite was "Gabe Lens" — this repo was renamed to avoid collision.

## The Suite

### Skills (7)

| Skill | Command | What it does |
|---|---|---|
| **Gabe Lens** | `/gabe-lens` | Cognitive translation — analogies, spatial maps, constraint boxes, one-line handles |
| **Gabe Align** | `/gabe-align` | Values enforcement — pre-flight checks + auto-checkpoint at commit/PR |
| **Gabe Review** | `/gabe-review` | Code review — risk pricing, confidence scoring, interactive triage, deferred items |
| **Gabe Roast** | `/gabe-roast` | Adversarial gap review — stress-tests from a required perspective |
| **Gabe Assess** | `/gabe-assess` | Change impact — blast radius, maturity scope, prerequisites, alternatives |
| **Gabe Health** | `/gabe-health` | Codebase health — god files, churn hotspots, coupling, deferred items, maintenance |
| **Gabe Help** | `/gabe-help` | Context-aware guide — scans environment, suggests the right tool |

### Commands (5)

| Command | What it does |
|---|---|
| `/gabe-init` | Project setup — creates `.kdbp/`, installs hooks, selects project type + maturity |
| `/gabe-commit` | Commit quality gate — deterministic checks, interactive triage, defer/accept/fix per finding |
| `/gabe-push` | Push, create PR, watch CI, promote branches — the post-commit shipping workflow |
| `/gabe-plan` | KDBP-aware planning — persists plan to `.kdbp/PLAN.md`, lifecycle (complete/defer/cancel) with archive |
| `/gabe-teach` | Human knowledge consolidation — tracks WHY/WHEN/WHERE topics from recent commits with Socratic verification |

### KDBP System

The Knowledge, Decisions, Behavior, and Pending system tracks project state across sessions:

```
.kdbp/
├── BEHAVIOR.md      # Project name, domain, maturity, tech stack
├── VALUES.md        # 3-7 project-specific values (checked at commit)
├── DECISIONS.md     # Append-only architecture decision table
├── PENDING.md       # Deferred items with priority and escalation
├── LEDGER.md        # Session checkpoint history (auto-appended)
├── MAINTENANCE.md   # Quarterly human checklist
├── PLAN.md          # Active plan (written by /gabe-plan)
├── KNOWLEDGE.md     # Human knowledge map (managed by /gabe-teach)
└── archive/         # Archived plans (completed_, defer_, cancelled_)
```

User-level values at `~/.kdbp/VALUES.md` apply across all projects.

### Hooks (6, installed to `~/.claude/settings.json`)

| Hook | Event | What it does |
|---|---|---|
| KDBP values loader | SessionStart | Loads user + project values into context |
| Plan awareness | SessionStart | Surfaces active plan goal, phase, and staleness |
| Knowledge awareness | SessionStart | Surfaces pending and stale KNOWLEDGE.md topics |
| Commit gate | PreToolUse (Bash) | Runs deterministic checks on `git commit`, blocks on CRITICAL |
| Ledger writer | PostToolUse (Bash) | Auto-appends commit entries to `.kdbp/LEDGER.md` |
| Session-end reminder | Stop | Reminds about deferred items, scope changes, and active plan |

### Workflows

| I need to... | Use |
|---|---|
| Start a new project | `/gabe-init [name]` |
| Check values alignment | `/gabe-align [shallow/standard/deep]` |
| Understand a concept | `/gabe-lens [concept]` |
| Find gaps in a design | `/gabe-roast [perspective] [target]` |
| Assess a change | `/gabe-assess [change]` |
| Review code | `/gabe-review` |
| Check codebase health | `/gabe-health` |
| Commit with quality checks | `/gabe-commit [message]` |
| Push, create PR, watch CI | `/gabe-push` |
| Create or manage a plan | `/gabe-plan [goal]` |
| Consolidate architect-level understanding | `/gabe-teach [topics/status/free]` |
| What tool do I need? | `/gabe-help` |

### Architecture Reference

For application stack decisions (Python + FastAPI + PydanticAI + React + Bun), see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## Gabe Lens

### See it in action

Ask `/gabe-lens enforcement tiers` and get this:

```
┌─── GABE BLOCK: Enforcement Tiers ──────────────────────┐
│                                                        │
│  THE PROBLEM                                           │
│  Rules written in docs get ignored under fatigue and   │
│  context loss. 19 files exceeded the 800-line limit    │
│  despite the limit being documented everywhere.        │
│                                                        │
│  THE ANALOGY                                           │
│  Think of it as gravity vs. posted speed limits.       │
│  Gravity (Tier 1 hooks) works whether you're paying    │
│  attention or not — drop a ball, it falls. Speed       │
│  limits (Tier 3 docs) only work if the driver reads    │
│  the sign AND chooses to comply. Tier 2 (workflows)    │
│  is like a speed bump — it slows you down IF you       │
│  drive over it, but you can take a different road.     │
│                                                        │
│  THE MAP                                               │
│                                                        │
│    Tier 1: GRAVITY ══════════════════► Always works    │
│    (hooks)    PreToolUse ─→ fires every edit           │
│               pre-commit ─→ fires every commit         │
│                                                        │
│    Tier 2: SPEED BUMPS ─ ─ ─ ─ ─ ─ ─► Works if used    │
│    (workflows) /review ─→ only if invoked              │
│                                                        │
│    Tier 3: POSTED SIGNS · · · · · · ·► Often ignored   │
│    (docs)     CLAUDE.md rules ─→ lost after compaction │
│                                                        │
│  CONSTRAINT BOX                                        │
│    IS:      A reliability classification for rules     │
│    IS NOT:  A quality judgment (Tier 3 rules aren't    │
│             bad rules — they're just badly placed)     │
│    DECIDES: Where to invest enforcement effort —       │
│             convert Tier 3 lessons into Tier 1 hooks   │
│                                                        │
│  ONE-LINE HANDLE                                       │
│  "Hooks are gravity — docs are speed limit signs"      │
│                                                        │
│  SIGNAL: Quick check ✓                                 │
│  (The concept is intuitive once you see the tiers.     │
│   Don't overthink — the tier system IS the insight.)   │
└────────────────────────────────────────────────────────┘
```

That one-line handle — *"Hooks are gravity — docs are speed limit signs"* — stuck for weeks. The original 3-paragraph explanation didn't last a day.

## Install

```bash
git clone https://github.com/khujta/gabe-suite.git
cd gabe-suite
./install.sh              # Install all skills + commands
./install.sh --dry-run    # Show what would be done
./install.sh --uninstall  # Remove everything
```

After install, initialize a project:

```
/gabe-init [project-name]
```

This creates `.kdbp/`, installs hooks, and asks about project type and maturity.

## Usage

### Full block (default)

```
/gabe-lens [concept or question]
```

All components: problem, analogy, map, constraint box, one-line handle. ~200-350 tokens.

### Brief

```
/gabe-lens bf [concept]
```

Constraint box + one-line handle only. ~40-80 tokens. For previously introduced concepts.

### Oneliner

```
/gabe-lens ol [concept]
```

Just the memorable phrase. ~5-15 tokens. For compaction handoffs or re-anchoring.

### Annotate a document

```
/gabe-lens an [file-path]
```

Reads a file and produces a companion with Gabe Blocks for the 3-5 most critical concepts.

## Compression modes

| Context | Mode | Command | Tokens |
|---|---|---|---|
| First encounter with a concept | Full | `/gabe-lens` | ~200-350 |
| Referencing a known concept | Brief | `/gabe-lens bf` | ~40-80 |
| Compaction handoff or re-anchoring | Oneliner | `/gabe-lens ol` | ~5-15 |

## Analogy domains

Physical systems you can visualize in 3D, in preference order:

1. **Mechanical** — gears, valves, pulleys
2. **Fluid dynamics** — pressure, flow, reservoirs
3. **Optics** — lenses, mirrors, refraction
4. **Chemistry** — reactions, catalysts, equilibrium
5. **Electromagnetism** — fields, circuits, charges
6. **Thermodynamics** — heat, entropy, engines
7. **Biology** — cells, ecosystems, evolution

If no good physical analogy exists, the skill says so explicitly rather than forcing a weak metaphor.

## Cognitive Suits

Not everyone thinks the same way. Gabe Lens adapts its output to match how your brain works.

| Suit | Style | Example handle for "caching" |
|---|---|---|
| **Spatial-Analogical** (default) | Physical metaphors, 3D diagrams | "A fridge next to the stove" |
| **Sequential-Procedural** | Step-by-step, process flows | "Check the shelf before the warehouse" |
| **Abstract-Structural** | Patterns, types, relationships | "Every cache is a trade: space for time" |
| **Narrative-Contextual** | Stories, characters, scenarios | "The barista remembers your order" |

### Calibrate

```
/gabe-lens-calibrate
```

Presents the same concept in all 4 suits. Pick the one that clicks. Your choice is saved globally and used for all future `/gabe-lens` output.

To reset to default: `/gabe-lens-calibrate reset`

---

## Gabe Roast

Adversarial gap review. Adopts a perspective (architect, UX designer, security auditor, etc.) and attacks a target to find what's missing, broken, or risky.

### See it in action

Ask `/gabe-roast "UX Designer" MOCKUP-PLAN.md` and get:

```
GABE ROAST: MOCKUP-PLAN.md
Perspective: UX Designer

═══ MVP ════════════════════════════════════════════════

CRITICAL

  M1
  **Gap:** The plan starts with 12 isolated screen mockups
  but defines no user flow diagrams. Each screen is designed
  in a vacuum.
  **One-liner:** "Building rooms before drawing the hallways"
  **Effort:** M (confident)
  **Lose:** Every screen gets reworked once flows reveal they
  don't connect.

HIGH

  M2
  **Gap:** Component library is extracted BEFORE screens exist.
  **One-liner:** "Packing a suitcase before knowing the destination"
  **Effort:** S (confident)
  **Lose:** Component library gets rebuilt from scratch once
  real screens reveal actual patterns.

────────────────────────────────────────────────────────
TOTAL: 2 gaps — 1 critical, 1 high
```

### Usage

Both inputs are **required** — if either is missing, the skill asks before proceeding.

```
/gabe-roast [perspective] [target]
```

**Brief mode** (table format):

```
/gabe-roast bf [perspective] [target]
```

### Classification

Gaps are grouped by **maturity level** (MVP / Enterprise / Scale), then by **importance** (Critical / High / Medium / Low). Each gap includes a Gabe Lens one-liner, effort estimate with confidence, and the cost of inaction.

---

## Gabe Assess

Rapid change impact assessment. Pauses before an "obvious yes" to surface what a proposed change actually means before you commit.

### See it in action

Someone proposes fixing CORS on a shared staging bucket. Before saying yes:

```
/gabe-assess Fix Storage CORS for staging scan testing
```

```
GABE ASSESS: Fix Storage CORS for staging scan testing
Context: blocker

D1 BLAST RADIUS: External
   Bucket is shared with Gustify. CORS changes affect all apps.

D2 MATURITY SCOPE: MVP
   Current: MVP. Proposed: MVP-appropriate config change.
   Match — but shared infra elevates risk.

D3 PREREQUISITES:
   - Verify Gustify doesn't have its own CORS config
   - Check who deploys staging rules (INC-001)

D4 ALTERNATIVES:
   [A] Do nothing — defer E2E, unit tests already prove it
   [B] Minimal    — gsutil cors set + allowedEmails entry (S)
   [C] Proper     — combined rules deploy from Gustify repo (M)
   [D] Workaround — test via admin script, bypass client (S)

RECOMMENDATION: [B] — neither change touches shared rules file
ONE-LINER: "Bucket knob and guest list — don't redecorate the shared house"
```

### Usage

```
/gabe-assess [change description]           # Full assessment
/gabe-assess bf [change]                    # Brief (4 lines)
/gabe-assess il [change]                    # Inline (1 sentence)
/gabe-assess batch [change 1] + [change 2]  # Multiple changes
```

### Assessment dimensions

| Dimension | Question |
|---|---|
| **D1 Blast Radius** | What does this touch? (Contained / Local / Cross-cutting / External) |
| **D2 Maturity Scope** | Is this the right level of fix for where we are? (MVP / Enterprise / Scale) |
| **D3 Prerequisites** | What must be true before this change is safe? |
| **D4 Alternatives** | Is there a simpler, cheaper, or more appropriate path? |

---

## Embedding in workflows

```yaml
project_knowledge:
  optional:
    - "skills/gabe-lens/SKILL.md"
    - "skills/gabe-roast/SKILL.md"
```

One-line handles from both skills enhance compaction handoff notes by surviving context compression.

## The origin story

<details>
<summary>How gabe-lens was built from a cognitive self-observation experiment</summary>

gabe-lens started as a personal experiment: **what happens when you use AI to reverse-engineer how your own brain learns?**

I sat down with Claude and deliberately tried to learn a complex topic — attention mechanisms in neural networks. But the real goal wasn't understanding attention. It was watching *how my mind processed* the explanation, in real time, and having Claude observe and document the patterns.

What we discovered:

- **I don't reach for equations — I reach for metaphors.** When learning how Query/Key/Value works in transformers, I spontaneously generated analogies: spheres reflecting light onto each other, chemical reactions with temperature and state. These weren't decorations — they were my primary reasoning substrate.

- **I reason top-down, not bottom-up.** My mind asks "why does this exist?" before "how does it work?" Purpose first, constraints second, mechanism last.

- **I learn in spirals.** Constrained prototype → generalize → formalize → refine. I don't need complete understanding to start.

- **I have an overthinking trap.** When a correct answer comes fast, I spiral searching for hidden complexity that isn't there. The IS NOT field in constraint boxes was designed specifically to short-circuit this.

These were patterns observed during actual learning exercises, documented in real time. Once we had the cognitive profile, the next question was obvious: can we turn this into a reusable format?

The learning profile became the SKILL.md. The explanation sequence (Problem → Analogy → Code) became the Gabe Block. The overthinking trap mitigation became the constraint box. The one-liners I remembered days later became the one-line handles.

</details>

## License

MIT
