---
name: gabe-commit
description: "Commit quality gate — deterministic checks, interactive triage, defer/accept/fix per finding. Usage: /gabe-commit [commit message]"
---

# Gabe Commit

Deterministic commit quality gate. Runs checks, shows findings, lets you act on each one. Most actions cost zero tokens — LLM involvement is explicit and opt-in.

## Procedure

### Step 1: Validate context

1. Check that there are staged changes or unstaged changes to commit
2. If no commit message in $ARGUMENTS, generate one from `git diff --staged` (conventional commit format)
3. Read `.kdbp/BEHAVIOR.md` for `maturity` field (defaults to `mvp` if missing)

### Step 1b: Surface active plan (context only, no check)

If `.kdbp/PLAN.md` exists and contains `status: active`:
- Read the `## Current Phase` section
- Display as info line in Step 4 output: `ℹ PLAN: [goal] — Phase [N]: [name]`
- This is informational context, not a blocking check. Zero cost.

### Step 2: Run deterministic checks

Run these scripts. No LLM. No token cost. Target: 2-10 seconds total.

**CHECK 1 — Lint**
- Python: `ruff check app/ --output-format=json 2>/dev/null`
- TypeScript: `bunx biome check src/ --reporter=json 2>/dev/null`
- Skip if tool not found

**CHECK 2 — Types**
- Python: `mypy app/ --no-error-summary 2>/dev/null`
- TypeScript: `tsc --noEmit 2>/dev/null` or `bunx tsc --noEmit 2>/dev/null`
- Skip if tool not found

**CHECK 3 — Tests**
- Python: `pytest tests/ -x --tb=line -q 2>/dev/null`
- TypeScript: `bun test 2>/dev/null`
- Skip if no test directory found

**CHECK 4 — Coverage** (enterprise + scale maturity only)
- On changed source files only, threshold 80%
- Skip at mvp maturity

**CHECK 5 — Shape** (active only when >30 source files AND >2000 lines total)
- File sizes: >400 (low), >600 (medium), >800 (high)
- New files <20 lines (low)
- Skip below activation threshold

**CHECK 6 — Deferred**
- Read `.kdbp/PENDING.md`
- Flag open items whose `File` column matches any changed file
- Use item's existing priority

**CHECK 7 — Doc Drift** (requires `.kdbp/` directory)

Two layers, both deterministic:

**Layer 1 — Universal safe cards** (always active when `.kdbp/` exists, no config needed):
- `.env.example` OR `config.py` changed AND `README.md` NOT in diff → flag README.md (`low`)
- `pyproject.toml` OR `package.json` dependency section changed AND `README.md` NOT in diff → flag README.md (`low`)
- `docker-compose.yml` changed AND `README.md` NOT in diff → flag README.md (`low`)
- New `@app.get` / `@app.post` / `@router` decorator added AND no file in `docs/` in diff → flag docs/ (`medium`)

**Layer 2 — DOCS.md pattern matching** (active only when `.kdbp/DOCS.md` exists):
- Read `.kdbp/DOCS.md` mapping table
- For each changed file in `git diff --staged --name-only`:
  - Match against Source Pattern column (glob match)
  - If pattern matches AND Doc Target is NOT `skip`:
    - Check if Doc Target file appears in the staged diff
    - If Doc Target NOT in diff → create finding at pattern's Priority
- Deduplicate: one finding per unique Doc Target (use highest priority among matches)

### Step 3: Assign severity

Deterministic thresholds, not LLM judgment:

| Check | Pass | Severity |
|-------|------|----------|
| Lint errors | 0 errors | `critical` (errors) / `low` (warnings only) |
| Type errors | 0 errors | `high` |
| Test failures | All pass | `critical` |
| Coverage <80% on changed file | >=80% | `medium` (50-79%) / `high` (<50%) |
| File >800 lines | <=800 | `high` |
| File >600 lines | <=600 | `medium` |
| File >400 lines | <=400 | `low` |
| New file <20 lines | >=20 | `low` |
| Open deferred on changed file | None | item's priority |
| Doc drift (universal safe card) | Doc target in diff | `low` (config/deps/docker) / `medium` (new routes) |
| Doc drift (DOCS.md critical) | Doc target in diff | `critical` |
| Doc drift (DOCS.md high) | Doc target in diff | `high` |
| Doc drift (DOCS.md medium) | Doc target in diff | `medium` |
| Doc drift (DOCS.md low) | Doc target in diff | `low` |

### Step 4: Present results

**If ALL PASS** (most common case):
```
GABE COMMIT: feat: update triage prompt

CHECKS: ✅ lint  ✅ types  ✅ tests (84/84)  ✅ coverage  ✅ shape  ✅ docs
No findings. Committing...
[main abc1234] feat: update triage prompt
```
Stage all changes, commit, done.

