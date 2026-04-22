---
name: gabe-push
description: "Push, create PR, watch CI, promote branches — the post-commit shipping workflow. Captures deployment events in .kdbp/DEPLOYMENTS.md and proposes operational DECISIONS.md entries when infra/CI/deploy configs change. Usage: /gabe-push"
---

# Gabe Push

The stupidest way to ship. Push, PR, watch CI, promote. First run auto-detects your setup; every run after that repeats the same flow.

> **Rendering note.** Output templates in this spec wrapped in bare triple-backtick fences are spec-meta delimiters — render their contents as plain markdown at runtime. Tagged fences (```bash, ```json, ```diff) stay fenced. See `gabe-docs/SKILL.md` § "Runtime output rendering convention".

## Procedure

### Step 1: Validate prerequisites

1. Verify `gh` CLI: `gh --version 2>/dev/null`. If missing: "Install GitHub CLI: https://cli.github.com/" — stop.
2. Verify auth: `gh auth status 2>/dev/null`. If not authenticated: "Run `gh auth login` first" — stop.
3. Verify git repo with remote: `git remote -v`. If no remote: "No remote configured. Run `git remote add origin <url>` first" — stop.
4. Read `.kdbp/PUSH.md`. If it exists, skip to Step 3. If not, continue to Step 2.

### Step 2: First-run setup (creates `.kdbp/PUSH.md`)

1. Detect remote: `git remote -v`. Default to `origin`. If multiple remotes, ask user to pick.
2. Detect default branch: `gh repo view --json defaultBranchRef -q '.defaultBranchRef.name' 2>/dev/null`. Fallback to `main`.
3. Detect branch strategy from `git branch -r --list 'origin/*'`:
   - `origin/develop` exists alongside `origin/main` → suggest `gitflow`
   - Otherwise → suggest `trunk-based`
   - Ask: "Detected [strategy]. Correct? [Y/n]"
4. Detect CI provider:
   - `.github/workflows/` exists → `github-actions`
   - None found → `none`
5. Detect PR template: check `.github/pull_request_template.md` or `.github/PULL_REQUEST_TEMPLATE/`.
6. Build promotion chain:
   - trunk-based: `feature -> main`
   - gitflow: `feature -> develop -> main`
7. Write `.kdbp/PUSH.md` using the template format (see templates/PUSH.md).
8. Show: "Push config saved to `.kdbp/PUSH.md`. Edit anytime to adjust."
9. Ask: "Push now? [Y/n]" — if yes, continue to Step 3.

### Step 3: Pre-flight checks

1. Get current branch: `git branch --show-current`.
2. Guard: if on the default branch AND strategy is not `trunk-based`:
   - Warn: "You are on [main]. Push directly? This skips PR workflow. [y/N]"
3. Check uncommitted changes: `git status --porcelain`.
   - If changes exist, show count and ask:
     - `[commit]` — run `/gabe-commit` first, then continue
     - `[push-only]` — push only what's already committed
     - `[abort]` — stop
   - If user picks `commit` and gabe-commit blocks (CRITICAL findings), stop the push.
4. Check unpushed commits: `git rev-list @{u}..HEAD --count 2>/dev/null`.
   - If 0 and not a new local branch: "Nothing to push. All commits already on remote." — stop.

### Step 4: Push

1. Push: `git push -u [remote] [branch]`.
2. If push fails (rejected, auth error): show error and stop.
3. Show: "Pushed [branch] to [remote]."

### Step 5: Create or update PR

1. Check for existing PR: `gh pr view [branch] --json number,state,url 2>/dev/null`.
   - If PR exists and `OPEN`: show "PR already exists: [url]". Skip to Step 6.
2. Generate PR title: most recent commit subject, or branch name as title if multiple commits.
3. Generate PR body:
   - Commit summary: `git log origin/[target]..HEAD --pretty=format:'- %s' --reverse` (cap at 50).
   - If PR template exists, read it and prepend the commit summary.
   - If no template:
     ```
     ## Changes
     
     [commit list]
     
     ## Context
     
     Branch: [branch] -> [target]
     Commits: [N]
     ```
4. Create PR: `gh pr create --base [target] --head [branch] --title "[title]" --body "[body]"`.
5. Show: "PR created: [url]"

### Step 6: CI Watch (non-blocking, 75s max)

1. If CI provider in PUSH.md is `none`: "No CI configured. Done." — skip to Step 7.
2. Poll `gh pr checks [branch]` up to 5 times, 15-second intervals.
3. Each poll, show status:
   ```
   CI: ⏳ build (running)  ✅ lint (pass)  ⏳ test (running)
   ```
4. All checks pass: "CI: All checks passed." — continue to Step 7.
5. Any check fails:
   ```
   CI: ✅ lint (pass)  ❌ test (fail)  ✅ build (pass)
   Failed: test
   ```
   Offer actions:
   - `[details]` — show `gh pr checks --fail-only` output
   - `[logs]` — show `gh run view [run-id] --log-failed` output
   - `[auto-fix]` — if failure name matches lint/format/type patterns: attempt local fix, commit, re-push
   - `[assess]` — suggest `/gabe-assess [failure context]` for complex failures
   - `[ignore]` — continue without fixing
6. Timeout (75s): "CI still running. Check later: `gh pr checks`."

### Step 7: Branch promotion (optional)

1. Read promotion chain from PUSH.md (e.g., `feature -> develop -> main`).
2. If current PR target is the final link (e.g., `main`): done.
   ```
   GABE PUSH COMPLETE
   Branch: [branch] -> [target]
   PR: [url]
   CI: [status]
   ```
3. If there is a next target:
   - Ask: "Promote [current target] -> [next target]? [Y/n]"
   - If yes: wait for PR merge (`gh pr view --json state`), then:
     - `git checkout [current-target] && git pull`
     - Create new PR: `gh pr create --base [next-target] --head [current-target]`
     - Repeat Step 6 for the new PR
   - If no: "Promotion skipped. When ready, merge the PR and run `/gabe-push` from [current-target]."

### Step 7.5: Capture deployment event → `DEPLOYMENTS.md` (Phase 4/6 of doc-lifecycle work)

Only runs when Step 4 (push) completed successfully. Otherwise skip silently — nothing to record about a failed push.

**Preconditions:**

- `.kdbp/` exists (required for all of push anyway).
- If `.kdbp/DEPLOYMENTS.md` doesn't exist: copy it from `~/.claude/templates/gabe/DEPLOYMENTS.md` before appending. Never overwrite existing.

**Assemble the row** (pure deterministic aggregation of data push already collected — zero LLM):

| Column | Source |
|--------|--------|
| `#` | Next `P[N]` — read DEPLOYMENTS.md, find max existing `P` ID, add 1 |
| `Date` | Current timestamp `YYYY-MM-DD HH:MM` (local time) |
| `Branch → Target` | Current branch (from Step 1) → PR base branch (from Step 5) |
| `PR` | PR number from Step 5 (format `#N`) or `—` if no PR (e.g., direct push to branch without PR) |
| `CI Result` | Code from Step 6 outcome (see table below) |
| `Notes` | Event summary (see table below) |
| `Decisions` | `—` (Phase 5 will populate this via Step 7.5b operational note action) |

**CI Result codes** (pick one, in order of precedence):

| Code | Condition |
|------|-----------|
| `✅ N/N (Ms)` | All checks passed in M seconds |
| `⚠ N/M (Ms)` | M-N warnings or soft-failing checks, no hard failures |
| `❌ X/M (Ms) — failed: <name>` | X hard failures; name from the first failing check |
| `⏳ timeout` | CI still running when 75s cap hit |
| `—` | CI provider is `none` in PUSH.md (no CI configured) |

**Notes codes** (concat with `; ` when multiple apply):

| Code | When to include |
|------|-----------------|
| `promoted [from] → [to]` | Step 7 promotion succeeded, include target chain |
| `promotion skipped` | Step 7 prompt returned `n` or no next target |
| `auto-fix applied: [lint\|format\|type]` | Step 6 auto-fix path fired; list fix categories |
| `CI re-run after fix` | Auto-fix path triggered a second push |
| `PR merged before push` | Pre-existing merged PR detected (rare) |
| `—` | None of the above |

**Append the row** using the Edit tool:

1. Read `.kdbp/DEPLOYMENTS.md`.
2. Find the last `| P[N] |` row (or the header's separator line if table is empty).
3. Append the new row on a new line directly after it.

If the Edit fails due to a concurrent writer (shouldn't happen — push is the sole writer — but defensive), re-read and retry once.

**Example rendering:**

```
| P7 | 2026-04-17 14:22 | feature/add-auth → main | #42 | ✅ 3/3 (47s) | promoted main → prod | — |
| P8 | 2026-04-17 15:08 | fix/ci-typo → main | #43 | ❌ 1/3 (12s) — failed: lint | auto-fix applied: lint; CI re-run after fix | — |
```

**Sub-check 7.5b — Operational Decision Detection (Phase 5/6 of doc-lifecycle work):**

Only runs when Step 7.5a appended a row AND the BEHAVIOR.md frontmatter doesn't set `push_operational_classifier: never`. Otherwise skip silently.

**Pre-step — Re-surface deferred classifier candidates (runs BEFORE trigger layer):**

Read `.kdbp/PENDING.md`. For every row where `Source` column = `classifier` AND `Status` column = `open`:

1. Render each as an original proposal block using the same format as the Interactive triage output below. Use the `Finding` column as `title`. Rationale/alternatives/review_trigger are not re-stored in PENDING.md — if present from the original defer, pull from a `Notes` suffix; otherwise render the row as a minimal candidate (title only + "originally deferred YYYY-MM-DD") and skip alternatives.
2. User picks `[accept]` / `[note]` / `[defer]` / `[drop]` per row. Action handlers behave identically to current-run handlers. `accept`/`note`/`drop` set the PENDING row's `Status` to `resolved` with today's date. `defer` (explicit or drop-through) keeps `Status = open` and increments `Times Deferred`.
3. After all re-surfaced rows are resolved or dropped-through, continue to current-run trigger layer.

**Auto-resolve on current-run duplicate:** when the current-run classifier produces a `title` case-insensitively matching any re-surfaced open PENDING row, auto-resolve the PENDING row (`Status = resolved`, today's date, note `auto-resolved: superseded by current run`) and suppress the re-render. This prevents the same proposal from appearing twice in one run.

**Trigger layer** (zero-cost, all fire-independently; ≥1 hit → proceed to classifier):

| Trigger | Signal |
|---------|--------|
| CI-config modified | Diff for this push (use `git diff HEAD~N..HEAD` where N = commits being pushed) modifies any file under `.github/workflows/**`, `.gitlab-ci.yml`, `.circleci/**`, `azure-pipelines.yml` |
| Infra-as-code change | Diff modifies any file under `infra/**`, `terraform/**`, `pulumi/**`, `k8s/**`, `helm/**` |
| Deployment config | Diff modifies `docker-compose*.yml`, `Dockerfile*`, `fly.toml`, `railway.toml`, `render.yaml`, `vercel.json`, `netlify.toml` |
| Auto-fix config change | Step 6 auto-fix path fired AND it modified a config file (lint config, type config, CI workflow) |
| Rollback/revert | Any commit in the pushed range has a subject starting with `revert:` or `rollback:` |
| Trunk-first push | Push target is the repo's default branch AND PUSH.md promotion chain has `trunk-based: true` AND this is the first such push in LEDGER.md (rare — captures the "why direct to main" moment) |
| Promotion skipped when chain existed | Step 7 prompted to promote and user chose `n` (deliberate non-advance — worth capturing why) |

**Classifier layer** (LLM, cheap model, fires only when trigger hits AND no `operational`-tagged DECISIONS.md row covers this event):

- **Model:** Haiku-tier
- **Context:** trigger reason(s), commit subject(s) in pushed range, top 5 changed files in the triggered category, last 3 operational DECISIONS.md rows (dedup awareness)
- **Max tokens:** 200
- **Structured output** (`output_type` enforced — user value U4):
  ```
  OperationalDecisionCandidate:
    is_operational_decision: bool   # false → drop, no proposal
    title: str                      # one-line, <80 chars
    rationale: str                  # 2-3 sentences
    alternatives: list[str]         # 0-2 alternatives considered
    review_trigger: str             # when to revisit
  ```
- If `is_operational_decision == false`: drop silently.

**Interactive triage** (output block):

```
### Operational Decision Candidate

  Detected: [trigger reason]
  Proposed DECISIONS.md entry (tagged `operational`):

    Date:           2026-04-17
    Decision:       [title]
    Rationale:      [rationale]
    Alternatives:   [alt 1]
                    [alt 2]
    Status:         active,operational
    Review Trigger: [review_trigger]

  [accept]  Append to .kdbp/DECISIONS.md as D[next_id] with `operational` tag
  [note]    Write one-liner to today's DEPLOYMENTS.md Decisions column instead (lighter weight)
  [defer]   Write to .kdbp/PENDING.md with source=classifier — re-surface next run
  [drop]    Don't record (session-scoped dedup on title)
```

**Action handlers:**

| Action | Behavior |
|--------|----------|
| `accept` | Append to DECISIONS.md using same mechanism as review 5b. `Status` column = `active,operational`. Dedup: existing DECISIONS.md row with matching title case-insensitively → drop instead of append. Mark any open PENDING.md classifier row with matching title as `resolved` (today's date). |
| `note` | Find today's DEPLOYMENTS.md row (the one Step 7.5a just wrote, by `Date` and `PR` match). Update its `Decisions` column from `—` to a one-liner of `title`. Never appends a new row; updates the one already written. Mark any open PENDING.md classifier row with matching title as `resolved` (today's date). |
| `defer` | Append to PENDING.md: `\| P[N] \| today \| classifier \| [title] \| - \| [maturity] \| medium \| low \| 0 \| open \|`. Source column = `classifier`. Title stored verbatim in Finding for dedup on re-surface. If an open classifier row already exists with matching title (case-insensitive), increment `Times Deferred` on that row instead of creating a duplicate. |
| `drop` | No write. Session-scoped dedup on title. Also mark any open PENDING.md classifier row with matching title as `resolved` (today's date) to prevent re-surface loop. |

**Default-on-drop-through:** If the command completes without the user picking an action (common in non-interactive flow — agent continues before user can choose), treat as `defer`. The unresolved candidate is persisted to PENDING.md so it re-surfaces instead of vanishing. Session-scoped dedup still applies per-title to prevent double-persist within a single run.

**BEHAVIOR.md opt-out flag:**

Humans can disable the classifier entirely by adding `push_operational_classifier: never` to `.kdbp/BEHAVIOR.md` frontmatter. When present:

- Trigger layer still runs but no LLM call is made.
- No output rendered for 7.5b.
- Step 7.5a (DEPLOYMENTS.md capture) still runs normally — the opt-out is only for the classifier.

**Race handling with `/gabe-review` 5b:** both commands append to DECISIONS.md. Dedup is by case-insensitive title match. Edit-tool collisions retry with fresh read. `operational` tag in Status column lets downstream readers (notably `/gabe-teach` Loop L6) filter cleanly.

**Explicit non-goal:** this step NEVER touches `docs/architecture.md`, `docs/AGENTS_USE.md`, `docs/SCALING.md`, `docs/api.md`, `README.md`, `docs/wells/*.md`, `KNOWLEDGE.md`, or `STRUCTURE.md`. Push is operational-only. If deployment issues trigger code fixes, those flow through a separate `/gabe-commit` invocation that runs CHECK 7 normally.

### Step 8: Record to ledger

Append to `.kdbp/LEDGER.md`:
```
## [date] [time] — PUSH [branch] -> [target]
PR: [url]
CI: [all passed | N failed | skipped | no CI]
PROMOTION: [promoted to X | skipped | N/A]
DEPLOYMENTS: P[N]  (added row to .kdbp/DEPLOYMENTS.md)
```

### Step 9: Suggest /gabe-teach (if applicable)

If `.kdbp/KNOWLEDGE.md` exists, count rows with status `pending`:
- If pending count >= 2: show `ℹ [N] pending topics in KNOWLEDGE.md. Run /gabe-teach topics to review.`
- Otherwise: skip.

Non-blocking suggestion only. Push is already complete.

### Step 10: Auto-tick Push column in PLAN.md

Silent no-op on any mismatch. Only runs when ALL of the following are true:

1. Push succeeded (Step 4 reached without failure)
2. CI passed green (Step 6 ended with "All checks passed" — or CI provider is `none` and user confirmed)
3. Branch promotion reached the final link per PUSH.md, OR the PR was merged before running push

If any of those is false, skip this step. The Push column should only tick when the work is actually live on the target branch.

Follow the shared procedure documented in `/gabe-plan` under "Shared: auto-tick phase column":
- Target column: `Push`
- Preconditions: `.kdbp/PLAN.md` exists, contains `status: active`, has `## Current Phase`, and Phases table includes a `Push` column
- On mismatch or legacy Status-column format: exit silently
- On success, display: `✅ PLAN: Phase [N] push ticked` (one line)

If ticking Push completes all three columns (Review + Commit + Push = ✅) for the current phase, additionally display:
```
🎯 Phase [N] complete (all three gates passed).
   Run /gabe-plan update to advance to the next phase.
```

### Output examples

**All succeeds (most common):**
```
GABE PUSH: feature/add-auth -> main

PRE-FLIGHT: ✅ clean  ✅ ahead by 3 commits
PUSH: ✅ origin/feature/add-auth
PR: ✅ https://github.com/user/repo/pull/42
CI: ✅ lint  ✅ test  ✅ build (47s)

GABE PUSH COMPLETE
```

**Uncommitted changes:**
```
GABE PUSH: feature/add-auth -> main

PRE-FLIGHT: ⚠ 2 uncommitted files
  → [commit] run /gabe-commit first  [push-only] push what's committed  [abort] stop
```

**CI failure:**
```
GABE PUSH: feature/add-auth -> main

PRE-FLIGHT: ✅ clean  ✅ ahead by 1 commit
PUSH: ✅ origin/feature/add-auth
PR: ✅ https://github.com/user/repo/pull/43
CI: ✅ lint  ❌ test  ✅ build
  Failed: test
  → [details] [logs] [auto-fix] [assess] [ignore]
```

### Scope traceability (if SCOPE.md + ROADMAP.md exist)

When writing a DEPLOYMENTS.md row for this push, enrich with scope linkage:

1. Read PLAN.md `## Current Phase` → extract phase ID N.
2. Read ROADMAP.md phase N row → extract `Covers REQs`.
3. DEPLOYMENTS.md row gets extra columns: `Phase: {N}` and `REQs: {REQ-01, REQ-02, ...}`.
4. If CI passes AND the current phase's Exit criteria were satisfied in this push, propose marking Phase {N} as `complete` in ROADMAP.md — but route the write through `/gabe-scope-change` (never write ROADMAP.md directly from gabe-push).

Prompt at end:

```
Phase {N} Covers REQs appear satisfied by this deployment.
Mark phase complete?
  [y] Run /gabe-scope-change "mark phase {N} complete"
  [n] Leave roadmap alone (will surface again next push)
```

$ARGUMENTS
