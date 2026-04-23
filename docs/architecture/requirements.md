# Gabe Suite — Design Requirements

**Scope.** Design invariants and requirements the suite exists to satisfy. Not a feature list.
**Audience.** Contributors deciding whether a proposed change belongs in the suite.

---

## What the suite is for

A project-memory + execution-quality layer for Claude Code, aimed at solo and small-team development where:

- Code volume per session exceeds what a human can review line-by-line.
- Decisions need to survive past the Claude session window.
- Values, scope, and plan must stay coherent across commits.

The suite is **opinionated** — it enforces a specific workflow (plan → execute → review → commit → push) and a specific state shape (`.kdbp/`). It is not a general-purpose framework.

---

## Requirements

### R1 — Project memory survives sessions

`.kdbp/` files must be the authoritative record of project identity, scope, plan, values, knowledge, and decisions. Commands may write scratch state elsewhere only if it is regenerable.

### R2 — Every artifact has exactly one owner command

Each `.kdbp/*.md` file is written by one command family (e.g., SCOPE.md by `/gabe-scope-*` only). Commands never cross-write. Exceptions audited explicitly (e.g., `PLAN.md` column ticks by multiple commands, each owning one column).

### R3 — Deterministic over LLM wherever possible

Commands that can be deterministic (`/gabe-next`, CHECK 1–9 in `/gabe-commit`, `/gabe-plan check` analysis) must be. LLM usage explicitly marked in spec frontmatter + opt-in.

### R4 — No silent state changes

Every state mutation writes to `LEDGER.md` or `CHANGES.jsonl`. `/gabe-commit` surfaces the audit trail; `/gabe-push` records deployment events. No command mutates state without logging.

### R5 — User values outrank model defaults

`.kdbp/VALUES.md` (project) + `~/.kdbp/VALUES.md` (user) override model priors. Any command making a judgment call checks values first. `/gabe-align` audits regularly.

### R6 — Quality gates are the default path

Raw `git commit` is an anti-pattern. `/gabe-commit` runs CHECK 1–9 + deferred scan + doc drift + Notable Updates digest. Bypass requires explicit flag + audit event.

### R7 — Serial single-plan

One active plan at a time. Phases run in order. No parallel lanes. (Revisit only if maturity graduates to enterprise + team size demands + measurable pain exceeds serial cost — see [GAPS.md](../GAPS.md) W5.)

### R8 — Every command is resumable

Commands that span multiple steps write partial state. If interrupted, re-invocation picks up from the last checkpoint (see `/gabe-scope --resume`, `/gabe-execute` checkpoint cadence).

### R9 — Commands have no implicit ordering

Side-channel commands (`/gabe-align`, `/gabe-assess`, `/gabe-roast`, `/gabe-health`, `/gabe-teach`, `/gabe-help`, `/gabe-lens`) can run any time. Only the phase-flow commands have ordering (enforced by `/gabe-next` dispatch logic).

### R10 — Docs written by the suite follow its own standards

[skills/gabe-docs/SKILL.md](../../skills/gabe-docs/SKILL.md) is the doc standard. Both suite-generated project docs AND suite-internal docs (this file included) must conform.

### R11 — Cognitive accessibility

`/gabe-lens` exists because humans don't all think the same way. Technical docs and code explanations adapt to the user's cognitive suit (`~/.claude/gabe-lens-profile.md`). The suite's own docs default to spatial-analogical framing but remain legible to all suits.

### R12 — Small composable commands

Each command does one thing. `/gabe-commit` commits. `/gabe-push` pushes. `/gabe-next` routes. No omnibus commands. Cross-cutting concerns (values, knowledge, health) live in side-channel skills, not shoved into core flow commands.

---

## Non-goals

**What the suite explicitly does not try to do.**

- **N1 — Vendor neutrality.** Suite is Claude Code specific. Not designed for other agent runtimes.
- **N2 — Full CI/CD replacement.** `/gabe-push` wraps push + PR + CI watch. Does not replace deployment pipelines.
- **N3 — Generalized project templating.** `/gabe-init` seeds KDBP, not project scaffolding. Use Cookiecutter or equivalent for scaffolding.
- **N4 — Multi-repo monorepo coordination.** One project per `.kdbp/`. Monorepo with cross-package plans not in scope.
- **N5 — Parallelism.** See R7.
- **N6 — Team workflow.** Optimized for solo + small team. Multi-developer concurrent editing on the same plan is not a target.
- **N7 — Retroactive retrofit on non-KDBP projects.** `/gabe-init` on a project without priors is the path. Drift-detection and incremental migration off-scope.

---

## What triggers a requirements revision

- **New command family added.** Ensure each R still holds.
- **Core invariant changes.** (E.g., if R7 is revisited for parallelism, this doc updates + WORKFLOW.md reflects new shape.)
- **Non-goal becomes target.** Move N to R, write supporting design doc.

Revisions update this file in place. Prior versions recoverable via git history.

---

## Related

- **[../WORKFLOW.md](../WORKFLOW.md)** — how requirements manifest as concrete state machine + commands
- **[../GAPS.md](../GAPS.md)** — where requirements are satisfied partially or not at all
- **[stack.md](stack.md)** — application stack the suite recommends downstream
- **[scope-data-contracts.md](scope-data-contracts.md)** — field-level contracts for SCOPE/ROADMAP
