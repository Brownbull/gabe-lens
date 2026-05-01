# P8 — silent-fallback-changes-bigO

## Evidence source

BoletApp `docs/sprint-artifacts/epic-14c-retro-2026-01-20.md` §3. When delta sync broke, the fallback was `refetchOnMount: true`. This turned O(delta) into O(all transactions × navigations). Cost projection: 500 tx/user × 5 groups × ~10 navigations × 2 sessions/day = **50,000 reads per user per day**. 100 users = 5M reads/day = $3/day. 1000 users = **$30/day = $900/month**. The cost explosion was discovered *after* shipping.

## Red-line questions

- When a bug-fix commit flips a query / cache option to a more-eager setting (`refetchOnMount: true`, `staleTime: 0`, shorter polling interval), was the big-O change measured?
- Is there a cost-per-user dashboard or rate-limit that would catch a cost-shape change before it hits production?
- Does the PR checklist require a back-of-envelope cost estimate for any caching-layer change?

## Detection — doc pass

- `.kdbp/DECISIONS.md`: ADR on caching cost budget (reads/user/day, writes/user/day, $ ceiling).
- `.kdbp/BEHAVIOR.md`: rate-limit declarations.
- Cost-monitoring dashboard referenced in docs?

## Detection — code pass

- Grep `refetchOnMount:\s*true|refetchInterval:\s*\d+|staleTime:\s*0` — any of these are fallback-smell candidates.
- Grep `useQuery.*{[\s\S]*refetchOnWindowFocus:\s*true` without corresponding explicit cost comment.
- Grep polling loops: `setInterval|setTimeout.*fetch` with short intervals (< 10s).
- Firestore-specific: `onSnapshot` on large collections without `.where()` or `.limit()` filters.
- SQL-side: `SELECT \* FROM .* (no WHERE, no LIMIT)` in hot paths.

## Detection — commit pass

- `/refetch|refetch on mount/i` in commit subject
- `/fix refresh|fix sync|fix stale/i` combined with cache-option diff
- `/workaround|band.?aid|for now/i` in same commit that flips refetch / stale / interval options
- Author comment in diff: `// TODO measure cost` / `// temporary` next to a refetch flag

## Tier impact

- MVP: surfaces if ANY quota-metered backend is used (Firestore, Supabase, paid LLM, paid API).
- Enterprise: CRITICAL for any fallback flag set in a bug-fix commit without cost justification.
- Scale: plus: cost-budget dashboard required before any caching change merges.

## Severity default

CRITICAL when paired with a quota-metered backend. HIGH otherwise.

## ADR stub template

**Decision:** No caching-layer fallback flag (`refetchOnMount`, `staleTime`, polling interval) is changed without a back-of-envelope cost estimate in the PR description: reads/user/day × users × $/read → projected daily cost delta.
**Rationale:** BoletApp Epic 14c §3. A `refetchOnMount: true` band-aid projected $30/day at 1K users; the cost model would have caught it at PR time.
**Alternatives considered:**
1. Accept blunt-instrument fallback, track cost post-hoc — rejected; discoverable only after damage.
2. Feature-flag gate + canary rollout — valid for large changes, overkill for single-flag flips.

## Open Question template

**Question:** What is this project's cost model per feature (reads/writes/calls per user per day, $/user/month ceiling)? Who reviews cache-layer changes for cost impact?

## Rule template

**Rule:** Any change to query / cache eagerness (`refetchOnMount`, `staleTime`, polling, `onSnapshot` scope) requires a `# cost:` comment in the PR description with reads/writes × users × cost-per-op and projected daily/monthly delta. CI fails if the keyword is missing in a diff that touches these flags.
**Detection:** CI script: `git diff | grep -E "refetchOnMount|staleTime|refetchInterval"` && PR body requires `# cost:` section.
