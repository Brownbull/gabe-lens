# Section: Compute

**Trigger tag:** `perf-sensitive`

**Purpose:** Server-side performance posture. Applies to phases touching hot-path computation, heavy transforms, or performance-sensitive code.

## Dimensions (4)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Caching              | none                 | M      | memoize hot path     | M      | + tiered + invalid. |
| Batching             | one-at-a-time        | L      | batch window         | M      | + dyn batch size    |
| Pooling              | new per-use          | M      | fixed pool           | S      | + adaptive sizing   |
| Benchmark budget     | none                 | M      | baseline test        | M      | + regression gate   |

## Notes

- **Caching:** MVP = recompute every time. Enterprise = memoize hot path (LRU cache, `@functools.cache`). Scale = tiered cache (in-memory L1 + shared L2) with explicit invalidation protocol.
- **Batching:** MVP = process one item at a time (N round-trips). Enterprise = fixed-size batch window. Scale = dynamic batch size based on backpressure.
- **Pooling:** MVP = new connection/worker/client per request. Enterprise = fixed-size pool. Scale = adaptive pool sizing based on load signals.
- **Benchmark budget:** MVP = no perf gate. Enterprise = baseline benchmark captured once. Scale = CI-gated regression test (>10% slowdown fails build).

## Tier-cap enforcement

- **MVP phase:** LRU cache decorators on non-trivial functions, connection pool registration, batch-window assemblers trigger escalation.
- **Enterprise phase:** adaptive pool controllers, regression benchmark harness trigger Scale escalation.

## Known drift signals

| Pattern                                            | Tier floor | Finding severity |
|----------------------------------------------------|------------|------------------|
| `@functools.lru_cache` / `@cache` on hot path      | Enterprise | TIER_DRIFT-LOW   |
| Tiered cache (Redis + local dict)                  | Scale      | TIER_DRIFT-MED   |
| Explicit cache invalidation protocol (tag-based, pub-sub) | Scale | TIER_DRIFT-MED    |
| `asyncio.Queue` / batch-window accumulator         | Enterprise | TIER_DRIFT-MED   |
| Adaptive batch controller (size based on queue depth) | Scale   | TIER_DRIFT-MED   |
| Connection pool (`asyncpg.create_pool`, `httpx.AsyncClient` with limits) | Enterprise | TIER_DRIFT-LOW |
| `pytest-benchmark` / regression perf gate in CI    | Scale      | TIER_DRIFT-MED   |

## Red-line items

- **Premature optimization trap.** This section is the most common source of YAGNI violations. If a phase has NO measured perf problem and no production traffic justifying the concern, default to MVP across all 4 dimensions. Escalate only when evidence exists (profile, load test, complaint). Tier-cap enforcement exists precisely to prevent engineers from Scale-tier-ing a cold path.
