---
id: pattern-state-machine
name: "Pattern C: LangGraph State Machine"
tier: advanced
specialization: [agent]
tags: [pattern, state-machine, checkpoint, human-in-loop]
prerequisites: [pattern-single-agent-pipeline, deterministic-fallback-chain]
related: [pattern-tool-use-loop, agent-observability]
one_liner: "Nodes + edges + checkpoints — for agents that must survive restarts and pause for humans."
---

## Analogy

A manufacturing line with inspection checkpoints: the product stops at each station, gets stamped, and the line can resume from the last stamp if the power goes out. Compare to Pattern A (one worker) — here every station is a named node with persisted state.

## When it applies

- Long-running multi-stage agent tasks (>60s end-to-end)
- Workflows that must survive process restarts (checkpoint/recovery is load-bearing)
- Human-in-the-loop approvals at specific stages
- Auditable pipelines where "which node produced which intermediate" is a required question
- Enterprise systems with compliance/traceability requirements

## When it doesn't

- MVP agent apps (Pattern A is 10x faster to ship)
- High-throughput, low-latency paths (state machine overhead is real)
- Teams without LangGraph (or equivalent) expertise on the team
- Tasks that don't naturally decompose into stable named stages

## Primary force

Complex multi-stage agents fail in the middle — after the expensive step, before the final one. Without checkpointing, a failure forces a full re-run at full cost. A state machine with persisted transitions lets the system resume from the last good state, pause for human approval at specific nodes, and produce a complete audit trail of what happened where.

## Common mistakes

- Reaching for LangGraph before you need it — if you don't know why you want checkpoints, you don't yet
- 30-node graphs where 5 would do — more nodes = more debugging surface, not more correctness
- Persisting state in memory only (defeats the point)
- No human-approval pattern even though the framework supports it — you're paying the complexity tax without collecting the benefit

## Evidence a topic touches this

- Keywords: LangGraph, state machine, StateGraph, checkpoint, node, edge, human-in-loop
- Files: `**/graph*`, `**/nodes/*`, `**/langgraph*`
- Commit verbs: "add node", "wire edge", "add checkpoint", "pause for human"

## Deeper reading

- `refrepos/docs/arch-ref-lib/docs/agent-engineering/001-architecture-taxonomy.md` (Pattern C)
- `refrepos/docs/arch-ref-lib/docs/agent-engineering/005-level-4-production-pipeline.md`
