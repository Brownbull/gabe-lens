# Rubric Format Spec

Rubrics are JSON files that describe PASS/FAIL assertions against LLM (Large Language Model) output. The harness runs every assertion in order and reports PASS only if all pass.

## File naming

```
rubrics/{prompt-id}.json
```

Where `{prompt-id}` matches the prompt's `id:` frontmatter field.

## Schema

```json
{
  "rubric_id": "intake-quality-evaluator",
  "prompt_version": "v1",
  "output_format": "json",
  "assertions": [
    {
      "type": "output_is_json",
      "description": "Response must parse as valid JSON"
    },
    {
      "type": "field_exists",
      "path": ".quality",
      "description": "Response must have a top-level 'quality' field"
    },
    {
      "type": "field_in_set",
      "path": ".quality",
      "values": ["spec", "idea"],
      "description": "'quality' must be 'spec' or 'idea'"
    },
    {
      "type": "max_chars",
      "limit": 2000,
      "description": "Response must fit token budget (2000 chars ≈ 500 tokens)"
    }
  ]
}
```

### Top-level fields

| Field | Required | Purpose |
|---|---|---|
| `rubric_id` | yes | Must match prompt's `id:` frontmatter |
| `prompt_version` | yes | Rubric written against this prompt version; bump when prompt bumps |
| `output_format` | yes | `json` or `plain`; must match prompt's `output_format:` |
| `assertions` | yes | Array of assertion objects, evaluated in order |

## Assertion types (Phase 1)

### `output_is_json`

Passes if the response parses as valid JSON.

```json
{ "type": "output_is_json", "description": "..." }
```

### `field_exists`

Passes if `path` (jq syntax) resolves to a non-null value in the JSON response. Fails if response isn't JSON.

```json
{ "type": "field_exists", "path": ".quality", "description": "..." }
```

### `field_in_set`

Passes if the value at `path` is in the declared `values` set.

```json
{ "type": "field_in_set", "path": ".quality", "values": ["spec", "idea"], "description": "..." }
```

### `contains_phrase`

Passes if the raw response contains the given substring (case-sensitive).

```json
{ "type": "contains_phrase", "phrase": "Primary User", "description": "..." }
```

### `absent_phrase`

Passes if the raw response does NOT contain the given substring. Useful for catching hallucinations or forbidden tokens like `[PENDING APPROVAL]` leaking into finalized output.

```json
{ "type": "absent_phrase", "phrase": "[PENDING APPROVAL]", "description": "..." }
```

### `max_chars`

Passes if response character length <= limit. Proxy for token budget (rule of thumb: ~4 chars per token).

```json
{ "type": "max_chars", "limit": 2000, "description": "Fits token budget" }
```

### `min_chars`

Passes if response character length >= limit. Catches empty or truncated responses.

```json
{ "type": "min_chars", "limit": 50, "description": "Not empty/truncated" }
```

## Worked example — the `_placeholder` rubric

The Phase 1 placeholder prompt returns the literal string `PLACEHOLDER`. This rubric expects JSON output — so every assertion fails, proving the harness correctly reports failures.

See [_placeholder.json](_placeholder.json).

## Authoring guidelines

- **Assert shape, not exact text.** LLMs vary run-to-run; rubrics that pin exact strings will flake.
- **One assertion per concern.** Don't combine checks; failure detail is more useful with isolated assertions.
- **Include a `max_chars` assertion** on every rubric; token budget enforcement is critical per design §8 IR3.
- **Describe assertions in plain English.** The `description` field is what shows up in `-v` (verbose) output and is the first thing a human reads when debugging.
- **Negative fixtures test failure paths.** Write at least one fixture per prompt that SHOULD fail its rubric (e.g., malformed input). Verifies scoring logic isn't passing everything by accident.

## Future extensions (deferred beyond Phase 1)

- `regex_match` — pattern assertion
- `field_length` — assert array or string length at a path
- `llm_judge` — use a second LLM call to judge semantic quality (reserved for when shape assertions aren't enough)
- `diff_ratio` — fuzzy match against a reference with tolerance
