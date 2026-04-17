---
id: retry-with-exponential-backoff
name: Retry with Exponential Backoff
tier: intermediate
specialization: [distributed-reliability]
tags: [retries, backoff, jitter, transient-failure]
prerequisites: [idempotency-keys]
related: [circuit-breaker, deterministic-fallback-chain]
one_liner: "Wait longer between each retry so the failing system can recover."
---

## Analogy

A polite guest who knocks once, waits longer after each no-answer, and eventually leaves a note — instead of pounding the door forever and making the situation worse.

## When it applies

- Transient failures: network blips, rate limits, 503s, temporary overload
- Downstream systems with known recovery times (seconds, not hours)
- Idempotent operations (so retries are safe)
- Any HTTP client talking to a remote service with occasional flakiness

## When it doesn't

- Permanent failures (4xx that aren't 429 or 408) — retry is pointless
- Non-idempotent operations without an idempotency key (double-charge risk)
- Synchronous user-facing paths with <1s latency budget
- When the caller has no ability to tolerate the retry's added latency

## Primary force

Retries without backoff amplify outages. Every caller hammering a failing service keeps it failing — it's a denial-of-service attack your own clients are executing against you. Exponential backoff with jitter lets the target breathe, so the system self-heals instead of thrashing. The 1s/2s/4s schedule is the classic; jitter (random ±25%) prevents thundering herds on recovery.

## Common mistakes

- Fixed-delay retries (retry storm the moment the service comes back)
- No jitter (thundering herd on recovery spike)
- Unbounded retries (infinite spend on permanent failures)
- Retrying non-idempotent writes (double-charge, duplicate records)
- Retrying 4xx errors that aren't rate limits (you're just making noise)

## Evidence a topic touches this

- Keywords: retry, backoff, tenacity, exponential, jitter, urllib3.Retry, httpx retries
- Files: `**/http_client*`, `**/retry_policy*`, `**/transport*`
- Commit verbs: "add retry", "handle 429", "backoff on", "wrap in tenacity"

## Deeper reading

- AWS Architecture Blog: "Exponential Backoff and Jitter"
- tenacity Python library docs
- Google SRE Book: Handling Overload
