# Validate-mode triage checklist

> Static reference consumed by the `/gabe-mockup validate` S6 (Triage loop) step in SKILL.md. Read this when running the loop interactively. This file is NOT a template — it ships verbatim.

## Per-finding card format

When the runner emits findings into `.kdbp/MOCKUP-VALIDATION.md`, each pending entry shows as:

```
- [ ] **[abc1234567]** <ruleId> / <severity> / <viewport> — <message>
  - **Element:** `<selector>`
  - **Status:** pending
  - **Notes:** —
```

## Triage actions (per finding)

| Key | Action | Effect |
|-----|--------|--------|
| `f` | **Fix** | Edit the screen now to resolve the underlying issue. After your edit, re-run the runner — the next pass detects the fix and the stable-ID drops off the active findings list. |
| `d` | **Defer** | Set `Status: deferred` on the line. Re-emit moves the finding into the "Triage Backlog (deferred)" section; it stays there until you change Status back to `pending` or `fixed-in-place`. |
| `x` | **Dismiss** | Set `Status: dismissed` and prompt for a one-line reason saved into Notes. The finding moves to the "Dismissed" section; the stable-ID guards against re-surfacing on the next run unless the underlying issue changes (selector / message). |
| `s` | **Skip** | Leave `Status: pending`. Useful for revisiting the same finding in a later session. |
| `e` | **Explain** | Delegate to the `gabe-lens` skill for an analogy + concrete fix suggestion. Falls back to inline explanation if `gabe-lens` is not installed. |
| `q` | **Quit** | Stop triaging. The file is the source of truth — pick up where you left off next time. |

## Bulk shortcuts (offer up front when finding count > 5)

| Action | Effect |
|--------|--------|
| Defer all warns | Sets `Status: deferred` on every `pending` finding with `severity: warn`. |
| Defer all info | Sets `Status: deferred` on every `pending` finding with `severity: info`. |
| Walk all blocks | Loops only through `severity: block` findings; offer f/d/x/s/e/q per finding. |
| Skip C2 narrow-columns | Sets `enabled: false` for `C2_narrow_columns` in `tests/mockups/validate/rules.json` (persists until re-enabled). |
| Skip C3 empty-content | Sets `enabled: false` for `C3_empty_content` in `tests/mockups/validate/rules.json`. |

## Idempotency

- Stable-ID = `sha1(screen + viewport + ruleId + selector)` truncated to 10 chars.
- Re-running `runner.mjs` preserves user-set Status values for matching IDs.
- New findings always come in as `pending`.
- Old findings whose stable-IDs are no longer present (issue resolved) drop off the active list automatically.
- Re-promoting a dismissed finding requires editing Status back to `pending` manually.

## When to re-run

- After `/gabe-mockup` lands a new screen — M5–M12 phase exit auto-runs validate over screens emitted in that phase, unless `--skip-validation` was passed.
- After hand-editing a screen to fix a finding (the `f` action implies re-run).
- After modifying `tests/mockups/validate/rules.json` thresholds.
- On-demand: `node tests/mockups/validate/runner.mjs`.

## Subset flags

| Flag | Effect |
|------|--------|
| `--screens=foo,bar` | Only listed screens (matched by `name` from INDEX.md §3 / file basename). |
| `--viewports=phone` | Only listed viewports — any subset of `phone,tablet,desktop`. |
| `--severity=block` | Filter to listed severities — any subset of `block,warn,info`. |
| `--skip-kdbp` | Disable C4 (KDBP rule binding). Useful for focused layout-only sweeps. |

## False-positive playbook

| Symptom | Likely cause | Action |
|---------|--------------|--------|
| All screens flag `body-overflow` at phone viewport | Dynamic architecture didn't apply `[data-viewport]`; project lacks tweaks.js viewport switcher | Switch to per-device architecture OR add viewport switcher to tweaks.js |
| `list-emptiness` on legitimate empty-state screen | Screen variant naming doesn't match `skip_screens_pattern` | Rename screen file to include `-empty` / `-zero` suffix, OR add screen name to `rules.json` `skip_screens` array |
| `min-column-width` on intentionally-narrow column (e.g., a 32px icon column) | Default 60px threshold too aggressive for icon columns | Lower `min_column_width_px` in rules.json OR dismiss the finding with reason "icon column, intentional" |
| KDBP rule with no detector emits info finding on every screen | Rule tagged `applies-to: mockup-screens` but no `detect:` line in RULES.md | Add `detect: dom-selector <css>` to the rule OR change `applies-to:` to scope it tighter (e.g., `mockup:<screen>`) |
