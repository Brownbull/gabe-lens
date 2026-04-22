---
name: gabe-commit
description: "Commit quality gate — deterministic checks, interactive triage, defer/accept/fix per finding. Also retroactive `docs-audit` mode for accumulated documentation drift. Usage: /gabe-commit [commit message] | /gabe-commit docs-audit"
---

# Gabe Commit

Deterministic commit quality gate. Runs checks, shows findings, lets you act on each one. Most actions cost zero tokens — LLM involvement is explicit and opt-in.

> **Rendering note.** Output templates in this spec wrapped in bare triple-backtick fences (without a language tag) are **spec-meta delimiters**, not runtime code blocks. Render their contents as plain markdown at runtime — markdown tables render as tables, not as monospace code. Tagged fences (```bash, ```json, etc.) and ```mermaid fences ARE runtime code blocks, keep them fenced. See `gabe-docs/SKILL.md` § "Runtime output rendering convention" for the decision rule.

## Procedure

### Step 0: Subcommand dispatch

Parse `$ARGUMENTS`:

- If `$ARGUMENTS` starts with `docs-audit` → jump to **Step A: Docs-Audit Mode** (at end of this file). Skip Steps 1-6.
- Otherwise → treat `$ARGUMENTS` as commit message, proceed to Step 1 (normal commit flow).

The `docs-audit` subcommand is explicit only — NOT automatically chained. It's for retroactive catch-up on accumulated drift that per-diff CHECK 7 missed. Read-only git operations; any file changes it proposes remain unstaged for the human to `/gabe-commit` normally.

### Step 1: Validate context

1. Check that there are staged changes or unstaged changes to commit
2. If no commit message in `$ARGUMENTS`, generate one following the **Commit message body structure** section below
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

Three layers, all deterministic:

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

**Layer 3 — Gravity-well docs drift** (active only when `.kdbp/KNOWLEDGE.md` has a Gravity Wells table with at least one row whose Docs column is non-empty):
- Read wells table from `.kdbp/KNOWLEDGE.md`
- For each changed file in `git diff --staged --name-only`:
  - For each well row where `Paths` is non-empty AND `Docs` is non-empty:
    - Parse comma-separated Paths globs
    - If any glob matches the changed file:
      - Check if the well's Docs path appears in the staged diff
      - If Docs NOT in diff → create finding `low` with text: `Well [G_N] [Name] touched ([matched path]), [Docs path] not updated`
- Deduplicate: one finding per unique Docs target (keep highest-severity match, but Layer 3 is always `low`)
- Severity is deterministically `low` (decision 4b — won't block MVP commits; docs lag is the norm during active development)
- Skip this layer entirely when:
  - No wells have both Paths AND Docs populated (nothing to check against)
  - Diff is ONLY the Docs files themselves (don't flag a doc update as missing doc update)

**CHECK 8 — Structure** (requires `.kdbp/STRUCTURE.md`)

Deterministic path-pattern check for new files. Zero LLM cost. Skipped if `.kdbp/STRUCTURE.md` missing.

1. Get new files only: `git diff --staged --name-only --diff-filter=A`
2. Read `.kdbp/STRUCTURE.md`, parse:
   - Allowed Patterns table — each row has a glob pattern + maturity tier
   - Disallowed Patterns table — each row has a glob pattern + reason
3. For each new file path:
   - If it matches a Disallowed pattern → finding `critical`, text `Disallowed location: [pattern] — [reason]`
   - If it matches an Allowed pattern at or below current maturity (from BEHAVIOR.md) → pass, no finding
   - If it matches NO pattern → finding `medium`, text `No structural pattern matches [path]. Intended location?`

Tier rules:
- maturity mvp → only MVP-tagged patterns are active (E and S count as "no match")
- maturity enterprise → MVP + E patterns active
- maturity scale → all patterns active

Action set for Structure findings:
- `move` — suggest 3 nearest-match allowed patterns by edit distance, user picks one, apply `git mv`, re-stage
- `update-structure` — add the path (or a generalized glob) as a new allowed pattern in STRUCTURE.md with a chosen tier; re-run CHECK 8 to confirm
- `accept` — commit with warning, append one row to STRUCTURE.md Exceptions Log
- `defer` — add to PENDING.md as source=`gabe-commit`, priority=medium

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
| Doc drift (Layer 3 wells Docs) | Well's Docs file in diff | `low` (always) |
| Structure (disallowed pattern) | N/A (always fail) | `critical` |
| Structure (no pattern match) | Match at/below current maturity | `medium` |

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
| **Doc drift** | `update-docs` | Reads diff + target doc section, suggests minimal edit. **Consults `gabe-docs/SKILL.md` per-doc-type diagram policy:** if target matches a doc-type row (wells, AGENTS_USE.md, architecture.md, architecture-patterns.md) AND the doc's mapped section has no diagram yet AND the diff introduces a flow / state / multi-hop journey → proposes a diagram alongside the prose edit. Diagram type per matrix; skeleton per SKILL.md syntax templates; reach for `diagrams-library.md` only if ≥3 layers/actors. | Yes | tokens |
| | `accept` | Acknowledges drift, commits without doc update | No | 0 |
| | `defer` | Adds to PENDING.md at detected priority | No | 0 |
| **Structure** | `move` | Suggests nearest-match patterns, `git mv` to chosen, re-stage | No | 0 |
| | `update-structure` | Adds path/glob as allowed pattern in STRUCTURE.md | No | 0 |
| | `accept` | Appends to Exceptions Log, commits | No | 0 |
| | `defer` | Adds to PENDING.md | No | 0 |

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

6. **Auto-tick Commit column in PLAN.md** (silent no-op on any mismatch). Only runs when the `git commit` in step 6.2 returned 0.
   - Follow the shared procedure documented in `/gabe-plan` under "Shared: auto-tick phase column"
   - Target column: `Commit`
   - Preconditions: `.kdbp/PLAN.md` exists, contains `status: active`, has a `## Current Phase` section, and Phases table includes a `Commit` column
   - On mismatch or legacy Status-column format: exit silently
   - On success, display: `✅ PLAN: Phase [N] commit ticked` (one line, non-blocking)

