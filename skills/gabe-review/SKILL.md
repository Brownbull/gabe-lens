---
name: gabe-review
description: "Code review with risk pricing, deferred item tracking, and maturity-appropriate severity. Surfaces the cost of NOT fixing each finding. Usage: /gabe-review [target] or /gabe-review deferred"
metadata:
  version: 1.1.0
---

# Gabe Review — Code Review with Risk Pricing

## Purpose

Review code changes and price every finding — what it costs to fix now, what it costs to ignore, and what you're betting by deferring. Track deferred items across reviews and escalate when the same gap gets kicked down the road.

This is NOT a generic checklist review. Every finding gets a **Defer Risk** (consequence + probability) and a **Maturity Gate** (MVP/Enterprise/Scale). The output is a risk matrix that lets humans make informed ship/defer decisions.

---

## When to Use

**Use when:**
- You're about to open a PR and want to understand what you're shipping
- A code review (CE:review, BMad, manual) approved with deferred items and you want to price the risk
- You want to see all accumulated deferred items and their escalation status
- You need to decide between "fix now" and "defer" with real risk information

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

### Step 1: Load Deferred Backlog

Before reviewing new code, check for existing deferred items:

1. Look for `.kdbp/deferred-cr.md` or `.planning/deferred-cr.md`
2. If found, load all entries with `Status != Resolved`
3. For each deferred item, check if the current diff addresses it:
   - **Match by file path** (exact match)
   - If file matches, compare Finding text with >50% word overlap
   - If file was renamed (detected via `git diff --find-renames`), match on Finding text alone with >70% overlap
4. If addressed: mark as `Resolved` in the file (use Edit tool to update the table row)
5. If NOT addressed and same file is in the diff: increment `Times Deferred` and apply escalation rules

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

### Verdict

[APPROVE|WARNING|BLOCK] — [reason]

- APPROVE: No CRITICAL, no ESCALATED deferrals above maturity gate, coverage confidence ≥ MEDIUM
- WARNING: HIGH findings within maturity tolerance, OR coverage confidence LOW (caps verdict)
- BLOCK: CRITICAL present, OR ESCALATED deferrals (2+ times), OR coverage VERY LOW, OR maturity gate exceeded

**Deferred items must be tracked before verdict:** If any findings are deferred during this review, write them to `deferred-cr.md` BEFORE producing the verdict. If the user declines to track deferred items, the verdict cannot be APPROVE — downgrade to WARNING with note: "Deferred items not tracked — risk of invisible debt."

### Session Estimate
Fixing [CRITICAL+HIGH]: ~Nh | Fixing all: ~Nh | Deferring [count]: risk exposure ≈ [summary]
```

### Brief Mode (`/gabe-review brief`)

Only the findings table + verdict. No dashboard, no session estimate.

### Deferred-Only Mode (`/gabe-review deferred`)

Only the Risk Dashboard table. No new review.

### Post-Review Mode (`/gabe-review post-review`)

Parse the most recent code review output in the conversation. Detect the source format and map findings:

| Source | Severity mapping |
|---|---|
| **CE:review** | P0→CRITICAL, P1→HIGH, P2→MEDIUM, P3→LOW |
| **BMad code-review** | decision_needed→HIGH, patch→by-dimension, defer→load into deferred backlog |
| **ECC code-reviewer** | CRITICAL→CRITICAL, HIGH→HIGH, MEDIUM→MEDIUM, LOW→LOW (same scale) |
| **Manual/unknown** | Infer from keywords (security→CRITICAL, performance→MEDIUM, style→LOW) |

Add Defer Risk + Maturity Gate columns to each parsed finding. Present in the standard Gabe Review table format.

---

## Deferred Item Persistence

Written to `.kdbp/deferred-cr.md` or `.planning/deferred-cr.md` (first found, or create `.kdbp/deferred-cr.md`).

File format:
```markdown
<!-- gabe-review:1.1 -->
# Deferred Code Review Items

| # | First Seen | Review | Finding | File | Defer Risk | Times Deferred | Status |
|---|-----------|--------|---------|------|------------|----------------|--------|
| D1 | 2026-03-10 | TD-2-9 | Missing IP skip test | suggestRecipes.ts:31 | UNTESTED PATH — P(high), I(high) | 2 | ⚠️ ESCALATED |
| D2 | 2026-03-10 | TD-2-9 | Missing fail-open test | rateLimiter.ts:88 | SILENT FAILURE — P(medium), I(high) | 1 | Deferred |
```

**Persistence protocol:** Use the Edit tool to update individual rows. Read the file → find the row by `#` → update Status and Times Deferred → write back. If file doesn't exist, create it with the Write tool including the `<!-- gabe-review:1.1 -->` version header.

### Escalation Rules

| Times Deferred | Status | Effect |
|---------------|--------|--------|
| 1 | Deferred | Shown in Risk Dashboard, no score impact |
| 2 | ⚠️ ESCALATED | Promoted to HIGH if was MEDIUM/LOW. Highlighted in findings. |
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
