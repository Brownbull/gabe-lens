# P11 — multi-op-test-gap

## Evidence source

BoletApp `docs/sprint-artifacts/epic-14c-retro-2026-01-20.md` §2. Single-operation tests gave false confidence. The "works then fails" pattern (see P7) shipped because every test ran exactly one action before asserting. Multi-op sequences (create → sync → delete → sync → create again) would have caught the `prevMemberUpdatesRef` staleness bug in seconds. This pattern is the preventive counterpart to P7 (the detection side).

## Red-line questions

- For sync / cache / real-time / ref-mutating code, does the test suite exercise ≥ 3 sequential operations per `describe` block before asserting final state?
- Is there a test utility that wraps "run operation × N times" into a single helper so adding N-op coverage is cheap?
- Does CI enforce that any `useRef` mutation in non-trivial effect code has an N-op test present?

## Detection — doc pass

- `.kdbp/DECISIONS.md`: ADR on testing standards (multi-op coverage, N-op utilities).
- Test framework config (`vitest.config`, `jest.config`, `pytest.ini`) — any custom matchers / helpers for multi-op?

## Detection — code pass

- Enumerate test files: `find . -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" -o -name "test_*.py"`.
- For each `it(...)` / `test(...)` block in files touching sync / cache / ref / real-time code, count the number of operation-triggering calls (`.mutate`, `.setState`, `dispatch`, `act`, API calls) before the first `expect`.
- Flag blocks with exactly one op before assert when the code under test manages sync / cache / ref state.
- Look for a dedicated `describe('multi-operation sequence', ...)` or similar naming convention. Absence = missing coverage.

## Detection — commit pass

- `/add test|test coverage/i` for sync code WITHOUT matching `/sequence|multi|N-op/i` keywords.
- `/test passes locally/i` combined with a revert later (likely P7 manifestation).

## Tier impact

- MVP: surfaces if ANY sync / cache / ref code has single-op-only tests and the code path touches multi-user or persistent state.
- Enterprise: CRITICAL absence.
- Scale: plus: fuzzing / property-based N-op sequences.

## Severity default

HIGH.

## ADR stub template

**Decision:** Sync / cache / ref code paths are covered by integration tests exercising ≥3 sequential operations (create, modify, delete, re-create, etc.) before the final assertion. A shared `runOpsSequence([...ops])` test helper lives in `test/utils/` to keep the cost low.
**Rationale:** BoletApp Epic 14c §2. Single-op tests hid the second-operation staleness bug. N-op coverage is the minimum contract for stateful code.
**Alternatives considered:**
1. Manual QA for multi-op — rejected; humans miss the third repetition.
2. Property-based testing — valuable at Scale tier; overkill for MVP.

## Open Question template

**Question:** Which sync / cache / ref code paths lack multi-operation test coverage? Is there a shared `runOpsSequence` helper in this project's test utilities?

## Rule template

**Rule:** Any test describe-block covering sync / cache / ref / real-time code must exercise ≥3 sequential operations before the final assertion. A custom lint or grep-based CI check enforces this on a declared path allowlist.
**Detection:** CI script scanning test files on sync-path allowlist for single-op describe-blocks; fails on mismatch.
