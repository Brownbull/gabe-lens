---
id: pattern-tool-use-loop
name: "Pattern D: Tool-Use Loop (Autonomous Investigation)"
tier: advanced
specialization: [agent]
tags: [pattern, tool-use, investigation, autonomous]
prerequisites: [structured-output-enforcement, context-engineering-basics]
related: [pattern-state-machine, progressive-knowledge-disclosure]
one_liner: "Give the agent tools and a stopping condition — let it decide what to look at."
---

## Analogy

A detective given a case file and full access to records. They don't follow a script — they read, hypothesize, pull more records, revise, and stop when they have enough evidence. The system prompt is the case assignment; tools are the records room; the stopping condition is "solved or budget exhausted."

## When it applies

- Investigation/research agents where the right next step depends on what was just learned
- Deep-analysis tasks where a fixed pipeline would over-investigate cheap cases and under-investigate complex ones
- Codebase exploration, incident forensics, research synthesis
- When adaptability beats predictability

## When it doesn't

- Production request-response with latency SLO <30s (loops can take minutes)
- Cost-sensitive paths (each loop iteration is a model call)
- Tasks with known-good fixed pipelines (don't re-earn adaptability you don't need)
- When you cannot write a tight stopping condition (infinite loop risk)

## Primary force

Some tasks genuinely require "decide what to look at next based on what you just saw." Pipelines can't do that — they're fixed. A tool-use loop lets the model drive investigation but requires you to define bounded tool surfaces, strict stopping conditions, and iteration budgets. Without those three, you have an open wallet and a cliff.

## Common mistakes

- No hard iteration cap → infinite loops on edge cases
- Tools that return unbounded data (the context blows up on iteration 3)
- No evidence-budget check ("enough evidence?" is the key stop signal — make it explicit)
- Letting the model invent its own tools instead of constraining to a vetted set

## Evidence a topic touches this

- Keywords: tool use, tool loop, ReAct, agent iterations, max_iter, evidence budget
- Files: `**/tool_loop*`, `**/agent/*.py`, `**/react_agent*`
- Commit verbs: "add tool loop", "iterate until", "bound iterations", "evidence check"

## Deeper reading

- `refrepos/docs/arch-ref-lib/docs/agent-engineering/006-level-5-autonomous-investigation.md`
- `refrepos/docs/arch-ref-lib/docs/agent-engineering/001-architecture-taxonomy.md` (Pattern D)
