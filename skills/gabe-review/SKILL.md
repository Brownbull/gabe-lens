---
name: gabe-review
description: "Code review with risk pricing, confidence scoring, interactive triage, and deferred item tracking. Surfaces the cost of NOT fixing each finding. Usage: /gabe-review [target] or /gabe-review deferred"
metadata:
  version: 1.3.0
---

# Gabe Review — Code Review with Risk Pricing

## Purpose

Review code changes and price every finding — what it costs to fix now, what it costs to ignore, and what you're betting by deferring. Track deferred items across reviews and escalate when the same gap gets kicked down the road.

This is NOT a generic checklist review. Every finding gets a **Defer Risk** (consequence + probability) and a **Maturity Gate** (MVP/Enterprise/Scale). The output is a risk matrix with a **Review Confidence Score** that lets humans make informed ship/defer decisions — and an interactive **Triage** loop to resolve findings on the spot.

---

## When to Use

**Use when:**
- You're about to open a PR and want to understand what you're shipping
- A code review (CE:review, BMad, manual) approved with deferred items and you want to price the risk
- You want to see all accumulated deferred items and their escalation status
- You need to decide between "fix now" and "defer" with real risk information
- You want to fix findings interactively without leaving the review context (`/gabe-review fix`)

**Don't use when:**
- You need deep multi-persona review (use CE:review or BMad code-review first, then /gabe-review post-review)
- You're assessing a proposed change before implementing (use /gabe-assess)
- You're looking for structural gaps in design (use /gabe-roast)

---

## Required Inputs

### 1. Target — What to review

| Input Type | Example |
|---|---|
| **Diff** | `git diff`, `git diff --staged`, PR diff (default: staged + unstaged changes) |
| **File(s)** | `/src/services/rateLimiter.ts` |
| **Folder** | `/functions/src/` |
| **Post-review** | Output from CE:review or BMad code-review (parses their findings and adds risk pricing) |
| **Deferred** | No target — shows only the deferred items dashboard |

If no target is provided, default to `git diff HEAD` (all uncommitted changes).

### 2. Maturity — What standard to apply

| Maturity | What it means | Default severity threshold |
|---|---|---|
| **MVP** | Prototype/early product — fix security and data loss, accept rough edges | Only CRITICAL blocks merge |
| **Enterprise** | Production with users — fix performance, error handling, monitoring | CRITICAL + HIGH block merge |
| **Scale** | Large-scale operations — fix optimization, edge cases, polish | CRITICAL + HIGH + MEDIUM block merge |

**How maturity is determined (in order):**
1. Explicit argument: `/gabe-review --maturity enterprise`
2. Read from `.kdbp/BEHAVIOR.md` maturity field (if project has `.kdbp/`)
3. Ask the user
4. Default: MVP (conservative — strictness goes up, not down)

Never auto-detect from test count or CI presence. Maturity is a human decision.

---

## Review Process

### Step 0.5: Load KDBP Context (if available)

If `.kdbp/LEDGER.md` exists, read the last 5 checkpoint entries. For each:
- If a value was CONCERN on a file that's in the current diff → note it as prior signal
- If a scenario was ❌ on a file that's in the current diff → pre-seed as expected finding

This means gabe-review knows what the automatic checkpoints already flagged. Prior signals add a `FLAGGED (Nx)` annotation to the finding (where N = number of checkpoint flags). If flagged 3+ times, bump severity by one tier (LOW→MEDIUM, MEDIUM→HIGH, HIGH→CRITICAL). Do not bump findings already at CRITICAL.

If no `.kdbp/LEDGER.md` exists, skip this step silently.

### Step 1: Load Deferred Backlog

Before reviewing new code, check for existing deferred items:

1. Look for `.kdbp/PENDING.md` (preferred), `.kdbp/deferred-cr.md`, or `.planning/deferred-cr.md`
2. If found, load all entries with `Status != Resolved`
3. For each deferred item, check if the current diff addresses it:
   - **Match by file path** (exact match)
   - If file matches, compare Finding text with >50% word overlap
   - If file was renamed (detected via `git diff --find-renames`), match on Finding text alone with >70% overlap
4. If addressed: mark as `Resolved` in the file (use Edit tool to update the table row)
5. If NOT addressed and the diff touches the same function or within 20 lines of the finding's original location: increment `Times Deferred` and apply escalation rules. Changes elsewhere in the same file do NOT trigger escalation.

### Step 2: Review the Diff

For each changed file, check these dimensions:

| Dimension | What to find | Default severity |
|---|---|---|
| **Security** | Injection, auth bypass, secrets, OWASP Top 10 | CRITICAL |
| **Data integrity** | Data loss, corruption, race conditions, missing validation | CRITICAL |
| **Error handling** | Unhandled exceptions, fail-open without test, swallowed errors | HIGH |
| **Test coverage** | New branches without corresponding test changes | HIGH |
| **Logic** | Off-by-one, null handling, wrong condition, unreachable code | HIGH |
| **Performance** | N+1 queries, unbounded loops, missing indexes, memory leaks | MEDIUM |
| **Style** | Naming, formatting, dead code, console.log in production | LOW |

**Confidence gate:** Only report findings with >80% confidence. If uncertain, investigate further before reporting.

### Step 3: Branch-Test Gap Detection

For each modified source file:

