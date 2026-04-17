---
id: prompt-caching
name: Prompt Caching (Stable-Prefix Reuse)
tier: intermediate
specialization: [cost, agent]
tags: [caching, prompt-cache, cost-optimization, ttl]
prerequisites: [context-engineering-basics]
related: [progressive-knowledge-disclosure, model-routing-by-task]
one_liner: "Pay once for the stable prefix; reuse it on every call within TTL."
---

## Analogy

A coffee shop that pre-grinds beans once per hour instead of per cup. The grind is the same for every order, so grinding per-cup is waste. Prompt caching is the same idea: the system prompt doesn't change every turn, so pay to process it once and reuse.

## When it applies

- System prompts or instructions shared across many requests
- RAG contexts where the same document subset recurs within a session
- Multi-turn conversations where early turns stay stable
- High-volume systems where even 50% cache savings is material

## When it doesn't

- Prompts that change every request (no reusable prefix)
- Low-volume systems where cache warmup never pays back
- Anthropic's specific 5-minute TTL doesn't fit your traffic pattern (slow-burn apps)
- When prefix stability would force bad abstractions (don't contort design to hit the cache)

## Primary force

Most tokens in a typical agent call are context setup (system prompt, tool definitions, retrieved docs) that doesn't change turn-to-turn. Prompt caching lets the provider process that prefix once and bill subsequent calls at ~10% cost for the cached portion. In a chatty agent, that's often 50-80% cost reduction with zero architectural change beyond ordering the prompt correctly (stable content first, variable content last).

## Common mistakes

- Putting variable content in the middle of the prompt (defeats the cache)
- Not measuring cache hit rate — you don't know if you're actually saving
- TTL-ignorance — Anthropic's 5-minute window means bursty traffic caches well, slow-drip doesn't
- Caching tiny prefixes where the cache-miss penalty exceeds the cache-hit win

## Evidence a topic touches this

- Keywords: prompt cache, cache_control, stable prefix, cache hit rate, ephemeral cache
- Files: `**/prompt_builder*`, `**/llm_client*`, `**/cache*`
- Commit verbs: "enable cache", "add cache_control", "stabilize prefix", "order prompt for cache"

## Deeper reading

- Anthropic prompt-caching docs (5-minute TTL specifics)
- `/mnt/g/My Drive/Claude-Cowork/khujta_memory/_system/research/anthropic/claude-sdk-architect/`
