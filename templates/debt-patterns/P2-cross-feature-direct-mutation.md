# P2 — cross-feature-direct-mutation

## Evidence source

Gastify `docs/rebuild/LESSONS.md` §1.2 → rule R2. BoletApp `processScan.ts` directly called `transactionEditorActions.setTransaction(...)` — scan feature reached across to editor's internal API. When editor re-rendered before the store flush completed, stale props rendered.

## Red-line questions

- Does each feature module expose an event API (emit / subscribe) rather than action imports?
- When feature A needs to push a result to feature B, does it publish an event — or does it import B's action creator?
- Are there CI / lint rules preventing cross-feature imports of `*Actions` / `*Store`?

## Detection — doc pass

- `.kdbp/DECISIONS.md`: look for ADR declaring inter-feature communication protocol (event bus / command queue / pub-sub).
- `STRUCTURE.md` (if present): check if feature directories are declared as independent modules with defined public surfaces.
- Absence of an event-bus declaration in a multi-feature app = implicit temporal-coupling acceptance.

## Detection — code pass

- Grep `import .* from .*/features/<A>/.*/actions` inside files under `features/<B>/`.
- Grep direct store imports across feature boundaries: `import .*Store from .*features/.*/store`.
- dep-cruiser / nx-enforce / eslint-plugin-boundaries rules present? If not, no guardrail exists.
- Common smell: `features/<A>/handlers/*.ts` calling `features/<B>/actions/*.ts` (cross-feature handler → action).

## Detection — commit pass

- `/tight.*coupling|coupling.*tight/i`
- `/wire (scan|editor|feed) to /i`
- `/connect features/i`
- `/direct call to /i`
- `/import.*from .*features\//i` in the commit diff itself (script-grep)

## Tier impact

- MVP: surfaces for any confirmed cross-feature action import that caused a rendered-stale-props or handler-race bug.
- Enterprise: surfaces for any cross-feature action import, bug or not.
- Scale: requires architectural event-bus or command layer; any direct import is CRITICAL.

## Severity default

HIGH.

## ADR stub template

**Decision:** Features communicate via events, not direct imports. Feature A emits `<domainEvent>`; feature B subscribes. Neither imports the other's actions, stores, or internal helpers.
**Rationale:** Temporal coupling (feature A calling feature B's setter, then B re-rendering on stale data) was a top Gastify pain (LESSONS R2). Events give us a seam for ordering, retry, and test isolation.
**Alternatives considered:**
1. Direct imports with docs-only conventions — rejected; conventions erode.
2. Redux-style single store — rejected; couples unrelated features around shared reducer surface.

## Open Question template

**Question:** What is this project's inter-feature communication protocol — event bus, command queue, or direct imports? If direct imports, why, and what prevents drift?

## Rule template

**Rule:** Zero imports from `features/<X>/*` inside `features/<Y>/*` for distinct X, Y. Inter-feature coordination goes through a documented event layer (e.g. `shared/events/`).
**Detection:** dep-cruiser (or eslint-plugin-boundaries) rule enforcing feature isolation. CI fails on violation.
