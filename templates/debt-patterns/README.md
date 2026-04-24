# Debt Pattern Catalog

Data-driven catalog consumed by `/gabe-debt` (see `skills/gabe-debt/SKILL.md`). Each `P<n>-*.md` file is a self-contained pattern definition. Patterns are evidence-anchored to real failures in Gastify (`docs/rebuild/LESSONS.md` R1–R13) and BoletApp (`docs/sprint-artifacts/epic-14c-retro-2026-01-20.md`). Not generic invention.

## File format

Every pattern file has the following sections. `gabe-debt` parses them deterministically — keep headings stable.

```markdown
# P<n> — <pattern handle>

## Evidence source
<Retro / LESSONS file reference that seeds this pattern.>

## Red-line questions
Yes/no decisions that MUST be resolved. If any answer is "no / unknown / implicit," the pattern fires.
- ...

## Detection — doc pass
Structured inputs (.kdbp/* files) to read and what to look for.
- ...

## Detection — code pass
Grep / AST heuristics to run on the codebase.
- ...

## Detection — commit pass
Commit message markers that indicate the pattern was stepped-around instead of resolved.
- ...

## Tier impact
- MVP: <behavior at MVP tier — surfaces or suppresses>
- Enterprise: <behavior>
- Scale: <behavior>

## Severity default
CRITICAL | HIGH | MEDIUM

## ADR stub template
<Pre-written Decision / Rationale / Alternatives to seed DECISIONS.md when user promotes to `d`.>

## Open Question template
<Pre-written question to seed SCOPE.md §14 when user promotes to `o`.>

## Rule template
<Pre-written R-entry body to seed RULES.md when user promotes to `r`.>
```

## Adding a custom pattern

Drop a new file at `.kdbp/debt-patterns/<id>-<handle>.md` in your project. Project-local patterns override globally-shipped ones by ID.

## Current catalog (v1)

| ID | Handle | Source |
|---|---|---|
| P1 | dual-state-machines | Gastify LESSONS §1.1 / R1 |
| P2 | cross-feature-direct-mutation | Gastify LESSONS §1.2 / R2 |
| P3 | async-listener-race | Gastify LESSONS §2 Seam A / R5 |
| P4 | schema-drift-across-boundaries | Gastify LESSONS §2 Seam C / R4,R6 |
| P5 | god-class-growth | Gastify LESSONS §1.3 / R3 |
| P6 | deletion-detection-in-sync | BoletApp epic-14c-retro §1 |
| P7 | multi-op-state-staleness | BoletApp epic-14c-retro §2 |
| P8 | silent-fallback-changes-bigO | BoletApp epic-14c-retro §3 |
| P9 | cross-product-infra-coupling | BoletApp CLAUDE.md INC-001 |
| P10 | cost-model-absent-before-deploy | BoletApp epic-14c-retro §3 |
| P11 | multi-op-test-gap | BoletApp epic-14c-retro §2 |
