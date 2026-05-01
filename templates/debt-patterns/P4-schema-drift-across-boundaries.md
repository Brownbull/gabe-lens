# P4 — schema-drift-across-boundaries

## Evidence source

Gastify `docs/rebuild/LESSONS.md` §2 Seam C → rules R4, R6. BoletApp's Gemini call returned `price` on line items; client + DB expected `totalPrice`. Compat shim (`(i as any).price`) marked `TODO(TD-18-8)`; new data bypassed shim → null `totalPrice` → edit form threw on `undefined`. Also: 44+ Tailwind theme variants hand-synced across files.

## Red-line questions

- Every boundary where data crosses a system (LLM output, external API, client ↔ server, client ↔ DB): is there a machine-enforced schema at the boundary?
- Are shared constants (category lists, theme tokens, API paths) single-sourced with codegen — or hand-synced?
- Does the boundary validator reject unknown fields explicitly?

## Detection — doc pass

- `.kdbp/DECISIONS.md`: ADR on boundary validation (Pydantic `output_type`, Zod, JSON Schema, protobuf).
- `.kdbp/ENTITIES.md`: canonical entity definitions. If fields are also defined in code without derivation, flag drift risk.
- `shared/` or `packages/common/` folder present? If field lists are duplicated in TS and Python without codegen, flag.

## Detection — code pass

- Grep LLM call sites: `generativeModel|gemini|openai|anthropic|claude\.messages` followed by JSON parsing — is there a Pydantic / Zod / `output_type` guard?
- Grep `as any|as unknown as` casts on AI/external-API responses.
- Grep `// TODO|TODO(.*)|FIXME` with keywords `remove after`, `migration`, `cleanup`.
- Look for duplicated enum / const lists: `grep -rn "'Food'\|\"Food\"" src/` and count occurrences — if the same literal list appears >2 places, likely drift candidate.
- Check for codegen markers (`// GENERATED` / `# DO NOT EDIT`) in shared constants.

## Detection — commit pass

- `/field.*drift|drift.*field/i`
- `/shim|compat|compatibility/i`
- `/hand.?sync|manual sync/i`
- `/rename .* field|field .* rename/i`
- `/TD-\d+|TODO\(TD-/`
- `/Gemini|LLM.*response|AI response/` combined with `fix`

## Tier impact

- MVP: surfaces if ANY LLM / external API call site lacks a schema validator.
- Enterprise: plus: all shared constants / enums must be codegen'd or explicitly rationalized.
- Scale: plus: migration scripts in place for planned schema evolutions.

## Severity default

CRITICAL for LLM outputs that write to DB. HIGH for client-server. MEDIUM for internal constant drift.

## ADR stub template

**Decision:** All `<boundary-type>` calls validate payloads via `<schema mechanism>` at the boundary. Unknown fields are rejected (or explicitly logged + defaulted). No downstream `as any` fallbacks.
**Rationale:** Gastify LESSONS R4 + R6. Manual coercion fails silently; parse-time failure surfaces the problem before data corrupts storage.
**Alternatives considered:**
1. TypeScript interfaces only — rejected; compile-time only, useless at runtime.
2. Accept-and-coerce with logging — rejected; lets corrupted data into the DB.

## Open Question template

**Question:** What is this project's boundary-validation mechanism for LLM outputs / external APIs / client-server handoffs? Where are shared constants single-sourced?

## Rule template

**Rule:** Every LLM and external-API call uses a schema-enforced output type (Pydantic `output_type`, Zod `.parse`, JSON-schema validator). Shared constants (categories, tokens, paths) live in ONE source file and are emitted to other languages via codegen. CI diff-check fails on drift.
**Detection:** grep for LLM call sites without schema guards; CI script comparing generated constants against source.
