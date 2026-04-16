---
name: gabe-push
description: "Push, create PR, watch CI, promote branches — the post-commit shipping workflow. Usage: /gabe-push"
---

# Gabe Push

The stupidest way to ship. Push, PR, watch CI, promote. First run auto-detects your setup; every run after that repeats the same flow.

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

### Step 8: Record to ledger

Append to `.kdbp/LEDGER.md`:
```
## [date] [time] — PUSH [branch] -> [target]
PR: [url]
CI: [all passed | N failed | skipped | no CI]
PROMOTION: [promoted to X | skipped | N/A]
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

$ARGUMENTS
