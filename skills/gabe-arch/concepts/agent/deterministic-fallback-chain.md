---
id: deterministic-fallback-chain
name: Deterministic Fallback Chain
tier: intermediate
specialization: [agent, distributed-reliability]
tags: [fallback, reliability, graceful-degradation, output-shape]
prerequisites: [structured-output-enforcement]
related: [retry-with-exponential-backoff, circuit-breaker]
one_liner: "When structured output fails, don't raise — degrade through a chain of cheaper guesses."
---

## Analogy

An ATM that prefers to dispense twenties but falls back to tens, then fives, then prints a receipt telling you where the nearest working ATM is. It never shrugs and locks your card — it has a sequence.

## When it applies

- Agent API that must always return a response shape, even when the model misbehaves
- User-facing flows where "error" is worse than "partial answer"
- Downstream systems that can't handle nulls but can handle a safe default
- Structured-output parsers that occasionally fail to validate

## When it doesn't

- Critical correctness paths (payments, medical) — prefer explicit error over silent degradation
- When the fallback quality is indistinguishable from the primary — you're hiding a bug
- Simple synchronous APIs where raising is the right answer

## Primary force

Production LLM systems fail in many small ways — schema mismatches, timeouts, rate limits, partial JSON. A fallback chain converts a class of scattered failures into a single predictable response shape, which is what every caller actually wants. The chain is deterministic: same input → same fallback step → same output.

## Common mistakes

- Silent fallback with no logging — you never learn the primary is broken
- Fallbacks that are themselves LLM calls with the same fragility (recursive risk)
- No SLO on the depth of fallback used — when fallback-3 becomes the norm, the primary is dead
- Swallowing exceptions instead of classifying them (schema error vs. rate limit vs. timeout have different right fallbacks)

## Evidence a topic touches this

- Keywords: fallback, graceful degradation, default value, fallback chain, on_error
- Files: `**/fallback*`, `**/agents/*.py`, `**/error_handlers.py`
- Commit verbs: "add fallback", "degrade to", "handle parse error", "default when"

## Deeper reading

- `refrepos/docs/arch-ref-lib/docs/agent-engineering/003-level-2-structured-agent.md`
- PydanticAI `output_retries` + custom exception handlers
