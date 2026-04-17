---
id: circuit-breaker
name: Circuit Breaker
tier: intermediate
specialization: [distributed-reliability]
tags: [circuit-breaker, failure-isolation, half-open, cascading-failure]
prerequisites: [retry-with-exponential-backoff]
related: [deterministic-fallback-chain, token-budget-caps]
one_liner: "Stop calling a dead downstream — give it time to recover before the next attempt."
---

## Analogy

A home electrical circuit breaker: when current spikes dangerously, it trips and cuts power. You check the wiring before flipping it back on. Without the breaker, the house burns down. Your software equivalent: trip when failures spike, block calls for a cooldown, test recovery with a single "half-open" probe.

## When it applies

- Calls to external services (payment, email, LLM providers) with known failure modes
- Downstream dependencies that, when down, should cause fast fails rather than stalled calls
- Production systems where cascading failure is a real risk
- Any caller that currently retries endlessly against a dead service

## When it doesn't

- In-process calls (overhead > benefit)
- Services where you have no sensible degraded-mode fallback (what do you do when the breaker's open?)
- Tiny systems where the extra state machine isn't worth the complexity
- When the downstream owns its own rate limits and handles overload correctly (rare)

## Primary force

Retrying against a down service makes the outage worse — the service can't recover while being hammered. Circuit breakers track failure rate; when it exceeds a threshold, the breaker "opens" and all calls fail fast (typically routing to a fallback). After a cooldown, the breaker "half-opens" and allows one probe call; success closes it, failure reopens it. This turns a flood of doomed calls into a controlled trickle that actually lets recovery happen.

## Common mistakes

- Threshold too sensitive (breaker trips on transient noise)
- No half-open state (breaker stays open or you manually reset it)
- No fallback when open (you've traded "slow failure" for "instant failure")
- Shared breaker across unrelated operations (one bad endpoint trips all of them)
- No observability on breaker state transitions (you can't debug what you can't see)

## Evidence a topic touches this

- Keywords: circuit breaker, open/closed/half-open, failure threshold, pybreaker, resilience4j
- Files: `**/circuit_breaker*`, `**/resilience*`, `**/clients/*.py`
- Commit verbs: "add circuit breaker", "trip on", "half-open", "fail fast when"

## Deeper reading

- Martin Fowler: "CircuitBreaker" (canonical article)
- Netflix Hystrix docs (deprecated but historically significant)
- pybreaker / resilience4j library docs
