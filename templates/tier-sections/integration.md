# Section: Integration

**Trigger tag:** `external-api`

**Purpose:** External service interaction posture. Applies to phases that call 3rd-party APIs (payment, email, SMS, LLM providers, partner integrations, webhooks).

## Dimensions (4)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Retry/backoff        | none                 | L      | exp backoff 3x       | S      | + jitter + budget   |
| Idempotency          | none                 | XL     | request ID           | M      | + dedupe store      |
| Rate-limit           | hope                 | L      | 429 handler          | M      | + token bucket      |
| Timeout              | default              | M      | explicit + fail      | S      | + budget propagate  |

## Notes

- **Retry/backoff:** MVP = single attempt, fail on first network blip. Enterprise = exponential backoff with 3 retries. Scale = + jitter (thundering-herd avoidance) + retry budget (stop after total time cap).
- **Idempotency:** XL skip MVP→Ent. Without request ID, a retry duplicates side effects (double-charge, double-email, double-entry). Enterprise = client-generated request ID passed to provider. Scale = server-side dedupe store to catch cross-request-ID dupes.
- **Rate-limit:** MVP = no 429 handling, crash on throttle. Enterprise = catch 429, respect `Retry-After`. Scale = client-side token bucket matching provider's published budget.
- **Timeout:** MVP = default (often infinite or very long). Enterprise = explicit timeout per call, fail fast. Scale = budget propagation (caller's remaining budget passed to callee).

## Tier-cap enforcement

- **MVP phase:** `tenacity` / `retry` decorators, `X-Idempotency-Key` headers, `Retry-After` handling all trigger escalation prompt.
- **Enterprise phase:** token-bucket rate limiter, budget-propagating timeout wrapper trigger Scale escalation.

## Known drift signals

| Pattern                                       | Tier floor | Finding severity  |
|-----------------------------------------------|------------|-------------------|
| `@retry` / `@tenacity.retry` / `backoff.on_exception` | Enterprise | TIER_DRIFT-MED |
| `X-Idempotency-Key` / `Idempotency-Key` header| Enterprise | TIER_DRIFT-MED    |
| Dedupe store (Redis SET NX, PG unique index)  | Scale      | TIER_DRIFT-HIGH   |
| Token bucket / leaky bucket limiter           | Scale      | TIER_DRIFT-MED    |
| Context-propagating timeout (asyncio.timeout + deadline passing) | Scale | TIER_DRIFT-MED |

## Red-line items

- **Idempotency on side-effectful calls.** Any phase whose external call mutates state (payment, send-email, create-user) MUST declare idempotency at Enterprise minimum even if phase is MVP-tiered. `/gabe-plan` should BLOCK and prompt escalation: "This phase calls a mutating external API — idempotency is load-bearing. Skip MVP tier on Idempotency row."
- **Retry without idempotency = bug factory.** If retry is enabled (Enterprise+) and idempotency is at MVP (`none`), escalate: retries amplify every duplicate-side-effect problem.
