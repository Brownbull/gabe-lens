# Architecture

Deeper technical docs — design requirements, data contracts, diagram conventions, and the recommended application stack.

Primary workflow doc lives one level up at [../WORKFLOW.md](../WORKFLOW.md). Read that first.

## Contents

| Doc | Purpose |
|-----|---------|
| [requirements.md](requirements.md) | Design invariants (R1–R12) + non-goals |
| [diagram-standards.md](diagram-standards.md) | Mermaid conventions for suite docs (thin layer on top of `skills/gabe-docs/SKILL.md`) |
| [scope-data-contracts.md](scope-data-contracts.md) | Field-by-field contract between `/gabe-scope` (producer) and everything else (consumers) |
| [stack.md](stack.md) | Recommended application stack (FastAPI + Bun + PydanticAI + Claude) for projects built with the suite |
