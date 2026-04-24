# P7 — multi-op-state-staleness

## Evidence source

BoletApp `docs/sprint-artifacts/epic-14c-retro-2026-01-20.md` §2. First sync worked. Second operation failed. Pattern: works → fails → works → fails. `prevMemberUpdatesRef` (tracking "what I already processed") wasn't updating correctly after handling the first event. Subsequent changes were not detected (ref held old state) OR detected-but-ignored (React Query staleTime) OR lost due to listener issues. Single-operation tests gave false confidence; multi-op tests never existed.

## Red-line questions

- For every stateful effect using `useRef` / `useState` / module-level mutable state: does the update happen on EVERY path — or is there a conditional that can skip it?
- Is there an integration test that exercises the feature with N ≥ 3 sequential operations and asserts final state matches expected?
- Does cache invalidation (React Query / SWR / Apollo) fire on each operation — or only on the first?

## Detection — doc pass

- `.kdbp/DECISIONS.md`: ADR on caching strategy (staleTime, keepPreviousData, invalidation policy).
- `.kdbp/BEHAVIOR.md`: any constraint requiring N-op test coverage?
- Grep for "stale" / "staleTime" / "cacheTime" in docs.

## Detection — code pass

- Pattern: `useRef<... Record<string, ...>>({})` updated inside a `useEffect` whose body has a conditional early-return:
  ```ts
  useEffect(() => {
    if (shouldSkip) return;
    // ... mutation logic
    prevRef.current = newValue;  // ← may never run
  }, [...]);
  ```
- Grep `staleTime:\s*\w+|refetchOnWindowFocus:\s*false` without corresponding explicit invalidation calls.
- Look for `useEffect` with missing dependency arrays around mutable ref updates.
- React Query: `useQuery` without `queryClient.invalidateQueries` on the matching mutation.

## Detection — commit pass

- `/works.*then fails|works the first time/i`
- `/second operation|second time/i`
- `/intermittent|flaky/i` combined with sync / cache keywords
- `/prev.*ref|prevRef/i` with fix context
- `/stale.*cache|cache.*stale/i`

## Tier impact

- MVP: surfaces if the app has any stateful sync / real-time / cache layer.
- Enterprise: CRITICAL if no N-op integration test exists for sync code.
- Scale: plus: N-op test enforced via CI fixture.

## Severity default

HIGH (lower than P6 only because this is often subtle and not always load-bearing at MVP).

## ADR stub template

**Decision:** All stateful sync / cache / ref code is covered by an integration test that runs ≥ 3 sequential operations and asserts final state. Refs mutated inside effects MUST update on every exit path (no conditional skip without explicit `prevRef.current = prevRef.current` reaffirmation or an else branch).
**Rationale:** BoletApp Epic 14c §2 — single-op tests gave false confidence; second-operation failures shipped to users. Multi-op tests are the minimum contract.
**Alternatives considered:**
1. Manual QA for multi-op scenarios — rejected; humans forget to run the third operation.
2. Replace ref with state / store — sometimes applicable; add as sub-ADR if chosen.

## Open Question template

**Question:** Which sync / cache / ref code paths have multi-operation integration tests? Where does `prevXRef` get updated, and on which code paths?

## Rule template

**Rule:** Any `useRef` holding mutable state that survives re-renders is covered by an integration test exercising ≥3 sequential operations. Refs updated inside conditional effects MUST have an else-branch reaffirmation OR an explicit TODO with a dated review.
**Detection:** eslint-plugin-react-hooks with custom rule for ref-mutation-in-conditional; test-file scan asserting `describe` blocks run N-op sequences for sync code paths.
