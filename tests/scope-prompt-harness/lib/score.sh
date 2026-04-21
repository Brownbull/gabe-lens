#!/usr/bin/env bash
# score.sh — Rubric scoring for the scope prompt harness.
#
# Usage:
#   score <rubric-file> <response-file> <score-output-file> [--verbose]
#
# Exit: 0=PASS, 1=FAIL, 2=harness error
#
# Assertion types supported (Phase 1):
#   output_is_json        — response parses as JSON
#   field_exists          — jq path resolves to non-null in response (JSON only)
#   field_in_set          — value at jq path is in declared set (JSON only)
#   contains_phrase       — response contains substring (case-sensitive)
#   absent_phrase         — response does NOT contain substring
#   max_chars             — response length <= limit (proxy for token budget)
#   min_chars             — response length >= limit
#   markdown_anchors_resolve — (JSON-only) checks that every [link](#anchor) in the
#                              value at `path` resolves to a matching `{#anchor}`
#                              definition in the same markdown string

set -euo pipefail

score() {
  local rubric_file="$1"
  local response_file="$2"
  local score_output_file="$3"
  local verbose="${4:-}"

  if [[ ! -f "$rubric_file" ]]; then
    echo "ERROR: rubric file missing: $rubric_file" >&2
    return 2
  fi
  if [[ ! -f "$response_file" ]]; then
    echo "ERROR: response file missing: $response_file" >&2
    return 2
  fi

  local response
  response=$(cat "$response_file")

  local rubric_json
  rubric_json=$(cat "$rubric_file")

  local n_assertions
  n_assertions=$(echo "$rubric_json" | jq '.assertions | length')

  local results='[]'
  local any_fail=0

  local i
  for ((i=0; i<n_assertions; i++)); do
    local a
    a=$(echo "$rubric_json" | jq ".assertions[$i]")
    local atype
    atype=$(echo "$a" | jq -r '.type')
    local adesc
    adesc=$(echo "$a" | jq -r '.description // ""')

    local pass=true
    local detail=""

    case "$atype" in
      output_is_json)
        if echo "$response" | jq empty 2>/dev/null; then
          pass=true
        else
          pass=false
          detail="response does not parse as JSON"
        fi
        ;;

      field_exists)
        local path
        path=$(echo "$a" | jq -r '.path')
        if ! echo "$response" | jq empty 2>/dev/null; then
          pass=false
          detail="response not JSON; cannot check path '$path'"
        else
          # Use jq's type function — returns "null" if value is null, "MISSING" if path absent.
          # Distinguishes missing/null from false/0 (both are valid present values).
          local type_result
          type_result=$(echo "$response" | jq -r "$path | type" 2>/dev/null || echo "MISSING")
          if [[ "$type_result" == "MISSING" || "$type_result" == "null" ]]; then
            pass=false
            detail="path '$path' missing or null"
          fi
        fi
        ;;

      field_in_set)
        local path
        path=$(echo "$a" | jq -r '.path')
        local values
        values=$(echo "$a" | jq -c '.values')
        if ! echo "$response" | jq empty 2>/dev/null; then
          pass=false
          detail="response not JSON; cannot check path '$path'"
        else
          local val
          val=$(echo "$response" | jq -r "$path | tostring")
          local in_set
          in_set=$(echo "$values" | jq -r --arg v "$val" 'any(tostring == $v)')
          if [[ "$in_set" != "true" ]]; then
            pass=false
            detail="value '$val' at '$path' not in set $values"
          fi
        fi
        ;;

      contains_phrase)
        local phrase
        phrase=$(echo "$a" | jq -r '.phrase')
        if ! grep -qF -- "$phrase" "$response_file"; then
          pass=false
          detail="response missing required phrase: '$phrase'"
        fi
        ;;

      absent_phrase)
        local phrase
        phrase=$(echo "$a" | jq -r '.phrase')
        if grep -qF -- "$phrase" "$response_file"; then
          pass=false
          detail="response contains forbidden phrase: '$phrase'"
        fi
        ;;

      max_chars)
        local limit
        limit=$(echo "$a" | jq -r '.limit')
        local len="${#response}"
        if (( len > limit )); then
          pass=false
          detail="response length $len exceeds max_chars $limit"
        fi
        ;;

      min_chars)
        local limit
        limit=$(echo "$a" | jq -r '.limit')
        local len="${#response}"
        if (( len < limit )); then
          pass=false
          detail="response length $len below min_chars $limit"
        fi
        ;;

      markdown_anchors_resolve)
        local path
        path=$(echo "$a" | jq -r '.path')
        if ! echo "$response" | jq empty 2>/dev/null; then
          pass=false
          detail="response not JSON; cannot extract markdown at '$path'"
        else
          local md
          md=$(echo "$response" | jq -r "$path // \"\"")
          if [[ -z "$md" ]]; then
            pass=false
            detail="markdown at '$path' is empty"
          else
            # Extract [text](#anchor) references and {#anchor} definitions.
            # Same-file links only (start with '#' not 'SCOPE.md#' or similar).
            local refs defs missing
            refs=$(echo "$md" | grep -oE '\]\(#[a-zA-Z0-9_-]+\)' | sed -E 's|\]\(#||; s|\)||' | sort -u)
            defs=$(echo "$md" | grep -oE '\{#[a-zA-Z0-9_-]+\}' | sed -E 's|\{#||; s|\}||' | sort -u)
            missing=$(comm -23 <(echo "$refs") <(echo "$defs") | head -5)
            if [[ -n "$missing" ]]; then
              pass=false
              detail="unresolved same-file anchor refs: $(echo "$missing" | tr '\n' ',' | sed 's/,$//')"
            fi
          fi
        fi
        ;;

      *)
        pass=false
        detail="unknown assertion type: '$atype'"
        ;;
    esac

    if [[ "$pass" == "false" ]]; then
      any_fail=1
    fi

    results=$(echo "$results" | jq \
      --arg type "$atype" \
      --arg desc "$adesc" \
      --arg pass "$pass" \
      --arg detail "$detail" \
      '. + [{type: $type, description: $desc, pass: ($pass == "true"), detail: $detail}]')

    if [[ "$verbose" == "-v" || "$verbose" == "--verbose" ]]; then
      if [[ "$pass" == "true" ]]; then
        echo "  PASS: $atype — $adesc"
      else
        echo "  FAIL: $atype — $adesc — $detail"
      fi
    fi
  done

  local overall
  if (( any_fail == 0 )); then
    overall="PASS"
  else
    overall="FAIL"
  fi

  echo "$results" | jq \
    --arg overall "$overall" \
    '{overall: $overall, assertions: .}' > "$score_output_file"

  if (( any_fail == 0 )); then
    return 0
  else
    return 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  score "$@"
fi
