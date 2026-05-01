# Application Architecture — Stack Reference

The settled stack for building AI agent applications. Derived from the AgentX hackathon post-mortem and 11 finalist analysis (April 2026).

This document captures the settled stack; the original decision log lives outside this repo (AgentX post-mortem). For the folder conventions that back this stack, see `templates/STRUCTURE.md` — that's the bundled, per-project-applicable artifact.

---

## The Stack

### Backend

| Component | Choice |
|-----------|--------|
| Language | Python 3.12 |
| Framework | FastAPI (async, auto-docs, Pydantic integration) |
| Agent Framework | PydanticAI (structured output via `output_type`, provider-agnostic) |
| ORM | SQLAlchemy 2.0 async + Alembic migrations |
| Database | PostgreSQL (pgvector for embeddings when needed) |
| Cache/Pub-Sub | Redis |
| Task Queue | FastAPI BackgroundTasks (MVP) → Celery (Scale) |

### Frontend

| Component | Choice |
|-----------|--------|
| Framework | React 19 + TypeScript |
| Runtime & PM | Bun (runtime + package manager + test runner) |
| Build | Vite (via `bun run dev`) |
| Styling | Tailwind CSS + shadcn/ui |
| State | Zustand (client) + TanStack Query (server) |
| Real-time | SSE (MVP) → WebSocket (Scale) |
| Tests | `bun test` + happy-dom (unit), `Bun.WebView` (E2E) |

### Agent Layer

| Component | Choice |
|-----------|--------|
| Structured Output | PydanticAI `output_type` (never prompt-based JSON) |
| Classification Model | Gemini Flash (cheap, $0.075/M) |
| Reasoning Model | Claude Sonnet (tool use, deep analysis) |
| Safety Model | Mistral Moderation (free, 11 categories) |
| Fallback Chain | PydanticAI retry → regex extract → rule-based → safe default |
| Tool Safety | Read-only, scoped to directory, max 10-20 iterations |

### Observability

| Component | Choice |
|-----------|--------|
| LLM Tracing | Langfuse Cloud (free tier) |
| App Tracing | OpenTelemetry → Jaeger (dev) or cloud (prod) |
| Metrics | Prometheus `/metrics` endpoint |
| Logging | structlog (JSON, trace ID correlation) |

### Deployment

| Context | Choice |
|---------|--------|
| Target | Web apps only (browser). No desktop, no mobile. |
| Development | Docker Compose (max 4 containers: app + db + redis + jaeger) |
| Frontend Docker | `oven/bun:slim` build stage → nginx:alpine serving |
| Production | Docker → cloud (Railway, Fly.io, or VPS) |

---

## Agent Application Checklist

Every agent app needs these 9 stages (from arch-ref-lib Tier 9):

```
1. INTAKE      → Validate input, assign ID, return 202 Accepted
2. GUARDRAILS  → Pre-compiled regex (15+ patterns), boundary markers, fail-closed
3. CLASSIFY    → Cheap model (Gemini Flash) for severity/category
4. AGENT       → Premium model (Claude Sonnet) with tools + output_type
5. OUTPUT      → Schema-enforced response, fallback chain
6. DISPATCH    → Real integration (Linear/Slack/email)
7. STREAM      → SSE progress events for any processing >5 seconds
8. STATE       → PostgreSQL + Redis
9. OBSERVE     → Langfuse traces + Prometheus metrics + cost per run
```

## Architecture Patterns

| Pattern | When to Use | Latency | Cost/op |
|---------|------------|---------|---------|
| **A: Single Agent + Pipeline** | MVP, predictable flows | 5-15s | $0.01-0.05 |
| **B: Multi-Model Staged** | Cost optimization at scale | 10-30s | $0.005-0.01 |
| **C: LangGraph State Machine** | Audit trails, checkpoint/recovery | 15-60s | $0.02-0.05 |
| **D: Tool-Use Loop** | Research, autonomous investigation | 30-180s | $0.02-0.10 |

Start with Pattern A. Add B (cost routing) or D (autonomous investigation) as needed.

## Maturity Progression

| Concern | MVP | Enterprise | Scale |
|---------|-----|------------|-------|
| Agent | Single model, rule-based fallback | Multi-model routing, full fallback chain | RAG + temporal memory + evals |
| Integrations | Real free tiers + mock fallback | Circuit breakers + retry with backoff | Multi-provider failover |
| Streaming | SSE with stage names | SSE + replay buffer + error boundaries | WebSocket + client cancellation |
| Observability | Langfuse + structlog | + OTEL spans + Prometheus | + Grafana + anomaly detection |
| Security | 15 regex patterns + read-only tools | + moderation model + HMAC | + red-team evals + audit logging |
| Testing | 80% coverage + 1 E2E flow | + agent pipeline integration tests | + eval-driven + load testing |
| Docker | 2-3 containers | 4-5 + health checks | Kubernetes + auto-scale |

## Reference Repos

See `refrepos/arch-ref-lib/docs/architecure-reference-library.md` Tier 9 for cloneable reference implementations.

See `refrepos/arch-ref-lib/docs/agent-learning-path.md` for Level 1-3 skill progression.
