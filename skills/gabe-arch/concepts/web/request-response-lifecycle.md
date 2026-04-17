---
id: request-response-lifecycle
name: Request / Response Lifecycle
tier: foundational
specialization: [web]
tags: [http, lifecycle, middleware, request-phases]
prerequisites: []
related: [stateful-vs-stateless-services, input-validation-at-boundary]
one_liner: "Every HTTP request passes through the same phases — know them or debug blind."
---

## Analogy

An airport security line: boarding pass check → ID verification → bag scan → walkthrough → gate agent. Each step can reject you; if all pass, you board. Debugging requests without knowing the stages is like trying to find your lost bag without knowing which conveyor carried it.

## When it applies

- Any HTTP-based service (virtually every web app)
- Debugging "why did this request behave like that" — stage-by-stage tracing is the answer
- Adding cross-cutting concerns (auth, logging, rate-limit, compression) — they attach to specific phases
- Framework onboarding — understanding where your code runs in the lifecycle

## When it doesn't

- Non-HTTP protocols (gRPC, WebSockets, raw TCP have different models)
- Pure function code with no network surface

## Primary force

Requests don't hit your handler directly. They pass through (typical order): connection accept → TLS handshake → HTTP parse → routing → middleware stack (request direction) → handler → middleware stack (response direction) → response serialization → connection close. Each phase has failure modes, timing characteristics, and observability surfaces. Knowing which phase a problem lives in is the difference between a 10-minute fix and a 4-hour search.

## Common mistakes

- Adding authentication in the handler instead of middleware (runs after parsing; misses early rejection)
- Logging request bodies after deserialization (misses malformed requests that failed to parse)
- Setting response headers after writing the body (no-op; headers must come first)
- Expecting middleware to run both directions when it's written for one
- Forgetting timeouts — long-running handlers tie up connection slots

## Evidence a topic touches this

- Keywords: middleware, lifecycle, request phase, router, handler, before_request, after_request
- Files: `**/middleware*`, `**/app.py`, `**/main.py`, `**/api/*.py`
- Commit verbs: "add middleware", "wire router", "before request hook", "intercept at"

## Deeper reading

- Framework-specific: FastAPI docs (Dependencies + Middleware), Express docs (Middleware)
- "High Performance Browser Networking" (Grigorik) ch. 9-11
