---
id: input-validation-at-boundary
name: Input Validation at the Boundary
tier: foundational
specialization: [security, web]
tags: [validation, boundary, owasp, fail-fast]
prerequisites: []
related: [input-guardrails, secrets-via-env-never-code]
one_liner: "Trust internal code, validate external input — never the reverse."
---

## Analogy

Customs at a border: rigorous inspection at the line, but you don't re-check passports inside the country. The border is the boundary; what passes it is trusted by definition, which is why the boundary check has to be real.

## When it applies

- Every HTTP endpoint accepting client input
- Any data crossing from untrusted sources (APIs, files, user uploads, environment)
- Parsing JSON, XML, YAML — any deserialization of external data
- Configuration loaded from files or env vars at startup

## When it doesn't

- Internal function calls between your own modules (trust boundaries already crossed)
- Data from your own DB that was validated when inserted
- Pure computational code with no external inputs

## Primary force

Every value that enters the system from outside is untrusted until proven otherwise. Validating at the boundary (schema parse, type check, range check, length cap, regex match) lets every downstream module trust its inputs — the alternative is every function defensively re-checking, which is both noisy and incomplete. Fail fast at the door; trust everything inside. Pydantic, zod, JSON Schema, and typed DTOs exist for exactly this reason.

## Common mistakes

- Validating in the handler AND in the service layer AND in the repository (duplicated logic that drifts)
- Only validating required fields (missing range/length/regex checks lets nonsense through)
- Using regex for structure instead of a schema (brittle)
- Treating validated-once-elsewhere data as still-untrusted (defensive paranoia erodes clarity)
- Custom validation logic instead of battle-tested libraries

## Evidence a topic touches this

- Keywords: validation, Pydantic, zod, schema, input validation, sanitize, validator
- Files: `**/schemas/*`, `**/validators/*`, `**/api/*.py`, `**/models/*`
- Commit verbs: "add validation", "validate input", "reject invalid", "use schema"

## Deeper reading

- OWASP ASVS: Input Validation (V5)
- Pydantic v2 docs
- "Parse, don't validate" (Alexis King) — the functional framing
