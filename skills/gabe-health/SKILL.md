---
name: gabe-health
description: "Codebase health analysis — god files, churn hotspots, coupling clusters, bug concentration, and scope creep vs plan. Run before epics, during retros, or when things feel fragile. Usage: /gabe-health [focus]"
metadata:
  version: 1.0.0
---

# Gabe Health — Codebase Health Analysis

## Purpose

Surface structural fragility in a codebase before it becomes an incident. Find the files that break every sprint, the modules that always change together, and the gaps between what was planned and what was actually touched.

This is NOT a code review (use /gabe-review). This is NOT a design critique (use /gabe-roast). This is the X-ray before the surgery — "where is this codebase structurally weak?"

---

## When to Use

**Use when:**
- Starting a new epic or milestone — know where the minefields are before walking in
- During retrospectives — "why did this sprint feel fragile?"
- After a production incident — "was this a one-off or is this area inherently unstable?"
- Before major refactoring — "which files should I split/stabilize first?"
- When things just feel fragile but you can't articulate why

**Don't use when:**
- Reviewing a specific diff (use /gabe-review)
- Looking for bugs in code (use /gabe-roast qa)
- Checking alignment with values (use /gabe-align check)

---

## Inputs

```
/gabe-health                    # Full analysis (all 5 checks)
/gabe-health hotspots           # Churn hotspots only
/gabe-health coupling           # Coupling clusters only
/gabe-health fragile            # Bug-fix concentration only
/gabe-health gods               # God files only
/gabe-health scope              # Plan vs actual (requires GSD or CE plan)
/gabe-health [path]             # Analyze a specific directory
```

Optional flags:
- `--days N` — lookback window (default: 60 days)
- `--threshold N` — minimum commits to flag (default: 5)

---

## The 5 Analyses

### 1. God Files

Files touched in >25% of PRs/commits in the lookback window. These are coupling magnets — every feature has to edit them.

**Detection:**
```bash
# Count commits per file in last N days
git log --since=N.days --name-only --format="" | sort | uniq -c | sort -rn | head -20
# Compare against total commit count
git log --since=N.days --oneline | wc -l
```

**Output:**
```
God Files (touched in >25% of commits, last 60 days):
  🔴 functions/src/rateLimiter.ts — 15/40 commits (37%)
     Suggest: Extract responsibilities. Consider /gabe-roast architect on this file.
  🔴 src/services/recipes.ts — 12/40 commits (30%)
     Suggest: May be doing too much. Check if it mixes data access + business logic.
  ⚠️ src/stores/recipeStore.ts — 10/40 commits (25%)
     Borderline. Monitor.
```

### 2. Churn Hotspots

Files with the most modifications in the lookback window, regardless of PR count. High churn often means the design isn't stable — it keeps needing adjustment.

**Detection:**
```bash
# Lines added+removed per file
git log --since=N.days --numstat --format="" | awk '{files[$3]+=$1+$2} END {for(f in files) print files[f], f}' | sort -rn | head -20
```

**Output:**
```
Churn Hotspots (most modifications, last 60 days):
  🔴 functions/src/rateLimiter.ts — 450 lines churned across 15 commits
  🔴 src/pages/RecipeDetailPage.tsx — 380 lines churned across 8 commits
  ⚠️ src/services/pantry.ts — 120 lines churned across 6 commits
  ✅ src/types/*.ts — stable (< 30 lines churned)
```

### 3. Coupling Clusters

Files that always change together. If A and B are co-modified in >60% of commits that touch either, they're coupled — changes to one likely require changes to the other.

**Detection:**
```bash
# For each pair of frequently modified files, count co-occurrence
# in commits vs individual occurrence
git log --since=N.days --name-only --format="---" | [compute co-change frequency]
```

**Output:**
```
Coupling Clusters (>60% co-change rate):
  rateLimiter.ts ↔ suggestRecipes.ts — co-changed in 10/12 commits (83%)
    Risk: Change one, must test both. Missing test in either = hidden breakage.
  
  pantry.ts ↔ mappingStore.ts — co-changed in 6/8 commits (75%)
    Risk: Store and service are entangled. Consider if store should own the logic.
  
  RecipeCard.tsx ↔ recipeStore.ts — co-changed in 5/9 commits (55%)
    Below threshold but close. Watch.
```

### 4. Bug-Fix Concentration

Where do `fix:` and `bug` commits cluster? If 60% of bug fixes touch the same directory, that module is structurally fragile.

