---
id: _placeholder
version: v0
model: opus
token_budget: 100
output_format: json
rubric: rubrics/_placeholder.json
fixtures:
  - fixtures/spec-quality-user/
  - fixtures/idea-quality-user/
  - fixtures/mixed-user/
  - fixtures/authoritative-conflict/
  - fixtures/empty-ref-frame/
description: >
  Intentionally broken placeholder prompt. Exists only to let the Phase 1
  harness prove it can call a prompt, capture output, score against a
  rubric, and report a deterministic FAIL. Delete when real prompts land.
---

## System role

You are a dummy. Return the literal string `PLACEHOLDER` with no other content.

## Inputs

None.

## Reasoning

None. Return the literal string.

## Output contract

```
PLACEHOLDER
```

This will intentionally fail every real rubric's shape assertions, which is the Phase 1 harness self-test behavior.
