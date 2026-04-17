---
id: token-budget-caps
name: Token Budget Caps (Per-Request Limits)
tier: foundational
specialization: [cost]
tags: [budget, max-tokens, cost-control, circuit-breaker]
prerequisites: []
related: [model-routing-by-task, circuit-breaker]
one_liner: "Every LLM call gets a max_tokens cap — no exceptions, no 'but this one's special'."
---

## Analogy

A taxi meter with a hard limit: the driver stops at $50 no matter where you are. You might walk the last block, but you don't come home to a $400 fare. Max-tokens is the meter; the cap is the fixed limit.

## When it applies

- Every production LLM call (no exceptions)
- Streaming responses (cap the total, not just per-chunk)
- Open-ended generation tasks (summaries, drafts) where the model could ramble
- Multi-turn loops where unbounded output compounds into unbounded cost

## When it doesn't

- Trusted batch jobs where you've measured the output distribution and know the 99p (still cap — just cap at 99p + 10%)
- Never — even dev prototypes benefit from caps to prevent runaway loops while iterating

## Primary force

Without a cap, one misbehaving prompt can generate 16K tokens and cost 10x the expected per-call budget. The cap is the last line of defense against runaway cost — cheaper than a circuit breaker, cheaper than a rate limit, cheaper than noticing the bill a week later. It also forces the model to be concise, which usually improves output quality.

## Common mistakes

- Omitting max_tokens and hoping the model is reasonable (it sometimes isn't)
- Setting max_tokens to the model's maximum (defeats the cap)
- Same cap for every task — a classification needs 20 tokens, a report needs 1000
- Caps in config but unread — verify the cap is actually applied in the request

## Evidence a topic touches this

- Keywords: max_tokens, token budget, cap, output limit, truncate
- Files: `**/llm_client*`, `**/config/*.yaml`, `**/agents/*.py`
- Commit verbs: "add max_tokens", "cap output", "limit generation", "set budget"

## Deeper reading

- Provider docs (Anthropic, OpenAI): max_tokens semantics per model
- User value U8 (Measure the Machine — caps are the enforceable companion to measurement)