1. Check if it introduces new error handling (`try/catch`, `if (error)`, fallback logic, `.catch(`)
2. Check if a corresponding test was also modified in the diff. Look for:
   - `[filename].test.[ext]` or `[filename].spec.[ext]` (direct match)
   - Test files in `e2e/`, `__tests__/`, `tests/` that import or reference the modified source module
   - Any test file in the diff that exercises the new branch (check import statements)
3. If new branches exist without test coverage:

```
⚠️ TEST GAP: [file] adds [branch type] at L[line] — no test exercises this path.
   Defer Risk: UNTESTED PRODUCTION PATH — P(high), Impact(high)
```

### Step 3.5: Churn Annotation

For each file in the diff, check its recent churn:

```bash
git log --oneline --since=30.days --follow -- [file] | wc -l
```

| Churn (30d) | Label | Meaning |
|---|---|---|
| 8+ commits | 🔴 HOT | Fragile — changes constantly, defer risk amplified |
| 4-7 commits | ⚠️ WARM | Active area — watch for coupling |
| 0-3 commits | ✅ STABLE | Low risk of cascading issues |

The churn label appears in the findings table. A finding on a HOT file has higher effective risk than the same finding on a STABLE file — "untested path on a file that breaks every sprint" is worse than "untested path on a file nobody touches."

### Step 4: Price Each Finding

Every finding gets these fields:

| Field | Description |
|---|---|
| **#** | Sequential number |
| **Severity** | CRITICAL / HIGH / MEDIUM / LOW |
| **Finding** | One-line description |
| **File** | `file:line` |
| **Churn** | 🔴 HOT / ⚠️ WARM / ✅ STABLE (from Step 3.5) |
| **Fix Cost** | T-shirt estimate: S (<30m), M (1-3h), L (3-8h), XL (>1d) |
| **Defer Risk** | `[CONSEQUENCE] — P([probability]), Impact([severity])` |
| **Maturity Gate** | MVP / Enterprise / Scale — when this finding becomes relevant |
| **Escalation** | Empty for new findings, `⚠️ RECURRING (Nth time)` for deferred items |

### Defer Risk Scales

**Probability** (how likely the bad outcome is):

| Level | Meaning |
|---|---|
| certain | Will happen in normal usage |
| high | Likely under common conditions |
| medium | Possible under specific conditions |
| low | Unlikely but plausible |
| negligible | Theoretical only |

**Impact** (how bad when it happens):

| Level | Meaning |
|---|---|
| catastrophic | Data loss, security breach, complete failure |
| high | Major feature broken, user trust eroded |
| moderate | Degraded experience, workaround exists |
| low | Minor friction, cosmetic |
| negligible | Barely noticeable |

**Risk score for sorting:** Rank by probability first, then impact within same probability. In the Risk Dashboard, highest risk items appear first.

### Step 4.5: Review Confidence Score

After pricing all findings, compute a **Review Confidence Score** (0–100). This tells the user: "how confident should you feel shipping this code as-is?"

#### Scoring Formula

Start at **100**. Deduct per finding:

| Severity | Base deduction | HOT churn | ESCALATED (2+) |
|----------|---------------|-----------|-----------------|
| CRITICAL | −20 | ×1.5 | ×1.5 |
| HIGH | −12 | ×1.3 | ×1.3 |
| MEDIUM | −5 | ×1.2 | — |
| LOW | −2 | — | — |

Multipliers stack: a CRITICAL finding on a HOT file that's ESCALATED = −20 × 1.5 × 1.5 = −45.

**Coverage confidence modifier** (from existing coverage assessment):

| Coverage | Modifier |
|----------|----------|
| HIGH | 0 |
| MEDIUM | −5 |
| LOW | −10 |
| VERY LOW | −15 |

**Floor: 0. Ceiling: 100.**

#### Confidence Projections

After the score, show what happens if the user fixes findings at each tier. Each projection removes the deductions from findings that match the criteria:

| Projection | Which findings are removed from the score |
|---|---|
| **Fix CRITICAL + HIGH** | All findings with severity CRITICAL or HIGH |
| **Fix all MVP gate** | All findings with Maturity Gate = MVP |
| **Fix all Enterprise gate** | All findings with Maturity Gate = MVP or Enterprise |
| **Fix all (including Scale)** | All findings (score → 100 minus coverage modifier) |

**Multiplier handling:** Projections remove the full multiplied deduction of each matching finding (including churn and escalation multipliers), not just the base severity deduction.

#### Output Format

```
### Review Confidence

Score: 62 / 100

| If you fix... | Findings resolved | Projected | Δ |
|---------------|-------------------|-----------|---|
| All CRITICAL + HIGH | 4 of 9 | 78 / 100 | +16 |
| All MVP gate | 5 of 9 | 85 / 100 | +23 |
| All Enterprise gate | 7 of 9 | 95 / 100 | +33 |
| All (incl. Scale) | 9 of 9 | 100 / 100* | +38 |

*Assumes HIGH coverage (modifier = 0). Actual ceiling: 100 minus coverage modifier.
```

**Interpretation guide:**

| Score range | Signal | Recommendation |
|-------------|--------|----------------|
| 90–100 | Ship with confidence | Minor items can be deferred safely |
| 70–89 | Ship with awareness | Review the projections — a small fix effort may buy a lot of confidence |
| 50–69 | Caution | Significant risk exposure. Check which tier gives the best ROI |
| 0–49 | Do not ship | Critical gaps. Fix at minimum the CRITICAL + HIGH tier before proceeding |