### Maturity-Driven Check Selection

| Check | MVP | Enterprise | Scale |
|-------|-----|------------|-------|
| Lint | ✅ | ✅ | ✅ |
| Types | ✅ | ✅ | ✅ |
| Tests | ✅ | ✅ | ✅ |
| Coverage | skip | ✅ | ✅ |
| Shape | skip | ✅ (30 files) | ✅ (20 files) |
| Deferred | HIGH+ only | MEDIUM+ | All |
| Doc Drift | safe cards + wells Layer 3 | safe cards + DOCS.md + wells Layer 3 | safe cards + DOCS.md + wells Layer 3 |
| Structure | MVP patterns | MVP + E patterns | All patterns |

---

## Step A: Docs-Audit Mode (subcommand `docs-audit`)

Retroactive tree-wide audit against `.kdbp/DOCS.md` + wells' `Docs` paths. Runs only when invoked explicitly via `/gabe-commit docs-audit`. Skips Steps 1-6 entirely — no diff, no commit, no tests. Read-only git; any proposed file changes remain unstaged.

**Preconditions:**

- `.kdbp/` directory exists. If not → print `⚠ No .kdbp/ — run /gabe-init first.` and exit.
- At least ONE of: `.kdbp/DOCS.md` has non-skip mappings OR `.kdbp/KNOWLEDGE.md` Gravity Wells table has ≥1 well with a non-empty `Docs` column. If neither → print `ℹ Nothing to audit against. Populate DOCS.md mappings or run /gabe-teach init-wells with Docs paths.` and exit.

### Step A1: Gather universe

1. Source files: `git ls-files` (respects .gitignore, excludes untracked)
2. Tracked doc files: files under `docs/**/*.md` and `README.md` at project root
3. DOCS.md mappings: parse `.kdbp/DOCS.md` mapping table, filter out rows where `Doc Target` is `skip`, collect `(Source Pattern, Doc Target, Section, Priority)` tuples
4. Well Docs paths: parse `.kdbp/KNOWLEDGE.md` Gravity Wells table, collect rows where `Paths` AND `Docs` are both non-empty

### Step A2: DOCS.md audit

For each mapping `(pattern, target, section, priority)`:

