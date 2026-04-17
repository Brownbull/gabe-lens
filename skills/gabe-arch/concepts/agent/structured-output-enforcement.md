---
id: structured-output-enforcement
name: Structured Output Enforcement
tier: foundational
specialization: [agent]
tags: [pydantic, schema, output-type, reliability]
prerequisites: []
related: [deterministic-fallback-chain, input-guardrails]
one_liner: "Never trust prompt instructions to produce valid JSON — enforce at the framework layer."
---

## Analogy

Telling a person "please write your address in all caps" works until it doesn't. Asking them to fill out a form with labeled boxes works every time. Framework-level enforcement is the form; prompt instructions are the polite request.

## When it applies

- Any production LLM output consumed by downstream code (not just displayed)
- API responses that must be parseable (you can't show raw LLM text to a JSON-consuming client)
- Classification, extraction, routing — tasks where the shape matters more than the prose

## When it doesn't

- Pure free-text output for human consumption (a summary, an email draft)
- Exploratory prompts during development where you want to see what the model does naturally
- Tiny prototypes where the cost of introducing a schema library outweighs the win

## Primary force

LLM outputs drift. The same prompt produces valid JSON 99% of the time and a trailing comment 1% of the time, and that 1% is production at 2 AM. Framework-level enforcement (PydanticAI `output_type`, Claude `tool_choice`, OpenAI JSON mode) makes the shape a hard constraint, not a hopeful suggestion — invalid output becomes a caught exception, not a silent downstream crash.

## Common mistakes

- Asking for JSON in the system prompt and trusting it — the model is helpful, not compliant
- Writing a custom regex to validate LLM output instead of using a typed schema
- Using structured output AND adding "please respond in JSON" to the prompt — pick one
- No fallback when the schema fails to parse — see `deterministic-fallback-chain`

## Evidence a topic touches this

- Keywords: output_type, PydanticAI, JSON mode, tool_choice, structured output, schema
- Files: `**/agents/*.py`, `**/schemas/*.py`, `**/output_models.py`
- Commit verbs: "enforce schema", "add PydanticAI", "structure output", "use tool_choice"

## Deeper reading

- `refrepos/docs/arch-ref-lib/docs/agent-engineering/003-level-2-structured-agent.md`
- User value U4 (Enforce Output Structure Mechanically)
- PydanticAI `output_type` docs