The confidence score appears BEFORE the verdict — it informs the verdict but doesn't replace it.

### Step 4.75: Plan Alignment (NEW — Phase 2/6 of doc-lifecycle work)

Before triage, run plan-compliance + stale-topic checks. Both are deterministic (zero LLM). The block only renders in **full mode** — skipped in `brief`, `deferred`, `fix`, `post-review` modes to keep those paths tight.

**Skip conditions (silent exit):**

- `.kdbp/` doesn't exist
- `.kdbp/PLAN.md` doesn't exist OR doesn't contain `status: active`
- Current diff is empty (nothing to align against)

#### Sub-check 5a — Phase Compliance

Purpose: "Does this diff accomplish what the current plan phase says it should?"

Procedure (deterministic):

1. Read `.kdbp/PLAN.md`. Extract `## Current Phase` section → phase number N + phase name.
2. Extract phase row N from `## Phases` table → `Description` column.
3. Extract `## Scope` section if present → explicit file list.
4. Build **expected change set** from:
   - Files named in Scope (exact paths)
   - Files matching globs mentioned in Description (keyword extraction — folder names, file suffixes, component names)
5. Compare against `git diff --name-only HEAD`:
   - On-scope files changed: count + list
   - Off-scope files changed: count + list (cap at 5)
   - Scope files NOT touched: count + list (cap at 5)
6. Classify alignment:

| Alignment | Condition |
|-----------|-----------|
| `ALIGNED` | All changed files are on-scope, no off-scope changes |
| `DRIFTED` | ≥70% of changed files on-scope, some off-scope |
| `MISALIGNED` | <70% of changed files on-scope (majority drift) |
| `SKIP` | Diff empty or Scope section missing (no basis for comparison) |

7. Render output block:

```
### Plan Alignment

Goal:         [Plan Goal from PLAN.md]
Phase [N/M]:  [name] — [description, truncated 120 chars]

Alignment: DRIFTED
  On-scope files changed:    3 / 7
  Off-scope files changed:   2 (frontend/src/lib/api.ts, docs/wells/3-api.md)
  Scope files not touched:   4 (tests/test_guardrails.py, app/db/models.py, ...)

Suggestion: this diff mixes plan scope with unrelated changes.
Consider `git reset` + split the commit, or update PLAN.md scope via /gabe-plan.
```

Informational only — no auto-action. Does NOT write to PLAN.md.

#### Sub-check 5c — Stale Verified Topic Detection

Purpose: "Are verified KNOWLEDGE.md topics now stale because the code they reference changed?"

Skip silently if `.kdbp/KNOWLEDGE.md` doesn't exist OR has no verified topics.

Procedure (deterministic, no LLM):

1. Read `.kdbp/KNOWLEDGE.md`. Parse Gravity Wells table → `{well_id: paths_globs}`. Parse Topics table → collect rows with `Status: verified`.
2. For each verified topic:
   - Extract `Well` column → look up well's Paths globs.
   - Extract `Source` column → if it contains a commit hash (7-40 hex chars), keep it; else skip.
   - For each changed file in `git diff --name-only HEAD`:
     - Does the file match any of the well's Paths globs? (fnmatch with `**` recursive support)
     - If yes: run `git log --follow -1 --format=%H -- <file>` → get most recent commit on this file.
     - If that commit is LATER than the topic's `Source` commit (via `git merge-base --is-ancestor topic_source file_latest`) → mark topic as **stale candidate**.
3. If stale candidates found, render output block:

```
### Stale Topic Candidates

Topics whose verified material may no longer match the code:

  T1 — Why guardrails run before the LLM (well G1, verified 2026-04-15)
       Changed since verification: app/agent/guardrails.py
  T5 — Why 202 Accepted + BackgroundTask (well G3, verified 2026-04-10)
       Changed since verification: app/api/main.py, app/api/tasks.py

  [mark-stale]  Flag these topics `stale` in KNOWLEDGE.md (re-surface in /gabe-teach)
  [skip]        Ignore this session
```

On `mark-stale`:

- Use Edit tool on `.kdbp/KNOWLEDGE.md` Topics table.
- For each stale candidate row: find the row by `# T[N]` prefix, replace `verified` in the Status column with `stale`. Preserve all other columns (Tags, ArchConcepts, Last Touched, Verified Date, Score, Source) exactly.
- Idempotent: re-running on already-`stale` rows is a no-op.
- This is the ONE place review writes KNOWLEDGE.md. Surface narrow (status column only). No row creation, no deletion, no topic text change.

On `skip`: no write. Stale candidates re-surface next `/gabe-review` until addressed.

#### Sub-check 5b — Architectural Decision Detection (Phase 3/6)

Purpose: "Did significant architectural decisions happen in this diff that should be captured in DECISIONS.md?"

**Trigger layer** (zero-cost, always runs; fires when ≥1 hits):

A diff is flagged as "potentially architectural" when ANY of these conditions hold:

