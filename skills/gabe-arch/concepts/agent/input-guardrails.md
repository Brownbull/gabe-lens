---
id: input-guardrails
name: Input Guardrails (Pre-Agent Validation)
tier: foundational
specialization: [agent, security]
tags: [guardrails, prompt-injection, validation, safety]
prerequisites: []
related: [input-validation-at-boundary, structured-output-enforcement]
one_liner: "Filter adversarial input before it reaches the model — cheaper than filtering output."
---

## Analogy

A bouncer at the door checking IDs — refusing anyone carrying obvious weapons before they enter the club. Much easier than letting everyone in and trying to catch trouble after drinks are poured.

## When it applies

- Any agent taking untrusted user input (public APIs, support ticket systems, chat)
- Prompt-injection attack surfaces — text that could hijack instructions
- Preventing the model from even seeing known-bad patterns (cheaper than model-side detection)
- Logging which attack patterns hit your system (observability has teeth only with names)

## When it doesn't

- Fully trusted input pipelines (internal batch jobs with sanitized data)
- As the only defense — guardrails complement model-side safety, don't replace it
- For content moderation of model output (that's post-hoc, different problem)

## Primary force

Prompt injection attacks exploit the model's helpfulness. A regex that blocks "ignore previous instructions" before the model sees it is 1000x cheaper than a model call, 100% deterministic, and produces named evidence of attack patterns for your ops dashboard. The goal is not perfect filtering — it's removing the obvious 80% so the model's remaining defenses handle the 20%.

## Common mistakes

- Returning only `{safe: bool}` — lose observability (can't answer "which patterns trend?")
- Treating guardrails as a complete security solution (they're layer 1 of many)
- Matching patterns case-sensitively (attackers use mixed case, unicode)
- Not versioning the pattern set — you need to know when a new pattern was added

## Evidence a topic touches this

- Keywords: guardrail, prompt injection, input validation, regex pattern, jailbreak, matched_patterns
- Files: `**/guardrails.py`, `**/patterns*`, `**/agent/pre_validate*`
- Commit verbs: "add guardrail", "block pattern", "detect injection", "expand patterns"

## Deeper reading

- `refrepos/docs/arch-ref-lib/docs/agent-engineering/003-level-2-structured-agent.md`
- OWASP LLM Top 10 (LLM01: Prompt Injection)
