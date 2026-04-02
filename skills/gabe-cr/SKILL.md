---
name: gabe-cr
description: "Code review with risk pricing, deferred item tracking, and maturity-appropriate severity. Surfaces the cost of NOT fixing each finding. Usage: /gabe-cr [target] or /gabe-cr deferred"
metadata:
  version: 1.0.0
---

# Gabe CR — Code Review with Risk Pricing

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
- You need deep multi-persona review (use CE:review or BMad code-review first, then /gabe-cr post-review)
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

If not provided, infer from project signals:
- Has CI/CD + monitoring + >50 tests → Enterprise
- Has load testing + feature flags + >200 tests → Scale
- Otherwise → MVP

---

## Review Process

### Step 1: Load Deferred Backlog

Before reviewing new code, check for existing deferred items:

1. Look for `.kdbp/deferred-cr.md` or `.planning/deferred-cr.md`
2. If found, load all entries with `Status != Resolved`
3. For each deferred item, check if the current diff addresses it (file + description match)
4. If addressed, mark as `Resolved` in the file
5. If NOT addressed and same file is in the diff, increment `Times Deferred` and apply escalation rules

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
2. Check if a corresponding `.test.` or `.spec.` file was also modified in the diff
3. If new branches exist without test changes:

```
⚠️ TEST GAP: [file] adds [branch type] at L[line] but [test file] was not modified.
   Defer Risk: UNTESTED PRODUCTION PATH — P(high), Impact(high)
```

### Step 4: Price Each Finding

Every finding gets:

| Field | Description |
|---|---|
| **#** | Sequential number |
| **Severity** | CRITICAL / HIGH / MEDIUM / LOW |
| **Finding** | One-line description |
| **File** | `file:line` |
| **Fix Cost** | T-shirt estimate: S (<30m), M (1-3h), L (3-8h), XL (>1d) |
| **Defer Risk** | `[CONSEQUENCE] — P([probability]), Impact([severity])` |
| **Maturity Gate** | MVP / Enterprise / Scale — when this finding becomes relevant |
| **Escalation** | Empty for new findings, `⚠️ RECURRING (Nth time)` for deferred items |

---

## Output Format

### Full Mode (default)

```markdown
## Gabe CR — Review Summary

**Maturity:** [MVP|Enterprise|Scale] | **Files:** N changed | **Deferred backlog:** N items

### Findings

| # | Severity | Finding | File | Fix Cost | Defer Risk | Gate | Escalation |
|---|----------|---------|------|----------|------------|------|------------|
| 1 | CRITICAL | [description] | file:line | S | [consequence] — P(x), Impact(y) | MVP | |
| 2 | HIGH | [description] | file:line | M | [consequence] — P(x), Impact(y) | MVP | ⚠️ RECURRING (2nd) |
| ... | | | | | | | |

### Risk Dashboard (All Pending)

Items from this review + unresolved deferred backlog, ordered by risk:

| # | Source | Age | Finding | File | Defer Risk | Escalation |
|---|--------|-----|---------|------|------------|------------|
| D1 | [review name] | N days | [description] | file | [risk] | [status] |
| ... | | | | | | |

### Verdict

[APPROVE|WARNING|BLOCK] — [reason]

- APPROVE: No CRITICAL, no ESCALATED deferrals above maturity gate
- WARNING: HIGH findings exist but within maturity tolerance
- BLOCK: CRITICAL present, or ESCALATED deferrals (2+ times), or maturity gate exceeded

### Session Estimate
Fixing [CRITICAL+HIGH]: ~Nh | Fixing all: ~Nh | Deferring [count]: risk exposure ≈ [summary]
```

### Brief Mode (`/gabe-cr brief`)

Only the findings table + verdict. No dashboard, no session estimate.

### Deferred-Only Mode (`/gabe-cr deferred`)

Only the Risk Dashboard table. No new review.

### Post-Review Mode (`/gabe-cr post-review`)

Parse the most recent code review output in the conversation (from CE:review, BMad, or manual review), extract findings, and add Defer Risk + Maturity Gate columns to each.

---

## Deferred Item File Format

Written to `.kdbp/deferred-cr.md` or `.planning/deferred-cr.md` (first found, or create `.kdbp/deferred-cr.md`):

```markdown
# Deferred Code Review Items

| # | First Seen | Review | Finding | File | Defer Risk | Times Deferred | Status |
|---|-----------|--------|---------|------|------------|----------------|--------|
| D1 | 2026-03-10 | TD-2-9 | Missing IP skip integration test | suggestRecipes.ts:31 | UNTESTED PATH — P(high) | 2 | ⚠️ ESCALATED |
| D2 | 2026-03-10 | TD-2-9 | Missing fail-open integration test | rateLimiter.ts:88 | SILENT FAILURE — P(medium) | 1 | Deferred |
```

### Escalation Rules

| Times Deferred | Status | Effect |
|---------------|--------|--------|
| 1 | Deferred | Shown in Risk Dashboard, no score impact |
| 2 | ⚠️ ESCALATED | Promoted to HIGH if was MEDIUM/LOW. Highlighted in findings. |
| 3+ | 🔴 BLOCKING | Treated as CRITICAL. Review cannot approve until resolved or re-justified with NEW rationale. |

When a deferred item is re-justified (user explicitly provides new reasoning for why deferral is acceptable), reset the counter to 1 and note the justification.

---

## Integration with Gabe Suite

| Situation | This tool suggests |
|-----------|-------------------|
| Finding has CRITICAL severity | Fix immediately, no deferral allowed |
| Finding has unclear blast radius | Run `/gabe-assess` on the finding before deciding to fix or defer |
| Multiple findings in same area | Run `/gabe-roast [perspective]` on that area for deeper analysis |
| Alignment concern (wrong direction, not wrong code) | Run `/gabe-align shadow` to check values |
| Deferred item reaches 3+ deferrals | BLOCK — require justification or fix. Suggest `/gabe-roast qa` for test coverage roast |