| Trigger | Signal |
|---------|--------|
| New top-level folder | `git diff --name-only HEAD` shows a new path whose first segment didn't exist in HEAD~1 |
| Dependency churn | ≥2 of: `pyproject.toml dependencies section`, `package.json dependencies/devDependencies`, `Gemfile`, `go.mod require block` show non-whitespace changes |
| Config/routes/schemas | Changes a file matching `**/config*.{py,ts,yaml}`, `**/{routes,models,schemas,entities}/**`, `**/__init__.py` at a package root, `docker-compose*.yml`, `alembic/env.py` |
| Well-concentrated large change | Modifies files matching exactly one well's `Paths` globs AND diff is >50 lines total |
| Architectural commit prefix | Commit subject starts with `feat:`, `refactor:`, or `breaking:` AND touches ≥1 file mapped at `critical` or `high` in `.kdbp/DOCS.md` |
| Explicit ADR marker | Diff introduces a new `# Decision:` or `# ADR:` comment in any source file (grep signal) |

**Classifier layer** (LLM, cheap model, fires only when trigger hits):

Precondition: trigger hit AND no row in `.kdbp/DOCS.md` references any file in the diff by exact path (dedup — avoid re-proposing the same decision).

- **Model:** Haiku-tier (cheap; per user value U6 — route by task)
- **Context:** commit subject + body, top 10 changed files with line deltas, the trigger reason(s) from the trigger layer, the last 5 rows of DECISIONS.md (dedup awareness)
- **Max tokens:** 200
- **Structured output** (PydanticAI `output_type` or equivalent — user value U4):
  ```
  ArchitecturalDecisionCandidate:
    is_architectural: bool       # false → drop, no proposal
    title: str                   # one-line, <80 chars
    rationale: str               # 2-3 sentences
    alternatives: list[str]      # 0-2 alternatives considered
    review_trigger: str          # when to revisit (e.g., "when we add 3rd integration")
  ```
- If `is_architectural == false`: drop silently, no proposal rendered.

**Dedup + caps:**

- Max ONE candidate per review run. If multiple triggers hit, the classifier picks the strongest.
- Session-scoped dedup: if user picks `drop` on a candidate this session, do not re-propose the same title.
- If the classifier's proposed `title` case-insensitively matches any existing DECISIONS.md row: drop silently.

**Output block** (renders inside the Plan Alignment section, below 5c if both fired):

```
### Architectural Decision Candidate

  Detected: [trigger reason]
  Proposed DECISIONS.md entry:

    Date:           2026-04-17
    Decision:       [title]
    Rationale:      [rationale]
    Alternatives:   [alt 1]
                    [alt 2]
    Status:         active
    Review Trigger: [review_trigger]

  [accept]  Append to .kdbp/DECISIONS.md as D[next_id]
  [edit]    Revise fields before writing
  [defer]   Add reminder to PENDING.md (source=gabe-review)
  [drop]    Don't write (one-time dismissal this session)
```

**Action handlers:**

| Action | Behavior |
|--------|----------|
| `accept` | Read DECISIONS.md → compute next `D[N]` (max existing + 1) → append row with today's date, title, rationale, alternatives joined by `<br>`, `active` status, review_trigger. Use Edit tool to append before the closing fence if DECISIONS uses a frontmatter fence, else append at EOF. |
| `edit` | Show each field inline-editable (prompt per field, default = proposed value). On confirm, proceed to `accept`. |
| `defer` | Append to PENDING.md: `\| today \| gabe-review \| Propose DECISIONS entry: [title] \| - \| small \| medium \| low \| 0 \| open`. Source column = `gabe-review`. |
| `drop` | No write. Session-scoped dedup set to this title (same title won't re-propose this run). |

**Race handling:** DECISIONS.md may be appended by `/gabe-push` too (starting in Phase 5). Dedup is by title case-insensitive match. If two writers race on `D[N]` computation, Edit tool's match-and-replace will fail on one of them — the losing writer retries with fresh read.

#### Plan Alignment summary block

If 5a produced output OR 5c produced output OR 5b produced a candidate, wrap in a single "Plan Alignment" block under Step 4.75's heading. Order: 5a, 5c, 5b. If all three are empty, skip the block entirely (don't render an empty heading).

### Step 5: Triage

After the verdict and session estimate, present the triage prompt. This closes the gap between "here's what's wrong" and "let's fix it."

#### Entry Point — Bulk Matrix Menu

Replaces the old binary "Enter triage? [Y/n]" with a severity × scale matrix plus seven clearly-bounded options. Every option is explicit about **both** the fix set and the remainder behavior, so the user is never surprised by what happened to findings they didn't explicitly address.

**Matrix display:**

```
### Triage — [N] findings across [M] files

Severity × Maturity Gate:

| Severity     | MVP | Enterprise | Scale | Total |
|--------------|-----|------------|-------|-------|
| CRITICAL     | [n] | [n]        | [n]   | [n]   |
| HIGH         | [n] | [n]        | [n]   | [n]   |
| MEDIUM       | [n] | [n]        | [n]   | [n]   |
| LOW          | [n] | [n]        | [n]   | [n]   |

Project maturity: [MVP|Enterprise|Scale] (from .kdbp/BEHAVIOR.md)
```

Counts come deterministically from the Findings table already produced in Step 4. No recomputation.

**Seven options, each with explicit fix set AND remainder behavior:**