1. **Mapped source files exist?** Glob `pattern` against `git ls-files` output. If 0 matches → skip this mapping (nothing to document against).
2. **Target file exists?** If `target` doesn't exist on disk → finding `Doc target missing: {target} (mapped from {pattern}, {N} source files)`, severity = `priority`.
3. **Target section exists + non-empty?** If `section` is non-empty, extract content between `## {section}` and next heading (or EOF):
   - No `## {section}` heading found → finding `Doc section missing: {target}#{section} (mapped from {pattern})`, severity = `priority`.
   - Section found but <80 non-comment/non-whitespace chars → finding `Doc section empty: {target}#{section} ({N} source files mapped)`, severity = `priority`.
   - Otherwise → no finding for this step (diagram coverage still checked in step 4).
4. **Diagram coverage (per-doc-type matrix).** Only runs when step 3 passed (section populated ≥80 chars). Consult `gabe-docs/SKILL.md` "Per-doc-type diagram policy" matrix using `target` basename:
   - `docs/AGENTS_USE.md` — diagram required when `section` is `Agent Design` (flowchart) or when any module file matching `pattern` uses tool-call adapters (sequenceDiagram). Severity: `medium`.
   - `docs/architecture.md` — diagram required when `section` is `Data Model` (erDiagram), `API Endpoints` (sequenceDiagram), or the section contains >200 chars of prose describing a flow (flowchart). Severity: `medium`.
   - `docs/architecture-patterns.md` — diagram required per pattern entry when the entry describes a flow / state / structural split (not pure rationale). Severity: `low`.
   - All other `target` paths → no diagram check (out of scope for A2; wells covered by A3).

   Detection: parse the section content for a `` ```mermaid `` fence. If no fence AND the target+section row above requires a diagram per matrix → finding `Doc section populated but diagram missing: {target}#{section} (matrix requires [flowchart|sequenceDiagram|erDiagram])`, severity per row above. Actions: `[add-diagram] [skip] [defer]`.

   If a fence exists, stub-check via `gabe-docs/SKILL.md` stub-detection heuristic. If stub → finding `Doc section diagram is placeholder: {target}#{section}`, severity `low`. Actions: `[upgrade-diagram] [skip] [defer]`.

### Step A3: Well Docs audit

For each well with non-empty `Paths` AND non-empty `Docs`:

1. **Docs file exists?** If not → finding `Well doc missing: {Docs} (well {G_N} {name})`, severity = `low`.
2. **`## Topics (auto-appended)` section present?** If missing → finding `Missing ## Topics (auto-appended) section: {Docs} (teach Step 4d.1 can't append)`, severity = `medium`.
3. **Purpose still placeholder AND ≥3 verified topics?** Count `### T[N] —` headings under `## Topics (auto-appended)`. Count non-comment/non-whitespace chars in `## Purpose` section. If topics ≥3 AND Purpose <80 chars → finding `Well Purpose empty despite {N} verified topics: {Docs}`, severity = `low` (info: teach Step 4d.4 will offer to draft next time).
4. **Diagram still placeholder despite ≥2 verified topics?** Parse `## Key Diagrams` section. Apply stub detection per `gabe-docs/SKILL.md` "Upgrade detection heuristic" (signals a-d: `TODO` literal, `[Start]`/`[End]` scaffolder labels, ≤2 node count, <60 chars body). If stub detected AND verified-topic count ≥2 → finding `Well [G_N] {name} diagram still placeholder despite {M} verified topics: {Docs}`, severity = `low`. Actions: `[upgrade-diagram] [skip] [defer]`. Handler: see Step A7.

### Step A4: Orphaned doc detection

List all `.md` files under `docs/` (recursive). Subtract:

- Files mapped in DOCS.md (Doc Target column, dedup)
- Files in any well's Docs column
- Whitelist: `README.md` at docs root, `CHANGELOG.md`, `CONTRIBUTING.md`, `LICENSE.md`

Remaining files → finding `Orphaned doc: {path} (not in DOCS.md mappings, not tracked by any well)`, severity = `low`.

### Step A5: Source-coverage gap detection

For each tracked source file, check if it matches ANY DOCS.md Source Pattern (including `skip` rows — those are intentional excludes) OR ANY well's Paths glob.

