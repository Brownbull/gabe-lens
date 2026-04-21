#!/usr/bin/env bash
# call-llm.sh — LLM invocation for the scope prompt harness.
#
# Usage:
#   call_llm <mode> <model> <prompt-body-file> <input-json-file> <mock-response-file> <output-file>
#
# Modes:
#   mock  — copy mock-response-file to output-file (no API call)
#   real  — call Anthropic API with rendered prompt; write response to output-file
#
# Environment:
#   ANTHROPIC_API_KEY   — required for real mode
#   HARNESS_MODEL_OPUS  — override Opus model ID (default: claude-opus-4-7)
#   HARNESS_MODEL_SONNET — override Sonnet model ID (default: claude-sonnet-4-6)
#   HARNESS_MODEL_HAIKU — override Haiku model ID (default: claude-haiku-4-5-20251001)

set -euo pipefail

call_llm() {
  local mode="$1"
  local model_tier="$2"
  local prompt_body_file="$3"
  local input_json_file="$4"
  local mock_response_file="$5"
  local output_file="$6"

  if [[ "$mode" == "mock" ]]; then
    if [[ ! -f "$mock_response_file" ]]; then
      echo "ERROR: mock-response.txt missing at $mock_response_file" >&2
      return 2
    fi
    cp "$mock_response_file" "$output_file"
    return 0
  fi

  if [[ "$mode" == "real" ]]; then
    if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
      echo "ERROR: ANTHROPIC_API_KEY not set; real mode unavailable" >&2
      return 2
    fi

    local model_id
    case "$model_tier" in
      opus)   model_id="${HARNESS_MODEL_OPUS:-claude-opus-4-7}" ;;
      sonnet) model_id="${HARNESS_MODEL_SONNET:-claude-sonnet-4-6}" ;;
      haiku)  model_id="${HARNESS_MODEL_HAIKU:-claude-haiku-4-5-20251001}" ;;
      *) echo "ERROR: unknown model tier '$model_tier'" >&2; return 2 ;;
    esac

    # Render prompt: inject input.json fields as {{key}} placeholders.
    # For P1, pass prompt-body verbatim + append input.json as context.
    # Full templating lands in P3 alongside real prompts.
    local rendered
    rendered=$(cat "$prompt_body_file")
    rendered+=$'\n\n## Runtime input\n```json\n'
    rendered+=$(cat "$input_json_file")
    rendered+=$'\n```\n'

    local payload
    payload=$(jq -n \
      --arg model "$model_id" \
      --arg prompt "$rendered" \
      '{
        model: $model,
        max_tokens: 4096,
        temperature: 0,
        messages: [{role: "user", content: $prompt}]
      }')

    local response http_code
    # Capture body + HTTP status separately so we can fail hard on non-2xx.
    response=$(curl -sS -w "\n%{http_code}" https://api.anthropic.com/v1/messages \
      -H "x-api-key: $ANTHROPIC_API_KEY" \
      -H "anthropic-version: 2023-06-01" \
      -H "content-type: application/json" \
      -d "$payload")
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')

    if [[ "$http_code" != "200" ]]; then
      echo "ERROR: Anthropic API returned HTTP $http_code" >&2
      echo "$response" | jq -r '.error.message // .' >&2 2>/dev/null || echo "$response" >&2
      return 2
    fi

    # Anthropic messages API returns content[0].text on success.
    # Fail hard if the response doesn't match that shape (malformed JSON, schema change, etc.)
    local text
    if ! text=$(echo "$response" | jq -er '.content[0].text' 2>&1); then
      echo "ERROR: could not extract text from API response (malformed or schema change?)" >&2
      echo "Raw response: $response" >&2
      return 2
    fi
    printf '%s' "$text" > "$output_file"
    return 0
  fi

  echo "ERROR: unknown mode '$mode' (expected 'mock' or 'real')" >&2
  return 2
}

# Allow sourcing without executing
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  call_llm "$@"
fi