```
Bulk options:

  [1] Fix MVP items only
      Fix:          [n_mvp] findings (MVP gate, any severity)
      Defer:        [n_ent+n_scale] findings (Enterprise + Scale) → PENDING.md
      Confidence:   [current] → [projected] (+[delta])

  [2] Fix MVP + Enterprise items
      Fix:          [n_mvp+n_ent] findings (MVP + Enterprise gates)
      Defer:        [n_scale] findings (Scale gate) → PENDING.md
      Confidence:   [current] → [projected] (+[delta])

  [3] Fix all including Scale
      Fix:          [total] findings (everything)
      Defer:        none
      Confidence:   [current] → [projected] (+[delta])

  [4] Fix CRITICAL + HIGH only (severity-based, ignores gate)
      Fix:          [n_crit+n_high] findings (CRITICAL + HIGH, any gate)
      Defer:        [n_med+n_low] findings (MEDIUM + LOW) → PENDING.md
      Confidence:   [current] → [projected] (+[delta])

  [5] Defer Scale, triage the rest one-by-one
      Defer now:    [n_scale] findings (Scale gate) → PENDING.md
      Then enter:   one-by-one for remaining [total-n_scale] (MVP + Enterprise)

  [6] One-by-one (per-finding prompt)
      Enter:        per-finding loop for all [total] findings
      Each gets:    f / d / x / s / a / e decision

  [7] Skip triage
      Defer:        all [total] findings → PENDING.md
      Fix:          none

★ Recommended for [project maturity]: [default option]

Pick [1-7] or type `custom` for a mixed expression (e.g. "fix 1-3, defer 4-6, dismiss 7"):
```

**Starred default (by project maturity, not by project name):**

| Project maturity | Recommended option |
|------------------|--------------------|
| MVP | [1] Fix MVP items only |
| Enterprise | [2] Fix MVP + Enterprise items |
| Scale | [3] Fix all including Scale |

If no `.kdbp/BEHAVIOR.md` exists or maturity is unset, star [1] as the conservative default.

#### Bulk Option Guardrails

Before executing any bulk option, apply these two guardrails:

**1. CRITICAL findings are always in the fix set.**

If the chosen option would leave a CRITICAL unresolved (e.g., user picks [1] but a CRITICAL has Enterprise gate), show this warning and adjust:

```
⚠ Option [1] would defer [N] CRITICAL finding(s). CRITICALs cannot be deferred.
  Adjusted fix set:  [N+n_mvp] findings ([n_mvp] MVP + [N] CRITICAL forced)
  Adjusted defer:    [rest]
  Proceed? [Y/n]
```

If the user confirms, execute with the adjusted sets. If they decline, return to the menu.

**2. Dismiss is never a bulk action.**

All remainders from bulk options go to **defer** (PENDING.md, re-surfaces on next review). Dismiss is session-only and requires per-finding justification — only available in per-finding mode (options [5], [6], custom).

#### Custom Expression

User types a mixed expression:

```
fix 1-3, defer 4-6, dismiss 7
fix 1,3,5 defer 2,4
fix all-critical, defer all-scale, one-by-one rest
```

Parse rules:
- `fix N` / `fix N-M` / `fix N,M,P` — add to fix set
- `defer N` / `defer N-M` — add to defer set (PENDING.md)
- `dismiss N` — requires asking for justification per item
- `skip N` — leave un-triaged (prompted at end)
- `one-by-one N` or `one-by-one rest` — route specific items (or everything else) to the per-finding loop
- Shortcuts: `all-critical`, `all-high`, `all-mvp`, `all-enterprise`, `all-scale`, `rest`
- Unresolved items at the end of the expression → auto-defer with a confirmation prompt

Apply the same two guardrails (CRITICAL-always-fixed, dismiss-needs-justification).

#### One-by-one Loop (options [5] remainder, [6], or custom `one-by-one`)

Present findings **grouped by file** (not by severity), because fixes in the same file batch naturally. Within each file group, order by severity (CRITICAL first).

For each finding, show a compact card:

```
[1/5] HIGH — Missing fail-open test | rateLimiter.ts:88 | Fix: S (<30m)
      Defer Risk: SILENT FAILURE — P(medium), I(high)

  (f) Fix now    (d) Defer    (x) Dismiss    (s) Skip    (a) Fix all remaining    (e) Explain
```

#### Actions