Files matching NOTHING, excluding standard skip patterns (`tests/**`, `.kdbp/**`, `node_modules/**`, `__pycache__/**`, `.git/**`, `*.pyc`, `*.lock`, binary files) → finding `Uncovered by DOCS.md or wells: {path}`, severity = `low`.

Cap at 10 findings — if more exist, emit `… and {N} more uncovered files` as an info line at the end of this section. Prevents spam on brand-new projects with no mappings yet.

### Step A6: Render audit report + interactive triage

```
GABE COMMIT — docs-audit

Universe: [N source files] | [N doc files] | [N wells] | [N DOCS.md mappings]

| # | Sev    | Finding                                                              | Actions                               |
|---|--------|----------------------------------------------------------------------|---------------------------------------|
| 1 | high   | Doc target missing: docs/architecture.md#Data Model (4 mapped)       | [create] [skip] [defer]               |
| 2 | medium | Doc section empty: docs/AGENTS_USE.md#Prompts (3 mapped, 42 chars)   | [update-docs] [skip] [defer]          |
| 3 | medium | Missing ## Topics section: docs/wells/2-llm-pipeline.md              | [insert-heading] [skip] [defer]       |
| 4 | low    | Orphaned doc: docs/legacy/old-routing.md                             | [archive] [map] [skip]                |
| 5 | low    | Well Purpose empty despite 4 verified topics: docs/wells/3-api.md    | [defer-to-teach] [skip]               |
| 6 | low    | Well G2 LLM Pipeline diagram still placeholder (3 verified topics)   | [upgrade-diagram] [skip] [defer]      |
| 7 | medium | Doc section populated but diagram missing: docs/AGENTS_USE.md#Agent Design (matrix requires flowchart) | [add-diagram] [skip] [defer]          |

ℹ … and 3 more uncovered files. Run with `full` flag to see all.

→ Actions? (e.g., "1:create 2:update-docs 3:insert-heading") or "all:defer":
```

### Step A7: Action handlers

Execute each user action in order:

| Finding Type | Action | Behavior | LLM? |
|---|---|---|---|
| Doc target missing | `create` | Write new file with `# {filename-derived}` H1 + required `## {Section}` subheadings from all DOCS.md mappings pointing at this target + the standards marker `<!-- Standards: see ~/.claude/skills/gabe-docs/SKILL.md -->`. Leave section bodies as HTML-comment placeholders identical to `/gabe-init` doc stubs. | No |
| | `skip` | One-time dismissal (session-scoped) | No |
| | `defer` | Append row to PENDING.md: `{today} \| docs-audit \| Create {target} \| {target} \| large \| {priority} \| high \| 0 \| open` | No |
| Doc section missing | `create-section` (new action) | Append `## {Section}\n\n<!-- TODO: populate from DOCS.md mapping {pattern} -->\n` to the target file | No |
| | `skip` / `defer` | as above | No |
| Doc section empty | `update-docs` | Invoke the existing per-diff `update-docs` triage action but scoped to (a) the specific section and (b) recent commits that touched source files mapped to this section. Seeds from `git log --oneline -10 -- {glob from mapping}` and the current file content of the section. LLM edits proposed, human confirms. | **Yes** |
| | `skip` / `defer` | as above | No |
| Missing ## Topics heading | `insert-heading` | Append `\n## Topics (auto-appended)\n\n<!-- /gabe-teach topics appends verified topic summaries here on first run. -->\n<!-- Do not edit the structure below this line; edit individual entries freely. -->\n` to end of well doc | No |
| | `skip` / `defer` | as above | No |
| Orphaned doc | `archive` | `mkdir -p docs/archive` then `git mv {path} docs/archive/{today}-{basename}` (unstaged) | No |
| | `map` | Interactive prompt: `Source Pattern for {path}? (e.g., app/legacy/**)` then `Priority? [critical/high/medium/low]` then append row to DOCS.md mapping table: `\| {pattern} \| {path} \| - \| {priority} \|` | No |
| | `skip` | One-time dismissal | No |
| Well Purpose empty | `defer-to-teach` | Print `ℹ docs/wells/{N}-{slug}.md: Purpose will be drafted on next /gabe-teach topics session (Step 4d.4 freshness prompt fires at ≥3 verified topics).` | No |
| | `skip` | One-time dismissal | No |
| Diagram placeholder (well-level, A3) | `upgrade-diagram` | Read well's verified topics from KNOWLEDGE.md Topics table + `## Purpose` + `## Key Decisions` from the well doc. Determine diagram type from per-well recommendation table in `gabe-docs/SKILL.md` (not re-decided — respect scaffold intent). Generate diagram body per gabe-docs upgrade rules (≤10 nodes, intent-labeled, analogy-consistent). Consult `gabe-docs/diagrams-library.md` if the well covers ≥3 layers or needs subgraph grouping. Replace stub fence content. LLM edits proposed, human confirms before write. | **Yes** |
| | `skip` / `defer` | as above | No |
| Diagram missing (non-well doc, A2 step 4) | `add-diagram` | Read `section` content + source files matching `pattern` (via `git log --oneline -10 -- {pattern-glob}` + file reads). Determine diagram type from per-doc-type matrix in `gabe-docs/SKILL.md` (matrix row dictates the type). Generate diagram body per SKILL.md skeletons (≤10 nodes, intent-labeled). Consult `diagrams-library.md` only if ≥3 layers/actors. Insert a new mermaid fence at end of `section`, before the next heading. LLM edits proposed, human confirms before write. | **Yes** |
| | `skip` / `defer` | as above | No |
| Diagram stub (non-well doc, A2 step 4) | `upgrade-diagram` | Same handler as well-level upgrade above, but seeds from mapped source files + section prose (no KNOWLEDGE.md topic lookup for non-well targets). Respects matrix-dictated type. | **Yes** |
| | `skip` / `defer` | as above | No |
| Uncovered source file | `map` | Same interactive prompt as orphaned-doc `map` but target defaults to a DOCS.md row with appropriate doc (prompt for doc + section too). Writes to DOCS.md. | No |
| | `skip` | One-time dismissal | No |

