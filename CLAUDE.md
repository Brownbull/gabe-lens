# Gabe Suite — Project Context

Development suite for Claude Code. A growing collection of skills, commands, and hooks that transform how you understand, review, decide, and ship. One of the skills inside this suite is called `/gabe-lens` (cognitive translation) — do **not** confuse the suite name (Gabe Suite) with that skill name (Gabe Lens).

**Repos:**
- Brownbull: https://github.com/Brownbull/gabe-suite
- khujta:    https://github.com/khujta/gabe-suite

**Local folder:** `gabe_lens/` (legacy name; rename deferred — safe to rename to `gabe-suite/` later).

## Project Structure

```
gabe-suite/                   # current local folder: gabe_lens/ (rename deferred)
  skills/
    gabe-lens/                # cognitive translation skill (name stays)
      SKILL.md                — Cognitive translation (Gabe Blocks)
      SUITS.md                — 4 cognitive suit definitions for calibration
    gabe-roast/               — Adversarial gap review
    gabe-align/               — Pre-flight alignment check + VALUES.md
    gabe-assess/              — Change impact assessment
    gabe-review/              — Code review with risk pricing
    gabe-health/              — Codebase health analysis
    gabe-help/                — Context-aware guide
    gabe-docs/                — Documentation standards + diagrams library
    gabe-arch/                — Architecture curriculum layer
  commands/
    gabe-lens.md              — /gabe-lens command (the skill's command — name stays)
    gabe-lens-calibrate.md    — /gabe-lens-calibrate command
    gabe-roast.md, gabe-align.md, gabe-assess.md, gabe-review.md
    gabe-health.md, gabe-help.md
    gabe-init.md              — Project setup
    gabe-commit.md            — Commit quality gate
    gabe-push.md              — Push + PR + CI + promote
    gabe-plan.md              — KDBP planning with per-phase tier decision
    gabe-execute.md           — Phase execution
    gabe-next.md              — Zero-logic router
    gabe-teach.md             — Human knowledge consolidation
    gabe-scope.md + gabe-scope-{change,addition,pivot}.md
  templates/
    *.md, *.yaml, *.json      — .kdbp/ init files (SCOPE, ROADMAP, PLAN, etc.)
    tier-sections/*.md        — 14 tier trade-off section files + rubric + index
  prompts/*.md                — /gabe-scope prompt library
  schemas/*.json              — JSON Schemas for scope-session + scope-references
  assets/                     — Images for README
  docs/                       — User docs (start at docs/WORKFLOW.md)
    README.md                 — Doc index
    WORKFLOW.md               — State machine + command flow (primary)
    GAPS.md                   — Remaining workflow gaps + options
    architecture/             — Requirements, diagram standards, data contracts, stack ref
    archive/                  — Retired dogfood + historical design docs
  README.md                   — Public-facing documentation
  CLAUDE.md                   — This file
  install.sh                  — Install suite to ~/.claude/
```

## User Profile

`~/.claude/gabe-lens-profile.md` — stores user's chosen cognitive suit for the `/gabe-lens` skill. Created by `/gabe-lens-calibrate`. Default suit (Spatial-Analogical) used if absent. File name kept as-is — it's a skill-level artifact, not a suite-level one.

## Conventions

- Each skill has its own directory under `skills/` with a `SKILL.md`
- Each skill has a matching command file under `commands/`
- Command files are lean — they reference the SKILL.md for rules, not duplicate them
- Skills are independent but may reference each other (gabe-roast uses gabe-lens one-liner format)

## Current Skills

| Skill | Version | Purpose |
|---|---|---|
| **gabe-lens** | 2.1.0 | Cognitive translation — analogies, maps, constraint boxes, handles. Adapts to cognitive suit. |
| **gabe-roast** | 1.0.0 | Adversarial gap review from a required perspective, classified by maturity + importance |
| **gabe-align** | 1.0.0 | Pre-flight alignment check against curated values. Three modes: shadow, standard, deep |
| **gabe-assess** | 1.0.0 | Rapid change impact assessment. Blast radius, maturity scope, prerequisites, alternatives |
| **gabe-review** | 1.4.x | Code review — risk pricing, confidence scoring, tier drift, triage, deferred items |
| **gabe-health** | 1.0.0 | Codebase health — god files, churn hotspots, coupling, deferred items |
| **gabe-help** | 1.0.0 | Context-aware guide — detects project state, suggests the right tool |
| **gabe-docs** | 1.0.0 | Documentation standards + Mermaid diagrams library |

## Commands

| Command | Skill/owner | Purpose |
|---|---|---|
| `/gabe-lens` | gabe-lens | Explain a concept (full, brief, oneliner, annotate) |
| `/gabe-lens-calibrate` | gabe-lens | Discover your cognitive suit (interactive, one-time) |
| `/gabe-roast` | gabe-roast | Adversarial gap review (full, brief) |
| `/gabe-align` | gabe-align | Pre-flight alignment check (shallow, standard, deep) |
| `/gabe-assess` | gabe-assess | Change impact assessment (full, brief, inline, batch) |
| `/gabe-review` | gabe-review | Code review with risk pricing + tier drift |
| `/gabe-health` | gabe-health | Codebase health analysis |
| `/gabe-help` | gabe-help | Context-aware guide |
| `/gabe-init` | — | Project setup — .kdbp/, hooks, project type, maturity |
| `/gabe-commit` | — | Commit quality gate — deterministic checks, interactive triage |
| `/gabe-push` | — | Push, create PR, watch CI, branch promotion |
| `/gabe-plan` | — | KDBP planning + per-phase tier decision (MVP/Enterprise/Scale) |
| `/gabe-execute` | — | Phase execution with tier cap + escalation gate |
| `/gabe-next` | — | Zero-logic router |
| `/gabe-teach` | — | Human knowledge consolidation |
| `/gabe-scope`, `/gabe-scope-{change,addition,pivot}` | — | Scope authoring + evolution |

## Adding a New Skill

1. Create `skills/<skill-name>/SKILL.md` with frontmatter (name, description, version)
2. Create `commands/<skill-name>.md` with frontmatter (name, description)
3. Add to the Skills table in README.md
4. Update this CLAUDE.md
