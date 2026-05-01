# Archive

Retired docs. Kept for historical context, not maintained against current behavior.

If a concept described here still applies, look for it in the current docs:

| If you came here looking for... | Read instead |
|---------------------------------|--------------|
| How `/gabe-scope` works today | `commands/gabe-scope.md` spec + [../WORKFLOW.md](../WORKFLOW.md) |
| Scope data contract | [../architecture/scope-data-contracts.md](../architecture/scope-data-contracts.md) |
| Dogfood regression | none — suite doesn't ship a regression harness for `/gabe-scope` currently; `tests/scope-prompt-harness/` is the live harness |
| The dangling classifier / LEDGER hook fix | fix landed; behavior lives in `commands/gabe-push.md` Step 7.5b + post-commit hook |

## Archived files

| File | Archived | Why |
|------|----------|-----|
| `gabe-scope-design.md` | 2026-04-23 | Design spec v0.3 written pre-implementation. Behavior now lives in `commands/gabe-scope.md`. Design rationale preserved here. |
| `gabe-scope-implementation-plan.md` | 2026-04-23 | Implementation plan. The plan executed. No longer live. |
| `gabe-scope-v1-dogfood.md` | 2026-04-23 | Regression checklist for `/gabe-scope` v1 ship. V1 shipped. Checklist is historical. |
| `upstream-fixes-dangling-classifier-ledger-hook.md` | 2026-04-23 | Fix record for two specific bugs. Both fixes landed. |

## Archive policy

- **Before shipping a new feature:** write the design spec in an ephemeral location (`.planning/`, an issue, a branch-scoped doc). Don't write it into `docs/`.
- **After shipping:** if the design rationale is worth preserving, move it here with an entry in the table above. Otherwise delete.
- **Never revive an archived doc.** If its content is still relevant, extract into a current doc (`docs/WORKFLOW.md`, `docs/architecture/*`) and re-link.
