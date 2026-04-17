---
id: agent-observability
name: Agent Observability (Traces + Metrics)
tier: intermediate
specialization: [agent, distributed-reliability]
tags: [observability, langfuse, prometheus, tracing, metrics]
prerequisites: [input-guardrails]
related: [sse-streaming-progress, token-budget-caps]
one_liner: "If you can't see what the agent did, you can't improve it — trace every call, name every metric."
---

## Analogy

A dashcam in a car. You don't watch the footage daily, but the one time something crashes, you need to know exactly what was in front of you two seconds earlier. Traces are the footage; metrics are the odometer.

## When it applies

- Any production agent system (user value U8 — mandatory)
- Debugging cost regressions (which model, which prompt, which token?)
- Regulated industries that require auditability
- Teams with >1 engineer (shared understanding of what the agent actually does)

## When it doesn't

- One-off scripts, hackathon prototypes (the cost of instrumentation exceeds the investigation win)
- When instrumenting would leak PII into third-party services — solve privacy first
- Tiny internal tools with zero production traffic

## Primary force

Agents fail in ways no other software fails: the same prompt produces different outputs, costs drift over time, model versions change behavior silently. Named traces (Langfuse, LangSmith) and structured metrics (Prometheus: cost-per-run, latency-p95, token-usage) let you see those failures instead of guessing. Boolean success/failure is not enough; you need the full run recorded and per-pipeline-run metrics to answer "what changed since last week?"

## Common mistakes

- Logging text but not structured spans — searchable traces beat grep-able logs
- Measuring latency but not cost (or vice versa) — they're the two axes that matter
- No per-stage breakdown — you see total latency but not where it's spent
- Sending traces synchronously — a slow trace store becomes your new SLO

## Evidence a topic touches this

- Keywords: Langfuse, LangSmith, Prometheus, OpenTelemetry, trace, span, metric, cost_per_run
- Files: `**/observability*`, `**/tracing*`, `**/metrics*`
- Commit verbs: "add Langfuse", "emit metric", "wrap span", "trace run"

## Deeper reading

- `refrepos/docs/arch-ref-lib/docs/agent-engineering/005-level-4-production-pipeline.md`
- User value U8 (Measure the Machine)
- Langfuse / LangSmith / OpenTelemetry docs