**If findings exist but no CRITICAL:**
```
GABE COMMIT: feat: add classification pipeline stage

CHECKS: ✅ lint  ✅ types  ✅ tests (84/84)  ⚠ coverage  ⚠ shape  ⚠ docs

| # | Sev    | Finding                              | Actions                              |
|---|--------|--------------------------------------|--------------------------------------|
| 1 | medium | Coverage: classify.py at 62% (<80%)  | [write-test] [accept] [defer]        |
| 2 | low    | New file: route.py (23 lines)        | [merge:classify.py] [keep] [defer]   |
| 3 | low    | D2 open on agent.py (you changed it) | [resolve-now] [skip] [defer]         |
| 4 | medium | Docs: README.md may need update (config.py changed) | [update-docs] [accept] [defer] |

→ Actions? (e.g., "1:defer 2:keep 3:skip") or "all:commit" to defer all:
```

**If CRITICAL findings:**
```
GABE COMMIT: ❌ BLOCKED — 1 critical finding

CHECKS: ✅ lint  ❌ tests  ✅ types  ✅ docs

| # | Sev      | Finding                              | Actions                |
|---|----------|--------------------------------------|------------------------|
| 1 | critical | test_triage.py::test_classify FAILED | [fix] [skip-to-pending]|

Fix critical findings before committing.
```

### Step 5: Execute actions

| Finding Type | Action | What Happens | LLM? | Cost |
|-------------|--------|-------------|-------|------|
| **Lint error** | `auto-fix` | Runs `ruff --fix` / `biome --fix` | No | 0 |
| | `accept` | Commit with warning | No | 0 |
| **Type error** | `fix` | Shows error, suggests fix | Yes | tokens |
| | `suppress` | Adds `# type: ignore` | No | 0 |
| | `defer` | Adds to PENDING.md as HIGH | No | 0 |
| **Test failure** | `fix` | Shows output, helps debug | Yes | tokens |
| | `skip-to-pending` | Adds to PENDING.md as CRITICAL | No | 0 |
| **Coverage gap** | `write-test` | Generates test for uncovered code | Yes | tokens |
| | `accept` | Won't re-flag this file at this level | No | 0 |
| | `defer` | Adds to PENDING.md at detected severity | No | 0 |
| **File too large** | `extract` | Identifies + extracts concerns | Yes | tokens |
| | `accept` | Won't flag until next threshold | No | 0 |
| | `defer` | Adds to PENDING.md | No | 0 |
| **Small new file** | `merge:file` | Merges into suggested file | Yes | tokens |
| | `keep` | File stays separate | No | 0 |
| | `defer` | Adds to PENDING.md | No | 0 |
| **Open deferred** | `resolve-now` | Shows item, helps fix | Yes | tokens |
| | `skip` | Leaves open, no re-prompt this commit | No | 0 |
| | `escalate` | Bumps priority +1 level | No | 0 |
| **Doc drift** | `update-docs` | Reads diff + target doc section, suggests minimal edit | Yes | tokens |
| | `accept` | Acknowledges drift, commits without doc update | No | 0 |
| | `defer` | Adds to PENDING.md at detected priority | No | 0 |

### Step 6: Commit + record

After all actions resolved:

1. Stage changes: `git add` the relevant files
2. Commit: `git commit -m "[message]"`
3. Append to `.kdbp/LEDGER.md`:
```
## 2026-04-14 09:30 — [abc1234] feat: add classification pipeline stage
FINDINGS: 2 (0 critical, 1 medium, 1 low)
ACTIONS: 1:defer 2:keep
DEFERRED: +D8 (coverage classify.py)
```

4. If any items deferred, update `.kdbp/PENDING.md`:
   - Add new row with date, source=`gabe-commit`, finding, file, scale (from BEHAVIOR.md maturity), priority, impact, times_deferred=1, status=open
   - If item already exists in PENDING.md, increment `Times Deferred`
   - If `Times Deferred` reaches 3, auto-escalate priority one level

5. If `.kdbp/KNOWLEDGE.md` exists, suggest `/gabe-teach` when the commit likely introduces new topics. Heuristic (deterministic, zero cost):
   - Commit message starts with `feat:` or `refactor:` → suggest
   - Commit added new file(s) in a new folder → suggest
   - Commit modified `.kdbp/DECISIONS.md` → suggest
   - Otherwise: skip suggestion
   - Message: `ℹ New topics likely introduced. Run /gabe-teach topics to consolidate understanding.`

### Maturity-Driven Check Selection

| Check | MVP | Enterprise | Scale |
|-------|-----|------------|-------|
| Lint | ✅ | ✅ | ✅ |
| Types | ✅ | ✅ | ✅ |
| Tests | ✅ | ✅ | ✅ |
| Coverage | skip | ✅ | ✅ |
| Shape | skip | ✅ (30 files) | ✅ (20 files) |
| Deferred | HIGH+ only | MEDIUM+ | All |
| Doc Drift | safe cards only | safe cards + DOCS.md | safe cards + DOCS.md |

$ARGUMENTS
