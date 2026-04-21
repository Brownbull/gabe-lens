# Upstream Fixes — Dangling Classifier + LEDGER Hook Regex

**Status:** open
**Origin:** surfaced in `ai-app` session 2026-04-21 during `/gabe-push` after commit `8b40803`
**Scope:** `gabe_lens` repo only — not a downstream project fix
**Intent:** dedicated session applies both fixes, verifies, commits to `gabe_lens`, then reinstalls skills/hooks into consumer projects

---

## Fix 1 — Classifier Candidate Auto-Persist on Drop-Through

### Problem

`/gabe-push` Step 7.5b ("Operational Decision Candidate") and `/gabe-review` Step 5b ("Architectural Decision Candidate") both surface a proposal with `[accept] / [edit] / [note|defer] / [drop]` actions. If the user moves on without picking — which happens routinely in non-interactive flow (agent continues work, tool returns before user chooses) — the proposal evaporates. No persistence, no re-surface.

**Observed instance** (ai-app, 2026-04-21):

```
ℹ Classifier candidate pending: trunk-first operational decision — pick [accept] [note] [drop] when ready
```

User ran `/gabe-review` after and the candidate never re-appeared. Lost proposal.

### Decision

**Auto-persist unresolved candidates as `defer` → `.kdbp/PENDING.md` with `source=classifier`, `status=open`.** Re-surface on next `/gabe-push` or `/gabe-review` run that detects any open classifier row in PENDING.md.

Rationale:
- Matches existing PENDING pattern (D1-trigger already lives there with `source=gabe-teach`).
- Zero friction — user doesn't have to act immediately.
- Compounds with existing backlog workflow. Classifier candidates become first-class tracked items.
- No new file required. Reuses `.kdbp/PENDING.md`.

Rejected alternatives:
- **Block-exit until user picks**: too heavy-handed. Breaks non-interactive/agent flow.
- **Dedicated `.kdbp/CLASSIFIER_CANDIDATES.md`**: overkill — new file for same pattern.

### Target Changes

#### A. `commands/gabe-push.md` — Step 7.5b action handlers

Add fourth action + new default-on-exit rule.

**Current** (lines 225-227):
```
  [accept]  Append to .kdbp/DECISIONS.md as D[next_id] with `operational` tag
  [note]    Write one-liner to today's DEPLOYMENTS.md Decisions column instead (lighter weight)
  [drop]    Don't record
```

**Proposed**:
```
  [accept]  Append to .kdbp/DECISIONS.md as D[next_id] with `operational` tag
  [note]    Write one-liner to today's DEPLOYMENTS.md Decisions column instead (lighter weight)
  [defer]   Write to .kdbp/PENDING.md with source=classifier — re-surface next run
  [drop]    Don't record (session-scoped dedup on title)
```

**Current** action handlers table (line 230-236):

Add row:
```
| `defer` | Append to PENDING.md: `| today | classifier | [title] | - | small | medium | low | 0 | open |`. Source column = `classifier`. Title stored verbatim for dedup on re-surface. |
```

**New behavior — default on drop-through:**

Append this paragraph after the action handlers table:

> **Default-on-drop-through:** If the command completes without the user picking an action (common in non-interactive flow — agent continues before user can choose), treat as `defer`. The unresolved candidate is persisted to PENDING.md so it re-surfaces instead of vanishing. Session-scoped dedup still applies per-title to prevent double-persist within a single run.

#### B. `commands/gabe-review.md` — Step 5b action handlers

Same change in Review skill. Current actions (per SKILL.md search):
```
[accept]  Append to .kdbp/DECISIONS.md as D[next_id]
[edit]    Revise fields before writing
[defer]   Add reminder to PENDING.md (source=gabe-review)
[drop]    Don't write (one-time dismissal this session)
```

`[defer]` already exists here with `source=gabe-review`. Change needed: add **default-on-drop-through = defer** rule here too. Currently the skill does not specify drop-through behavior, so the candidate evaporates if user doesn't pick.

