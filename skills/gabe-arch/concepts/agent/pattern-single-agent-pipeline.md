---
id: pattern-single-agent-pipeline
name: "Pattern A: Single Agent + Deterministic Pipeline"
tier: foundational
specialization: [agent]
tags: [pattern, pipeline, deterministic, mvp]
prerequisites: []
related: [pattern-multi-model-pipeline, pattern-tool-use-loop, structured-output-enforcement]
one_liner: "One agent + fixed deterministic stages around it — the boring pattern that wins."
---

## Analogy

An assembly line with one skilled worker in the middle. Conveyor belts do the routine parts (guard, classify, notify); the worker makes the one decision machines can't. Predictable, inspectable, cheap to run.

## When it applies

- Most agent MVPs and production apps with clear input/output
- Incident triage, support routing, content moderation — any task with a fixed flow and one reasoning step
- Teams that need to ship in days, not weeks
- Any scenario where latency matters (5-15s typical)

## When it doesn't

- Agent needs to choose its own investigation path (use Pattern D instead)
- Multi-step reasoning where each step spawns sub-tasks (use Pattern C)
- Cost optimization via model staging is critical (use Pattern B)

## Primary force

Deterministic pipelines fail predictably. When only one stage uses a model, you can reason about, test, and debug the system without tripping over non-determinism at every layer. The #1 finalist across 12 production agent teams used Pattern A — architecture complexity is not maturity.

## Common mistakes

- Reaching for LangGraph before you have one working pipeline
- Making the single agent stage too broad (it becomes a god-function; split into classify + act)
- Skipping guardrails because "it's just one agent" — pre-agent validation is cheaper than post-agent cleanup
- Not streaming progress — 10+ second waits with no UI feedback kill user trust

## Evidence a topic touches this

- Keywords: single agent, deterministic pipeline, triage, classify-then-act, one agent
- Files: `**/pipeline.py`, `**/triage.py`, `**/agent/orchestrator*`
- Commit verbs: "add pipeline", "wire agent", "classify then route"

## Deeper reading

- `refrepos/docs/arch-ref-lib/docs/agent-engineering/001-architecture-taxonomy.md`
- `refrepos/docs/arch-ref-lib/docs/agent-engineering/003-level-2-structured-agent.md`