**Important constraints:**

- `create`, `create-section`, `insert-heading`, `archive`, `map` all leave changes UNSTAGED. The human runs `/gabe-commit` normally afterwards to stage + commit what they want.
- `update-docs` uses the existing per-diff triage action (see Step 5 triage table row "Doc drift"). In audit mode, the action accepts an explicit `section` scope parameter so the LLM only edits between `## {Section}` and the next heading.
- `defer` writes to PENDING.md; source column recorded as `docs-audit` so the human can filter later.
- No automatic chaining to Step 1. Audit is a dead-end: it reports, triages, and exits. Human decides when to commit the proposed changes.

### Step A8: Log to LEDGER.md

Always (even if no actions taken):

```
## {YYYY-MM-DD HH:MM} — docs-audit
UNIVERSE: {N} files, {N} docs, {N} wells, {N} mappings
FINDINGS: {total} ({critical_count} critical, {high_count} high, {medium_count} medium, {low_count} low)
ACTIONS: {1:create 2:update-docs 3:insert-heading 4:archive 5:skip}
DEFERRED: {count} (→ PENDING.md)
```

### Step A9: Closing summary

```
✅ docs-audit complete.
   {N} findings triaged.
   {M} files modified (unstaged — run /gabe-commit to stage + commit).
   {K} items deferred to PENDING.md.
```

If `{M} > 0`, print: `→ Next: run /gabe-commit "docs(audit): apply accumulated doc-drift fixes" to commit.`

---

## Commit message body structure

Commit messages generated by this command (or by `/gabe-execute` which delegates here) follow this body template:

```
<type>(<scope>): <subject>

<gabe-lens brief: 1-2 sentences — what changed + how it maps, plain language>

Before:
<3-6 line snippet or structured description of prior behavior>

After:
<3-6 line snippet or structured description of new behavior>

<optional footer — one of:>
Phase: N — [phase name]
Task: T[i]/[K] — [task description]
```

### Generation rules

**Subject**

- Conventional commit format: `type(scope): imperative`
- `type` ∈ {feat, fix, refactor, chore, docs, test, perf, ci, build}
- `scope` = topmost touched module or well (e.g., `triage`, `pipeline`, `docs`)
- Subject ≤72 chars, imperative mood, no trailing period

**Gabe-lens brief**

- 1-2 sentences, plain language, explains the *why* + *how it maps*
- Use analogy style from `gabe-lens` skill only when the change is **conceptual** (introduces a new pattern, abstraction, or architectural shift)
- Skip analogy for **mechanical** changes (renames, moves, typo fixes, dependency bumps, formatting)