**Consistency update:** align source tag. Today `gabe-review` uses `source=gabe-review`, `gabe-push` has no defer. Proposal: both use `source=classifier` to unify re-surface logic (easier grep, one source name for all classifier output). Or keep separate tags — either works, just pick one and document.

**Recommend:** `source=classifier` for both. Downstream re-surface step greps `source=classifier` regardless of origin skill.

#### C. Re-surface at start of `/gabe-push` and `/gabe-review`

New step at start of both skills (Step 0.6, after KDBP context load):

> **Re-surface deferred classifier candidates:** Read `.kdbp/PENDING.md`. For rows with `source=classifier` and `status=open`: render each as its original proposal block (title, proposed rationale, actions) BEFORE current-run classifier runs. User acts or drops through. Drop-through keeps row as `open` (age increments naturally). Resolution (`accept`/`note`/`drop`) updates PENDING row to `resolved` with today's date.

This is the piece that closes the loop — deferred items actually come back.

### Verification

After applying fixes to `gabe_lens`:
1. Reinstall consumer project: `bash ~/projects/gabe_lens/install.sh` (or project-local reinstall path).
2. In `ai-app`: verify the 2026-04-21 classifier candidate (trunk-first operational decision) re-surfaces on next `/gabe-push` run.
3. Test three paths: `accept` writes to DECISIONS.md, `defer` leaves in PENDING.md, drop-through auto-persists.

---

## Fix 2 — LEDGER Hook Regex Too Loose

### Problem

PostToolUse hook in `~/.claude/settings.json` captures commit info into `.kdbp/LEDGER.md`. Current regex matches any `[<anything>]` pattern — including non-commit heading content like `[pre-flight]`, `[classifier]`, `[phase-1]` that appear in command output.

**Observed instance** (ai-app `.kdbp/LEDGER.md`):

5 garbage entries at timestamps 12:09, 12:10, 12:49 on 2026-04-21 — all from `/gabe-push` and `/gabe-commit` output lines matching `## YYYY-MM-DD HH:MM — [heading]` format. None are real git commits.

### Current Regex (in `~/.claude/settings.json`)

```bash
TOOL_OUTPUT=$(cat)
if echo "$TOOL_OUTPUT" | grep -qE '\[.+\] .+'; then
  COMMIT_LINE=$(echo "$TOOL_OUTPUT" | grep -oE '\[.+\] .+' | head -1)
  TS=$(date '+%Y-%m-%d %H:%M')
  if [ -f .kdbp/LEDGER.md ]; then
    echo "" >> .kdbp/LEDGER.md
    echo "## ${TS} — ${COMMIT_LINE}" >> .kdbp/LEDGER.md
  fi
fi
```

Pattern `\[.+\] .+` — matches ANY bracketed text followed by any content. No commit-hash requirement.

### Fix

Tighten to require git commit-hash format inside brackets: `[0-9a-f]{7,40}`.

**Proposed regex:**

```bash
TOOL_OUTPUT=$(cat)
# Require git's standard commit output: `[branch hash]` or `[hash]` where hash = 7-40 hex chars.
# Git commit command emits: `[main 8b40803] <subject>` or `[8b40803] <subject>` — both match.
if echo "$TOOL_OUTPUT" | grep -qE '\[[^]]*[0-9a-f]{7,40}[^]]*\] .+'; then
  COMMIT_LINE=$(echo "$TOOL_OUTPUT" | grep -oE '\[[^]]*[0-9a-f]{7,40}[^]]*\] .+' | head -1)
  TS=$(date '+%Y-%m-%d %H:%M')
  if [ -f .kdbp/LEDGER.md ]; then
    echo "" >> .kdbp/LEDGER.md
    echo "## ${TS} — ${COMMIT_LINE}" >> .kdbp/LEDGER.md
  fi
fi
```

