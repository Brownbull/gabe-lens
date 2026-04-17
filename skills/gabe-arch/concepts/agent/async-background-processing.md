---
id: async-background-processing
name: Async Background Processing (202 Accepted)
tier: foundational
specialization: [agent, web]
tags: [async, 202-accepted, background-task, sse]
prerequisites: []
related: [sse-streaming-progress, request-response-lifecycle]
one_liner: "Return a ticket immediately; process in the background; stream progress separately."
---

## Analogy

A coat-check counter: you hand over your jacket and walk away with a ticket. The attendant hangs it up at their own pace. You come back (or get paged) when it's ready. Nobody stands at the counter waiting for a jacket to be processed.

## When it applies

- LLM calls >3 seconds (which is most of them)
- File uploads that trigger multi-step processing
- Any request where the user shouldn't be staring at a spinner
- API endpoints where holding the connection costs more than storing state

## When it doesn't

- Sub-second operations (no point adding complexity)
- Strict request-response protocols where the caller expects the result on the same connection
- Tightly-coupled transactions that must commit or rollback as one unit

## Primary force

A synchronous LLM call blocks a server thread for 10+ seconds. At any real scale, that means either huge thread pools (expensive) or timeouts (user-hostile). 202 Accepted + background processing decouples the client's wait from the server's work — the connection closes in milliseconds, the work proceeds at its natural pace, and progress is streamed back via SSE or polled via a status endpoint.

## Common mistakes

- No idempotency key on the submit endpoint — retries double-process
- Storing the ticket ID only in memory (server restart loses the job)
- Returning 200 instead of 202 (muddies the "accepted but not done" semantics)
- Background task with no timeout — jobs accumulate indefinitely on failure

## Evidence a topic touches this

- Keywords: 202 Accepted, BackgroundTask, background processing, ticket ID, async job
- Files: `**/api/*.py`, `**/tasks/*`, `**/workers/*`
- Commit verbs: "return 202", "add BackgroundTask", "async submit", "enqueue"

## Deeper reading

- `refrepos/docs/arch-ref-lib/docs/agent-engineering/005-level-4-production-pipeline.md`
- FastAPI `BackgroundTasks` docs
