# Gabe Suite — Docs

Start here.

## Primary reads

| Doc | For |
|-----|-----|
| [WORKFLOW.md](WORKFLOW.md) | the state machine + command flow — read this first |
| [GAPS.md](GAPS.md) | where the workflow has holes + options to close each |

## Deeper reference

| Doc | For |
|-----|-----|
| [architecture/requirements.md](architecture/requirements.md) | design invariants + non-goals |
| [architecture/diagram-standards.md](architecture/diagram-standards.md) | Mermaid conventions for suite docs |
| [architecture/scope-data-contracts.md](architecture/scope-data-contracts.md) | field-level contract for `/gabe-scope` outputs |
| [architecture/stack.md](architecture/stack.md) | recommended application stack for downstream projects |

## Archive

[archive/](archive/) — retired design + dogfood docs. See [archive/README.md](archive/README.md) for why each is archived.

## Runtime specs

Command and skill specs live outside `docs/` (they are runtime artifacts, not documentation):

- `commands/gabe-*.md` — one file per command
- `skills/gabe-*/SKILL.md` — one dir per skill
- `templates/` — files copied into `.kdbp/` at init
- `prompts/` — `/gabe-scope` prompt library
- `schemas/` — JSON schemas for scope artifacts