| Action | What happens |
|--------|-------------|
| **f — Fix now** | Claude applies the fix immediately. For code changes: edit the file, show the diff. For test gaps: write the test. For doc issues: update the doc. After fix, re-validate and mark resolved. |
| **d — Defer** | Ask for optional justification. Write to `.kdbp/PENDING.md` (or `deferred-cr.md` if PENDING.md doesn't exist) with current date, finding details, source=`gabe-review`, and Times Deferred = 1 (or increment if recurring). Move to next finding. |
| **x — Dismiss** | Ask for one-line reason. Record dismissal in the review output (not in deferred backlog). Move to next finding. Dismissals don't persist across reviews — they're session-only decisions. |
| **s — Skip** | Leave in the findings table without deciding. At end of triage, un-skipped items get a final "defer or dismiss?" prompt. |
| **a — Fix all** | Apply fixes for all remaining findings in sequence without per-finding prompts. Show a summary diff at the end. Useful when the user trusts the fixes and wants to batch them. |
| **e — Explain** | Invoke the `gabe-lens` skill to generate an analogy for the finding + expose trade-offs. Returns to this same prompt after explaining — doesn't advance. See "Explain behavior" below. |

#### Explain Behavior (`e`)

When the user picks `e`, Claude:

1. **Invokes the `gabe-lens` skill** with the finding details (severity, file:line, description, defer risk, maturity gate) as context
2. **Produces 4 sections** — short, concrete, no filler:
   - **ANALOGY:** physical or spatial metaphor for what's broken and why it matters (2-4 lines)
   - **WHY IT MATTERS:** bullets on what the finding actually buys the project (2-3 bullets)
   - **IF YOU FIX:** concrete outcome + confidence delta
   - **IF YOU DEFER:** concrete failure mode + when it bites
3. **Re-prompts the same action menu** — user can then pick f / d / x / s / a. Does NOT advance to the next finding on its own.

Example:

```
[2/9] HIGH — Missing fail-open test | rateLimiter.ts:88 | Fix: S (<30m)
      Defer Risk: SILENT FAILURE — P(medium), I(high)

> e

ANALOGY: Like a circuit breaker with no test that it actually trips. The code says
"if upstream fails, fail open (allow requests)". That's a reasonable policy — but
nothing exercises it. Six months later someone refactors, the fail-open silently
becomes fail-closed, and production drops 10% of traffic during partial outages
until someone notices in a dashboard.

WHY IT MATTERS:
  - Without the test, you can't know if the behavior is intentional
  - The fix is <30m (one test)
  - Deferring means the next refactor could silently flip the behavior

IF YOU FIX:  Confidence +12. Permanent guardrail on rate-limiter behavior.
IF YOU DEFER: Finding escalates on next review if rate-limiter is touched again.

  (f) Fix   (d) Defer   (x) Dismiss   (s) Skip   (a) Fix all

>
```

Keep analogies concrete. Avoid "this is like a house" handwaving — use the specific domain of the finding (timing, locking, data flow, UI state) so the analogy teaches something transferable.

#### Fix Behavior

When the user picks **Fix now**, Claude should:

1. **Read the file** at the finding's location (if not already in context)
2. **Apply the minimal fix** — same constraints as normal editing (no scope creep, no bonus refactoring)
3. **Show the diff** — so the user can see what changed
4. **Re-validate** — check if the fix actually resolves the finding (e.g., does the test now exist? is the validation present?)
5. **Report result**: `Fixed: [finding summary] — [file:line]` or `Partial fix: [what remains]`

For findings that can't be auto-fixed (e.g., "needs architectural decision", "requires external input"):
```
This finding needs manual resolution: [reason].
Suggested approach: [one-liner]
(d) Defer    (x) Dismiss
```

#### Fix All Behavior

When the user picks **(a) Fix all remaining**, Claude:

1. Groups remaining findings by file (reduces file re-reads)
2. Applies fixes in severity order within each file (CRITICAL first)
3. After all fixes, shows a single batched summary:
   ```
   Applied 4 fixes across 3 files:
   - rateLimiter.ts: #2 fail-open test, #3 error handling
   - vault-protocol.md: #1 schema count, #5 working type rules
   ```
4. Any finding that couldn't be auto-fixed is collected at the end:
   ```
   1 finding requires manual resolution:
   - #4 concurrency model — needs architectural decision
   (d) Defer    (x) Dismiss
   ```

#### Triage Summary and Score Update

After all findings are processed, show a compact summary **with updated confidence score**:

```
### Triage Complete

| Action | Count | Findings |
|--------|-------|----------|
| Fixed | 3 | #1 schema drift, #2 working type lifecycle, #5 quick capture fields |
| Deferred | 1 | #3 signal log granularity → PENDING.md |
| Dismissed | 1 | #4 concurrency model — "single-agent MVP, revisit at Scale" |

Review Confidence: 62 → 87 / 100 (+25)

### Final Verdict

[APPROVE|WARNING|BLOCK] — [reason, incorporating triage outcomes]

Deferred items written to .kdbp/PENDING.md
```

The post-triage score recalculates: **fixed** findings are fully removed from the deduction, **dismissed** findings count at **50%** of their original multiplied deduction (acknowledged but unresolved risk), and **deferred** findings count at full deduction. The Final Verdict replaces the Provisional Verdict using the updated score and remaining finding state.

#### CRITICAL Finding Constraint

CRITICAL findings during triage **cannot be deferred**. The `(d)` option is disabled:

```
[2/5] CRITICAL — SQL injection via unsanitized input | api.ts:44 | Fix: S (<30m)
      Defer Risk: DATA BREACH — P(high), I(catastrophic)

  (f) Fix now    (x) Dismiss (requires justification)    (s) Skip for now    (a) Fix all remaining
```

#### Edge Cases

| Situation | Behavior |
|-----------|----------|
| All findings are LOW and below maturity gate | Still offer triage, but default prompt is "All findings below MVP gate. Defer all? [Y/n]" |
| User exits mid-triage (Ctrl+C, context limit) | Persist any already-deferred items. Un-triaged findings are NOT auto-deferred — they remain in the session output only. |
| Fix introduces a new issue | Don't re-review during triage. The fix-then-review loop is for the next `/gabe-review` run. |
| Finding references a file not in the workspace | Can't auto-fix. Offer defer/dismiss only. |
| Skipped CRITICAL at end of triage | CRITICALs cannot be deferred. At the final sweep, present only **(f) Fix now** or **(x) Dismiss (requires justification)**. If the user skips again, auto-classify as Dismissed with note: "No resolution chosen — treated as acknowledged risk." |

### Step 6: Auto-tick Review column in PLAN.md

After triage completes (Final Verdict produced), tick the Review column of the current phase if the review passed. Silent no-op on any mismatch.

**Pass condition for Review column:**
- Final Verdict is APPROVE or WARNING (not BLOCK)
- No unresolved CRITICAL findings (deferred = OK; deferred CRITICAL cannot exist per guardrail)
- No unresolved HIGH findings ABOVE the maturity gate (deferred = OK)
- **Step 4.75 Sub-check 5a did NOT return `MISALIGNED`** (added Phase 2/6 of doc-lifecycle work — a MISALIGNED diff shouldn't auto-advance the phase just because code review passed). `ALIGNED`, `DRIFTED`, and `SKIP` all satisfy this condition. If MISALIGNED, silently skip the tick and log `ℹ PLAN: phase tick skipped (diff MISALIGNED with current phase scope)` to the output.

Follow the shared procedure documented in `/gabe-plan` under "Shared: auto-tick phase column":
- Target column: `Review`
- Preconditions: `.kdbp/PLAN.md` exists, contains `status: active`, has `## Current Phase`, and Phases table includes a `Review` column
- On mismatch or legacy Status-column format: exit silently
- On success, display: `✅ PLAN: Phase [N] review ticked` (one line at the end of output)

If the pass condition is not met (BLOCK verdict or unresolved issues above gate), do NOT tick — but do not emit a warning either. The user knows they blocked.

---

## Output Format

### Full Mode (default)

```markdown
## Gabe Review — Review Summary

**Maturity:** [MVP|Enterprise|Scale] | **Files:** N changed | **Deferred backlog:** N items

### Findings

| # | Severity | Finding | File | Churn | Fix Cost | Defer Risk | Gate | Escalation |
|---|----------|---------|------|-------|----------|------------|------|------------|
| 1 | CRITICAL | [description] | file:line | 🔴 HOT | S | [consequence] — P(x), I(y) | MVP | |
| 2 | HIGH | [description] | file:line | ✅ | M | [consequence] — P(x), I(y) | MVP | ⚠️ RECURRING (2nd) |
| ... | | | | | | | |

### Risk Dashboard (All Pending)

Items from this review + unresolved deferred backlog, ordered by risk:

| # | Source | Age | Finding | File | Defer Risk | Escalation |
|---|--------|-----|---------|------|------------|------------|
| D1 | [review name] | N days | [description] | file | [risk] | [status] |
| ... | | | | | | |

### Coverage Confidence

Before producing the verdict, assess coverage confidence:

| Condition | Coverage | Effect |
|---|---|---|
| All changed source files have corresponding test changes | HIGH | No cap |
| Some test gaps exist but none on error handling paths | MEDIUM | No cap |
| Test gaps exist on error handling / fail-open / fallback paths | LOW | Verdict capped at WARNING |
| Multiple untested branches on HOT files | VERY LOW | Verdict capped at BLOCK |

Format in output:
```
Coverage: LOW (2 untested error-handling branches) — verdict capped at WARNING
```

### Review Confidence

Score: [0-100] / 100

| If you fix... | Findings resolved | Projected | Δ |
|---------------|-------------------|-----------|---|
| All CRITICAL + HIGH | X of N | XX / 100 | +XX |
| All MVP gate | X of N | XX / 100 | +XX |
| All Enterprise gate | X of N | XX / 100 | +XX |
| All (incl. Scale) | N of N | XX / 100 | +XX |

### Verdict (Provisional)

[APPROVE|WARNING|BLOCK] — [reason]
*This verdict is based on findings as-is. Triage decisions below may change it.*

- APPROVE: No CRITICAL, no ESCALATED deferrals above maturity gate, coverage confidence ≥ MEDIUM, review confidence ≥ 70
- WARNING: HIGH findings within maturity tolerance, OR coverage confidence LOW (caps verdict), OR review confidence 50–69
- BLOCK: CRITICAL present, OR ESCALATED deferrals (2+ times), OR coverage VERY LOW, OR maturity gate exceeded, OR review confidence < 50

**Coverage vs confidence precedence:** The coverage verdict cap and confidence score are independent signals. When they conflict, the stricter result wins (e.g., coverage caps at WARNING but score < 50 → BLOCK).

### Session Estimate
Fixing [CRITICAL+HIGH]: ~Nh | Fixing all: ~Nh | Deferring [count]: risk exposure ≈ [summary]

### Triage

N findings to resolve. Enter triage? [Y/n]
```

**Verdict finalization:** The verdict shown before triage is PROVISIONAL. After triage completes, restate the **Final Verdict** incorporating triage outcomes (fixed items removed, dismissed at 50% weight, deferred at full weight). If the user declines triage, auto-defer findings above the maturity gate and restate the final verdict. If the user declines to track deferred items, the verdict cannot be APPROVE — downgrade to WARNING with note: "Deferred items not tracked — risk of invisible debt."

### Brief Mode (`/gabe-review brief`)

Only the findings table + headline confidence score + verdict. No projection table, no interpretation guide, no dashboard, no session estimate, no triage. Format: `Score: 62 / 100 | Verdict: WARNING — [reason]`. In brief mode the verdict is **final** (not provisional) since triage is not offered.

### Fix Mode (`/gabe-review fix`)

Runs the full review (Steps 0.5–4.5) then shows a compact pre-triage summary before auto-fixing:

```
Score: 48 / 100 (BLOCK) — 7 findings. Applying fixes...
```

Then enters triage with "(a) Fix all" pre-selected. Shows full triage summary with updated confidence score and Final Verdict at the end. For users who trust the review and just want everything patched.

### Deferred-Only Mode (`/gabe-review deferred`)

Shows the Risk Dashboard table with current confidence impact of deferred items. Offers triage:

```
### Deferred Backlog — N items

| # | Age | Finding | File | Defer Risk | Times Deferred | Confidence cost |
|---|-----|---------|------|------------|----------------|-----------------|
| D1 | 26d | Missing IP skip test | suggestRecipes.ts:31 | P(high), I(high) | 2 ⚠️ | −18 pts |
| D2 | 26d | Missing fail-open test | rateLimiter.ts:88 | P(medium), I(high) | 1 | −12 pts |
| ...

Total deferred confidence drag: −XX pts

Tackle deferred items? [Y/n]
```

If yes, enter the same triage loop with (f)/(d)/(x)/(s) options.

### Post-Review Mode (`/gabe-review post-review`)

Parse the most recent code review output in the conversation. Detect the source format and map findings:

| Source | Severity mapping |
|---|---|
| **CE:review** | P0→CRITICAL, P1→HIGH, P2→MEDIUM, P3→LOW |
| **BMad code-review** | decision_needed→HIGH, patch→by-dimension, defer→load into deferred backlog |
| **ECC code-reviewer** | CRITICAL→CRITICAL, HIGH→HIGH, MEDIUM→MEDIUM, LOW→LOW (same scale) |
| **Manual/unknown** | Infer from keywords (security→CRITICAL, performance→MEDIUM, style→LOW) |

Add Defer Risk + Maturity Gate + Confidence Score columns to each parsed finding. Present in the standard Gabe Review table format. After presenting findings, follow the full mode flow (confidence score with projections, provisional verdict, session estimate, triage).

---

## Deferred Item Persistence

Written to `.kdbp/PENDING.md` (preferred), `.kdbp/deferred-cr.md`, or `.planning/deferred-cr.md` (first found, or create `.kdbp/PENDING.md`).

File format:
```markdown
<!-- gabe-review:1.3 -->
# Deferred Code Review Items

| # | First Seen | Review | Finding | File | Defer Risk | Times Deferred | Status | Resolved |
|---|-----------|--------|---------|------|------------|----------------|--------|----------|
| D1 | 2026-03-10 | TD-2-9 | Missing IP skip test | suggestRecipes.ts:31 | UNTESTED PATH — P(high), I(high) | 2 | ⚠️ ESCALATED | |
| D2 | 2026-03-10 | TD-2-9 | Missing fail-open test | rateLimiter.ts:88 | SILENT FAILURE — P(medium), I(high) | 1 | Resolved | 2026-04-06 |
```

**Persistence protocol:** Use the Edit tool to update individual rows. Read the file → find the row by `#` → update Status, Times Deferred, and Resolved date → write back. If file doesn't exist, create it with the Write tool including the `<!-- gabe-review:1.3 -->` version header.

### Triage Persistence

When a finding is **fixed** during triage:
- If it existed in deferred backlog: mark `Status: Resolved` with today's date in the `Resolved` column
- Log which review resolved it

When a finding is **deferred** during triage:
- If new: add row with `Times Deferred: 1`, `Status: Deferred`
- If recurring: increment `Times Deferred`, apply escalation rules (existing logic)

When a finding is **dismissed** during triage:
- NOT written to deferred backlog (dismissals are session-only)
- Noted in the triage summary output but not persisted

### Escalation Rules

| Times Deferred | Status | Effect |
|---------------|--------|--------|
| 1 | Deferred | Shown in Risk Dashboard, no additional escalation multiplier on score |
| 2 | ⚠️ ESCALATED | Promoted to HIGH if was MEDIUM/LOW. Highlighted in findings. Confidence deduction uses ESCALATED multiplier. |
| 3+ | 🔴 BLOCKING | Treated as CRITICAL. Cannot approve until resolved or re-justified. |

**Re-justification:** When user explicitly provides NEW reasoning for why a deferral is acceptable (not just "defer again"), reset counter to 1 and append justification as a comment below the table row.

---

## Integration with Gabe Suite

| Situation | This tool suggests |
|-----------|-------------------|
| Finding has CRITICAL severity | Fix immediately, no deferral allowed |
| Finding has unclear blast radius | Run `/gabe-assess` on the finding before deciding |
| Multiple findings in same area | Run `/gabe-roast [perspective]` on that area |
| Alignment concern (wrong direction) | Run `/gabe-align shallow` to check values |
| Deferred item reaches 3+ deferrals | BLOCK. Suggest `/gabe-roast qa` for test coverage roast |
| KDBP checkpoint showed untested scenarios | Those scenarios become findings in gabe-review with severity HIGH |
| Review confidence < 50 | Suggest fixing CRITICAL+HIGH before proceeding. Show projection table. |
| Confidence jump ≥ 20 pts for a single tier | Highlight that tier as "best ROI" in the session estimate |
