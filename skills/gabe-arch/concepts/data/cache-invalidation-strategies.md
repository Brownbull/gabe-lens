---
id: cache-invalidation-strategies
name: Cache Invalidation Strategies
tier: advanced
specialization: [data]
tags: [cache, invalidation, ttl, write-through, write-behind]
prerequisites: []
related: [prompt-caching, request-response-lifecycle]
one_liner: "Cache invalidation is hard — pick the right wrongness rather than chasing correctness."
---

## Analogy

A bulletin board with announcements. Tear old ones off immediately when news changes? (expensive, real-time). Replace daily? (stale for a day, cheap). Mark "expires 5pm"? (bounded staleness). Each trade-off suits different kinds of news.

## When it applies

- Any system with a cache layer (Redis, Memcached, CDN, HTTP cache, LLM response cache)
- High-read workloads where cache hit rate dominates cost/latency
- Read-heavy views over write-heavy data
- Distributed systems where cache coherence across nodes matters

## When it doesn't

- Systems with no meaningful read repetition (cache doesn't help)
- Strict consistency requirements where any staleness is unacceptable (skip cache, accept latency)
- Tiny scale where the DB handles full load unassisted

## Primary force

There is no free invalidation strategy — each trades staleness, cost, or complexity. **TTL:** simple, bounded staleness, but cache can be stale up to TTL. **Write-through:** write updates cache + DB atomically; correct but slow writes. **Write-behind:** writes go to cache, flush to DB async; fast but risk of loss. **Event-driven invalidation:** pub/sub invalidates on write events; correct but requires infrastructure. Pick based on which wrongness you can tolerate: stale reads, slow writes, or operational complexity.

## Common mistakes

- Default TTL of "forever" (cache never invalidates; new data never appears)
- No cache warming (cold cache after deploy = latency spike)
- Cache stampede: many callers simultaneously miss, all hit DB at once
- Inconsistent keys (the same logical query produces different cache keys, killing hit rate)
- Caching based on request instead of response (you cache empty-results unnecessarily)

## Evidence a topic touches this

- Keywords: cache, invalidate, TTL, write-through, write-behind, cache-aside, stampede
- Files: `**/cache*`, `**/redis*`, `**/memcached*`
- Commit verbs: "invalidate cache", "set TTL", "warm cache", "cache-aside"

## Deeper reading

- "Designing Data-Intensive Applications" (Kleppmann) ch. 3
- AWS ElastiCache caching strategies documentation
- "There are only two hard things..." — Phil Karlton's classic quote