**Before / After**

- **Required** for all commits touching source code (`app/`, `src/`, `lib/`, etc.)
- **Skipped** for pure doc/config/dependency commits (those get subject + gabe-lens brief only)
- Format options:
  - Code snippet: 3-6 lines of actual or pseudo-code showing behavior delta
  - Structured description: one-line prose each, side-by-side meaning contrast
- Do not paste the whole diff — that's what `git show` is for. Distill the *behavior change*.

**Phase/Task footer**

- Appended automatically when `.kdbp/PLAN.md` has an active plan and Current Phase is set
- Source: the `ℹ PLAN: ...` context line from Step 1b (Current Phase number + name)
- If commit is made via `/gabe-execute`, the Task line is also appended
- If no active plan: omit the footer entirely

### Model routing

Per U6 (Route by Task, Not by User):

| Commit kind | Model | Reason |
|-------------|-------|--------|
| Rename/move/typo/format/dep-bump | Haiku | Mechanical — cheap summarization |
| Bug fix with clear diff | Haiku | Narrow scope, low-ambiguity before/after |
| New feature / refactor / new abstraction | Sonnet | Needs analogy + architectural framing |
| Docs changes | Haiku | Summarization |

Classify via heuristic first (file patterns, diff size, conventional type). Only invoke LLM for subject + body generation once type is known.

### Example — conceptual change (Sonnet)

```
feat(triage): wire PydanticAI agent with 4-tier fallback chain

Triage now enforces output shape mechanically via PydanticAI's output_type
rather than trusting the LLM to return valid JSON. A 4-tier fallback
(regex extract → rule-based → safe default) guarantees the pipeline
never crashes and never returns empty.

Before:
  result = triage_incident(title, desc)
  # rule-based keyword matching; returns None on mismatch

After:
  result = await run_triage(title, desc)
  # PydanticAI Agent(output_type=TriageResult, retries=2)
  # on exhaustion: regex-extract → rule-based → P3 safe default
  # tier fired logged via structlog tier=1|2|3|4

Phase: 2 — PydanticAI Agent
Task: T2/6 — New app/agent/triage_agent.py with Agent + fallback wrapper
```

### Example — mechanical change (Haiku)

```
refactor(triage): rename classify_incident → classify_severity

Clearer naming — function only sets severity, not full classification.

Before:
  def classify_incident(incident: Incident) -> Severity:

After:
  def classify_severity(incident: Incident) -> Severity:

Phase: 4 — Wire into pipeline
Task: T1/2 — Rename for clarity before pipeline integration
```

### Example — dep bump (Haiku, no before/after)

```
chore(deps): pin pydantic-ai to 0.0.14

Lock version to avoid breaking changes until tested.

Phase: 2 — PydanticAI Agent
Task: T3/6 — Add pydantic-ai to pyproject.toml
```

### Override

User can pass a pre-written message via `$ARGUMENTS`. In that case:

- Subject is used as-is
- Body enrichment is skipped (user owns the message)
- Phase/Task footer is still appended if plan is active (opt-out: `$ARGUMENTS` ending with `--no-footer`)

### Scope-edit audit (if SCOPE.md or ROADMAP.md in diff)

When a commit modifies `.kdbp/SCOPE.md` or `.kdbp/ROADMAP.md` directly:

1. **Bypass warning.** Surface before proceeding:
   ```
   ⚠ Direct SCOPE.md / ROADMAP.md edit detected.

   These files should change only through /gabe-scope-change (which routes to
   /gabe-scope-addition or /gabe-scope-pivot with classifier + Change Log).

   Direct edits skip the classifier, Change Log entry, and version bump.

   Options:
     [c] Continue anyway (records commit with scope_bypass audit tag)
     [r] Revert changes + use /gabe-scope-change
     [a] Abort commit
   ```
2. **Exception:** If the commit author also changed `.kdbp/CHANGES.jsonl` in the same diff with a matching `scope_addition` or `scope_pivot` row, assume the edit was made via the proper command path and skip the warning.
3. **Audit footer.** If user continues, append `Scope-Bypass-Audit: true` line to commit footer for later grep.

No behavior change for non-scope files.

$ARGUMENTS