**Detection:**
```bash
# Find fix/bug commits and their file distribution
git log --since=N.days --oneline --grep="fix" --grep="bug" --name-only --format="" | sort | uniq -c | sort -rn
```

**Output:**
```
Bug-Fix Concentration (where fixes cluster, last 60 days):
  🔴 functions/src/ — 8 of 13 fix commits (62%)
     Top files: rateLimiter.ts (4), suggestRecipes.ts (3), validateRequest.ts (1)
     Pattern: Rate limiting + suggestion pipeline is the fragile core.
  
  ⚠️ src/services/ — 3 of 13 fix commits (23%)
     Top files: pantry.ts (2), recipes.ts (1)
  
  ✅ src/pages/ — 1 of 13 fix commits (8%) — stable
  ✅ src/components/ — 0 fix commits — solid
```

### 5. Scope Creep (Plan vs Actual)

Compare what was planned (from GSD phase plan or CE brainstorm) against what files were actually changed. Surfaces unplanned work and missed scope.

**Detection:**
- Read `.planning/phases/*/PLAN.md` or `docs/plans/*.md` or `docs/brainstorms/*-requirements.md`
- Extract file references from the plan
- Run `git diff --stat [base-branch]..HEAD` to get actual changed files
- Compare: planned vs touched, unplanned touches, planned but untouched

**Output:**
```
Scope Creep — Phase 3 (Recipe Detail View):
  Planned: 6 files | Touched: 9 files | Unplanned: 4 files | Missed: 1 file

  Planned and touched:
    ✅ src/pages/RecipeDetailPage.tsx
    ✅ src/components/RecipeCard.tsx
    ✅ src/services/recipes.ts
    ✅ src/stores/recipeStore.ts
    ✅ src/types/recipe.ts

  Unplanned (touched but not in plan):
    ⚠️ functions/src/rateLimiter.ts — why? Refactoring unrelated to recipe detail
    ⚠️ functions/src/suggestRecipes.ts — pulled in by rateLimiter coupling
    ⚠️ src/services/pantry.ts — 3 lines changed (minor, likely acceptable)
    ⚠️ firestore.staging.rules — shared infra, cross-app risk

  Planned but untouched:
    ❌ functions/src/recipeDetail.ts — was this dropped from scope?

  Suggest: Review unplanned touches. If rateLimiter refactor was necessary,
  it should have been a separate PR (V3 — Ship Small).
```

---

## Output Format

### Full Mode (default)

```
📊 GABE HEALTH — [Project Name]
   Period: last [N] days | Commits: [total] | Files: [unique files touched]

[1. God Files]
[2. Churn Hotspots]
[3. Coupling Clusters]
[4. Bug-Fix Concentration]
[5. Scope Creep (if plan exists)]

Summary:
  🔴 Critical: [count] god files, [count] fragile modules
  ⚠️ Watch: [count] coupling clusters, [count] churn hotspots
  ✅ Stable: [list of stable areas]

  Top risk: [one-sentence summary of where the codebase is most fragile]
  Suggest: [one action — e.g., /gabe-roast architect functions/src/]
```

### Single Analysis Mode

When invoked with a focus (e.g., `/gabe-health coupling`), only that analysis runs.

---

## Integration with Gabe Suite

| Health finding | Suggested action |
|----------------|-----------------|
| God file detected | `/gabe-roast architect [file]` — structural review to plan decomposition |
| Coupling cluster | `/gabe-assess` — evaluate whether to decouple now or accept the coupling |
| Bug-fix concentration | `/gabe-review` on that area — price the risk of current state |
| Scope creep | `/gabe-align check` — values alignment check on unplanned work |
| High churn + hot file in next PR | `/gabe-review` will show 🔴 HOT churn flag — extra scrutiny on defer decisions |

---

## When to Run

| Moment | Why |
|--------|-----|
| Before starting a new epic/milestone | Know where the minefields are |
| During sprint retrospective | "Why did this sprint feel fragile?" — data-backed answer |
| After a production incident | "Is this area inherently unstable?" |
| Before major refactoring | "Which files should I split/stabilize first?" |
| Monthly cadence | Track health trends over time |

This is NOT a per-commit tool. Run it periodically for strategic insight.

---

## What This Does NOT Do

- Does NOT review code (use /gabe-review or /gabe-roast)
- Does NOT check values alignment (use /gabe-align)
- Does NOT block commits or PRs (purely analytical)
- Does NOT require `.kdbp/` to exist (works on any git repo)
- Does NOT modify any files (read-only analysis)
