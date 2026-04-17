---
id: sse-streaming-progress
name: SSE Streaming for Agent Progress
tier: intermediate
specialization: [agent, web]
tags: [sse, streaming, progress, user-experience]
prerequisites: [async-background-processing]
related: [agent-observability]
one_liner: "Show the model thinking in real time — silence over 5s feels like the thing is broken."
---

## Analogy

Watching a progress bar fill vs. staring at a frozen screen. Same 30-second wait, completely different experience. One feels like work is happening; the other feels like a crash.

## When it applies

- Any AI processing >5 seconds (user value U5 — mandatory)
- Multi-step agent runs where each step has observable progress
- Pipelines where intermediate results are meaningful to the user ("classified as X, now routing...")
- User-facing apps where abandonment rises sharply with perceived latency

## When it doesn't

- Batch jobs with no human waiting
- Sub-second operations (overhead > benefit)
- Clients that can't consume SSE (older browsers, some B2B integrations — use polling)
- When streaming partial results would confuse the user more than help them

## Primary force

Dead air kills user trust. A 30-second LLM pipeline with no progress feedback gets abandoned; the same pipeline streaming "validated input → classifying → routing → responding" finishes just as fast but feels 3x faster. SSE (Server-Sent Events) is the simplest streaming primitive — one-way, HTTP-native, auto-reconnect — and doesn't need WebSockets' complexity for most agent apps.

## Common mistakes

- Streaming raw token-by-token output when users only care about stage transitions
- No heartbeat events (browsers/proxies close idle connections after 30-60s)
- Forgetting to flush the server buffer (events arrive in a burst at the end)
- Mixing error handling with data events — separate `event: error` stream

## Evidence a topic touches this

- Keywords: SSE, Server-Sent Events, streaming, event: progress, EventSource, text/event-stream
- Files: `**/streaming*`, `**/api/*.py`, `**/sse*`
- Commit verbs: "stream progress", "add SSE", "emit event", "flush buffer"

## Deeper reading

- `refrepos/docs/arch-ref-lib/docs/agent-engineering/005-level-4-production-pipeline.md`
- User value U5 (Stream the Thinking)
- MDN Server-Sent Events
