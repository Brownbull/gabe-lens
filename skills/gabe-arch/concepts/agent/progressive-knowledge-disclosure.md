---
id: progressive-knowledge-disclosure
name: Progressive Knowledge Disclosure
tier: advanced
specialization: [agent]
tags: [context, lazy-loading, skills, disclosure]
prerequisites: [context-engineering-basics]
related: [prompt-caching]
one_liner: "Announce what exists; load content only when relevance is proven."
---

## Analogy

A library card catalog: you see every book's title + one-line description (cheap), but you only pull the book off the shelf when you decide it's relevant (expensive). The catalog stays in your working memory; the books don't.

## When it applies

- Systems with many available capabilities (skills, tools, docs, past sessions)
- Agent harnesses where the set of things the model could do is far larger than what it will do this turn
- Multi-skill/multi-tool ecosystems (Claude Code, agent frameworks) where upfront loading is unaffordable
- Any system at scale that's hit "token budget exceeded" during normal operation

## When it doesn't

- Small, bounded agents with 3-5 tools (upfront loading is cheaper than indirection)
- Latency-critical paths where the extra "announce then fetch" round-trip matters
- When the user expects everything available to be visible upfront (configuration tools, admin UIs)

## Primary force

Context windows are finite but the universe of capabilities is unbounded. Progressive disclosure (announce names + summaries, fetch bodies on request) scales to thousands of skills/tools without token inflation. Claude Code announces skills by name + truncated description (1% of context budget), defers tool schemas behind ToolSearch, side-queries memory via a sub-agent. Each layer trades a small fixed upfront cost for an unbounded capacity.

## Common mistakes

- Announcing everything eagerly and wondering why the first turn is slow/expensive
- Disclosing so lazily that the model can't find capabilities (under-announcement is as bad as over)
- Not caching the "announced" layer — it should be stable across turns
- Treating announcement and body as the same artifact instead of distinct formats

## Evidence a topic touches this

- Keywords: progressive disclosure, lazy load, deferred, announce, ToolSearch, skill listing
- Files: `**/skills/*`, `**/tool_registry*`, `**/context_loader*`
- Commit verbs: "defer load", "announce then fetch", "lazy resolve", "register skill"

## Deeper reading

- `/mnt/g/My Drive/Claude-Cowork/khujta_memory/_system/research/anthropic/claude-sdk-architect/progressive-knowledge-disclosure.md` (authoritative)
- `/mnt/g/My Drive/Claude-Cowork/khujta_memory/_system/research/anthropic/claude-sdk-architect/skills-deep-dive.md`
