#!/usr/bin/env bash
# run.sh — Scope Prompt Test Harness CLI
#
# Usage:
#   ./run.sh [--mock] [-v|--verbose] <prompt-id> <fixture-name>
#   ./run.sh [--mock] [-v|--verbose] <prompt-id> --all
#
# Examples:
#   ./run.sh --mock _placeholder spec-quality-user
#   ./run.sh --mock _placeholder --all
#   ./run.sh _placeholder spec-quality-user        # real API (requires ANTHROPIC_API_KEY)
#
# Exit codes:
#   0 — PASS (all invoked rubrics satisfied)
#   1 — FAIL (at least one rubric violated)
#   2 — harness error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GABE_LENS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROMPTS_DIR="$GABE_LENS_ROOT/prompts"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
RUBRICS_DIR="$SCRIPT_DIR/rubrics"
OUT_DIR="${HARNESS_OUT_DIR:-$SCRIPT_DIR/_out}"

source "$SCRIPT_DIR/lib/call-llm.sh"
source "$SCRIPT_DIR/lib/score.sh"

MODE="real"
VERBOSE=""
PROMPT_ID=""
FIXTURE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mock) MODE="mock"; shift ;;
    -v|--verbose) VERBOSE="-v"; shift ;;
    -h|--help)
      grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    --all)
      if [[ -z "$PROMPT_ID" ]]; then
        echo "ERROR: --all must come after prompt-id" >&2
        exit 2
      fi
      FIXTURE="--all"
      shift
      ;;
    --) shift; break ;;
    -*)
      echo "ERROR: unknown flag '$1'" >&2
      exit 2
      ;;
    *)
      if [[ -z "$PROMPT_ID" ]]; then
        PROMPT_ID="$1"
      elif [[ -z "$FIXTURE" ]]; then
        FIXTURE="$1"
      else
        echo "ERROR: unexpected positional argument '$1'" >&2
        exit 2
      fi
      shift
      ;;
  esac
done

if [[ -z "$PROMPT_ID" || -z "$FIXTURE" ]]; then
  echo "Usage: $0 [--mock] [-v] <prompt-id> <fixture-name>|--all" >&2
  exit 2
fi

PROMPT_FILE="$PROMPTS_DIR/${PROMPT_ID}.md"
if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "ERROR: prompt not found: $PROMPT_FILE" >&2
  exit 2
fi

# Parse frontmatter: extract model, rubric path, fixtures list.
# Simple awk-based YAML reader (handles our flat schema only).
parse_frontmatter_field() {
  local field="$1"
  awk -v f="$field" '
    BEGIN { in_fm = 0; done = 0 }
    /^---$/ {
      if (in_fm == 0) { in_fm = 1; next }
      else { done = 1; exit }
    }
    in_fm == 1 && done == 0 {
      # Match "field: value"
      if (match($0, "^" f ":[ \t]*")) {
        val = substr($0, RLENGTH+1)
        # Trim trailing whitespace
        gsub(/^[ \t]+|[ \t]+$/, "", val)
        print val
        exit
      }
    }
  ' "$PROMPT_FILE"
}

parse_frontmatter_list() {
  local field="$1"
  awk -v f="$field" '
    BEGIN { in_fm = 0; in_list = 0 }
    /^---$/ {
      if (in_fm == 0) { in_fm = 1; next }
      else { exit }
    }
    in_fm == 1 {
      if (match($0, "^" f ":[ \t]*$")) { in_list = 1; next }
      if (in_list && match($0, "^  - ")) {
        val = substr($0, 5)
        gsub(/^[ \t]+|[ \t]+$/, "", val)
        print val
        next
      }
      if (in_list && !match($0, "^  ")) { in_list = 0 }
    }
  ' "$PROMPT_FILE"
}

MODEL_TIER=$(parse_frontmatter_field "model")
RUBRIC_REL=$(parse_frontmatter_field "rubric")
RUBRIC_FILE="$SCRIPT_DIR/$RUBRIC_REL"

if [[ -z "$MODEL_TIER" ]]; then
  echo "ERROR: prompt frontmatter missing 'model:' field" >&2
  exit 2
fi
if [[ ! -f "$RUBRIC_FILE" ]]; then
  echo "ERROR: rubric not found: $RUBRIC_FILE" >&2
  exit 2
fi

# Extract prompt body (everything after second ---)
PROMPT_BODY_FILE=$(mktemp)
trap 'rm -f "$PROMPT_BODY_FILE"' EXIT
awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2' "$PROMPT_FILE" > "$PROMPT_BODY_FILE"

run_one_fixture() {
  local fixture_name="$1"
  local fixture_dir="$FIXTURES_DIR/$fixture_name"

  # Fall back to per-prompt nested layout if short name was given.
  if [[ ! -d "$fixture_dir" ]] && [[ -d "$FIXTURES_DIR/$PROMPT_ID/$fixture_name" ]]; then
    fixture_dir="$FIXTURES_DIR/$PROMPT_ID/$fixture_name"
    fixture_name="$PROMPT_ID/$fixture_name"
  fi

  if [[ ! -d "$fixture_dir" ]]; then
    echo "ERROR: fixture not found: $fixture_dir" >&2
    return 2
  fi

  local input_file="$fixture_dir/input.json"
  local mock_file="$fixture_dir/mock-response.txt"
  if [[ ! -f "$input_file" ]]; then
    echo "ERROR: fixture missing input.json: $input_file" >&2
    return 2
  fi

  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local run_out="$OUT_DIR/$PROMPT_ID/$fixture_name/$ts"
  mkdir -p "$run_out"

  cp "$PROMPT_BODY_FILE" "$run_out/rendered-prompt.txt"

  local response_file="$run_out/llm-response.txt"
  local score_file="$run_out/score.json"

  if ! call_llm "$MODE" "$MODEL_TIER" "$PROMPT_BODY_FILE" "$input_file" "$mock_file" "$response_file"; then
    echo "ERROR: call_llm failed for $fixture_name" >&2
    return 2
  fi

  local rc=0
  score "$RUBRIC_FILE" "$response_file" "$score_file" "$VERBOSE" || rc=$?

  local overall
  overall=$(jq -r '.overall' "$score_file")
  printf "[%s] %s/%s — %s\n" "$MODE" "$PROMPT_ID" "$fixture_name" "$overall"
  return $rc
}

overall_rc=0

if [[ "$FIXTURE" == "--all" ]]; then
  # Use fixtures declared in frontmatter
  mapfile -t fixtures < <(parse_frontmatter_list "fixtures" | sed 's|^fixtures/||; s|/$||')
  if [[ ${#fixtures[@]} -eq 0 ]]; then
    echo "ERROR: no fixtures declared in prompt frontmatter" >&2
    exit 2
  fi
  for fx in "${fixtures[@]}"; do
    rc=0
    run_one_fixture "$fx" || rc=$?
    if (( rc == 2 )); then exit 2; fi
    if (( rc == 1 )); then overall_rc=1; fi
  done
else
  overall_rc=0
  run_one_fixture "$FIXTURE" || overall_rc=$?
fi

exit $overall_rc
