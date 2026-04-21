# Scope Prompt Test Harness

Prompt-unit test harness for the `/gabe-scope` command family. Runs a prompt against one or more fixture inputs, captures the LLM (Large Language Model) output, and scores it against a declared rubric.

**Phase 1 goal:** Harness machinery exists and can report PASS/FAIL deterministically against a known-broken placeholder prompt.

**Phase 3 goal:** Real prompts land and pass their rubrics against ≥3 fixtures each.

## Layout

```
scope-prompt-harness/
├── README.md              # this file
├── run.sh                 # CLI entrypoint
├── lib/
│   ├── call-llm.sh        # LLM invocation (mock mode + real API)
│   └── score.sh           # rubric scoring
├── fixtures/              # one directory per synthetic scenario
│   └── {scenario-name}/
│       ├── input.json     # variables injected into the prompt at runtime
│       └── mock-response.txt  # canned LLM output (used with --mock)
├── rubrics/               # JSON rubrics, one per prompt type
│   └── README.md          # rubric format spec
└── _out/                  # harness output (gitignored)
    └── {prompt-id}/{fixture-name}/{timestamp}/
        ├── rendered-prompt.txt
        ├── llm-response.txt
        └── score.json
```

## Usage

```bash
# Mock mode (no API call, reads fixture's mock-response.txt)
./run.sh --mock _placeholder spec-quality-user

# Real mode (calls Claude API — requires ANTHROPIC_API_KEY)
./run.sh _placeholder spec-quality-user

# Run all fixtures for a prompt
./run.sh --mock _placeholder --all

# Verbose (prints rubric check details)
./run.sh --mock -v _placeholder spec-quality-user
```

Exit codes:

- `0` — PASS (rubric satisfied)
- `1` — FAIL (rubric violated)
- `2` — harness error (missing file, malformed config, etc.)

## Mock mode vs. real mode

| Mode | When to use | Cost | Determinism |
|---|---|---|---|
| `--mock` | Phase 1 harness self-test; regression re-runs; CI | $0 | Full |
| Real API | Phase 3 prompt authoring; periodic validation | ~$0.01/call (Opus) | Temperature-dependent; rubric assertions must tolerate variance |

Real-mode calls use `temperature=0` where the model supports it. Rubrics that accept minor variance document the tolerance explicitly.

## Writing a fixture

A fixture is a named scenario: a set of inputs the prompt will receive plus (optionally) a canned mock response.

```
fixtures/spec-quality-user/
├── input.json            # what the command would inject at runtime
└── mock-response.txt     # canned LLM output (used with --mock)
```

`input.json` shape depends on the prompt's declared `Inputs` section. Example for `intake-quality-evaluator`:

```json
{
  "question": "In one sentence, what are you building?",
  "answer": "A triage agent that classifies incoming incidents and routes them to the right team based on severity and domain.",
  "prior_answers": []
}
```

## Writing a rubric

Rubrics are JSON files that describe shape + constraint assertions against the LLM output. See [rubrics/README.md](rubrics/README.md) for the format spec.

## Environment variables

- `ANTHROPIC_API_KEY` — required for real-mode calls
- `HARNESS_OUT_DIR` — override `_out/` location (defaults to `./_out`)
- `HARNESS_MODEL_OPUS` — override Opus model ID (default: `claude-opus-4-7`)
- `HARNESS_MODEL_SONNET` — override Sonnet model ID (default: `claude-sonnet-4-6`)

## Phase 1 self-test

Run this to verify the harness works:

```bash
cd /home/khujta/projects/gabe_lens/tests/scope-prompt-harness
./run.sh --mock _placeholder --all
```

Expected result: **all 5 fixtures FAIL** against the `_placeholder` prompt. This proves the harness can:

1. Load a prompt file with frontmatter
2. Load a fixture's `input.json`
3. Read the fixture's `mock-response.txt` (skipping real API)
4. Load the declared rubric
5. Score the response against rubric assertions
6. Report deterministic FAIL with exit code `1`