Pattern breakdown:
- `\[` — literal opening bracket
- `[^]]*` — any chars except `]` (allows branch name + space prefix)
- `[0-9a-f]{7,40}` — REQUIRED git hex hash, 7-40 chars (matches git's short + full hash range)
- `[^]]*` — any chars except `]` (allows trailing content inside bracket)
- `\]` — literal closing bracket
- ` .+` — space + subject

This matches real git commit output:
- `[main 8b40803] feat: ...` ✓
- `[main (root-commit) cf30399] chore: ...` ✓
- `[8b40803] feat: ...` ✓

And rejects false positives:
- `[pre-flight] ...` ✗ (no hex)
- `[phase-1] ...` ✗ (no hex)
- `[classifier] ...` ✗ (no hex)
- `[accept] ...` ✗ (no hex)

### Target Change

#### A. `~/.claude/settings.json` PostToolUse hook

Locate the hook that appends to LEDGER.md (search for `LEDGER.md` within the `hooks` block). Replace the regex per above. Single-line edit.

#### B. Installer — `install.sh` and/or `commands/gabe-init.md`

If `install.sh` writes the hook into user's settings.json, update the template string there too. Otherwise document the fix in `gabe-init.md` so future fresh installs get the correct regex.

Grep location:
```bash
grep -rn 'LEDGER.md\|\[.+\].*grep' ~/projects/gabe_lens/install.sh ~/projects/gabe_lens/commands/gabe-init.md
```

### Verification

After fix applied to `~/.claude/settings.json`:
1. Run `/gabe-commit` → check .kdbp/LEDGER.md gets one new entry with real commit hash.
2. Run `/gabe-push` → check LEDGER gets PUSH entry but NOT the `[pre-flight]` / `[classifier]` noise.
3. Inspect `ai-app/.kdbp/LEDGER.md` — remove the 5 garbage 2026-04-21 entries manually (deferred cleanup).

---

## Session Checklist

When the dedicated session starts:

- [ ] Apply Fix 1A: `commands/gabe-push.md` Step 7.5b action handlers table + default-on-drop-through paragraph
- [ ] Apply Fix 1B: `commands/gabe-review.md` Step 5b — align `source=classifier`, add default-on-drop-through
- [ ] Apply Fix 1C: `commands/gabe-push.md` + `commands/gabe-review.md` — new Step 0.6 re-surface logic
- [ ] Apply Fix 2A: `~/.claude/settings.json` LEDGER hook regex
- [ ] Apply Fix 2B: installer / `gabe-init.md` template update
- [ ] Smoke test in ai-app: re-surface + real-commit capture + noise rejection
- [ ] Clean up 5 garbage LEDGER entries in `ai-app/.kdbp/LEDGER.md` (2026-04-21 12:09/12:10/12:49)
- [ ] Commit to `gabe_lens`: `fix(push,review): auto-defer dangling classifier candidates + tighten LEDGER hook regex`
- [ ] Reinstall gabe skills into active projects (ai-app + any other active KDBP projects)

---

## Open Questions for Session Start

1. **Source tag unification**: keep `source=gabe-review` for review-origin defers + add `source=classifier` for push-origin, OR unify both to `source=classifier`? Recommendation above is unify — confirm before implementing.
2. **PENDING.md column for title**: title goes in the `Finding` column (existing). Stored verbatim. On re-surface, compare titles case-insensitively for dedup.
3. **Re-surface order**: before or after current-run classifier? Recommendation is *before* — resolve old candidates first, then assess new.
4. **Auto-resolve on duplicate detection**: if current-run classifier produces same title as an open PENDING row, auto-resolve PENDING row and skip re-render to avoid the same proposal twice in one run. Confirm.
5. **LEDGER garbage cleanup for existing projects**: fix regex OR also scan existing LEDGER.md files for entries without hex hashes and flag them? Narrow-scope = fix hook only. Wider scope = add `/gabe-health` check. Recommend narrow scope for this session, add check separately if needed.
