---
id: context-engineering-basics
name: Context Engineering Basics
tier: intermediate
specialization: [agent]
tags: [context, rag, prompt, token-budget]
prerequisites: [structured-output-enforcement]
related: [progressive-knowledge-disclosure, prompt-caching]
one_liner: "Every token in context steals from reasoning — load the minimum, defer the rest."
---

## Analogy

A desk with limited surface area. A surgeon doesn't pile every tool in front of them — they keep only what the current operation needs and swap trays as the procedure advances. The desk is the context window; the trays are retrieval.

## When it applies

- Any agent with non-trivial reference material (docs, past conversations, knowledge base)
- Long-running sessions where naive context accumulation bloats prompts
- Multi-tool agents where tool descriptions alone consume a non-trivial fraction of the budget
- RAG systems, agent-over-codebase apps, documentation assistants

## When it doesn't

- Toy prompts with ≤1KB of context (engineering has overhead that's not worth it)
- One-shot completions where the input is bounded and static
- Cases where accuracy is more valuable than token cost and you've verified the model benefits from more context

## Primary force

LLM reasoning quality degrades as context fills — not linearly, not monotonically, but measurably. The best systems load exactly what the current step needs and defer everything else. Claude Code's own architecture proves this at scale: system prompts are memoized, skill listings load truncated, tool schemas are deferred until requested, memory is side-queried.

## Common mistakes

- Loading the entire codebase/knowledge base "just in case"
- Concatenating chat history forever instead of summarizing or side-querying
- Verbose tool descriptions — every unused word is paid for on every call
- No measurement of tokens consumed per stage (you can't optimize what you don't measure)

## Evidence a topic touches this

- Keywords: context window, token budget, RAG, retrieval, prompt engineering, context compaction
- Files: `**/context*`, `**/rag*`, `**/retrieval*`, `**/prompt_builder*`
- Commit verbs: "trim context", "add retrieval", "compact history", "reduce prompt"

## Deeper reading

- `/mnt/g/My Drive/Claude-Cowork/khujta_memory/_system/research/anthropic/claude-sdk-architect/progressive-knowledge-disclosure.md`
- `refrepos/docs/arch-ref-lib/docs/agent-engineering/004-level-3-context-engineered.md`
