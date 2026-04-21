Load and follow the skill at `skills/gabe-review/SKILL.md` (project-local) or `~/.claude/skills/gabe-review/SKILL.md` (global).

Review code changes with risk pricing, confidence scoring, and interactive triage.

Arguments:
- No args: review all uncommitted changes (git diff HEAD)
- `brief`: findings table + confidence score + verdict only, no triage
- `fix`: skip to triage, auto-fix all findings
- `deferred`: show deferred items dashboard with triage option
- `post-review`: parse the most recent code review output and add risk pricing + confidence score
- `[file or folder]`: review specific target

Before reviewing, check for `.kdbp/deferred-cr.md` or `.planning/deferred-cr.md` to load the deferred backlog. If deferred items exist, check whether the current diff addresses them.

### Scope-aware review (if SCOPE.md + ROADMAP.md exist)

When project scoped via `/gabe-scope`, add REQ-drift to the findings dimensions:

1. **REQ coverage drift.** For each changed file, try to trace back to a REQ-NN via the current phase's `Covers REQs` column. If a file changes but no REQ in current phase claims it, add MEDIUM finding `req_coverage_gap` — either code is off-scope or the phase is wrong.
2. **REQ inflation.** If a single diff claims to satisfy >3 REQs, flag as HIGH finding `req_inflation` — likely scope creep that should split into multiple commits + phases.
3. **Direct SCOPE.md / ROADMAP.md edit.** If the diff touches SCOPE.md or ROADMAP.md directly (not via `/gabe-scope-change`), flag as CRITICAL finding `scope_bypass` — rerun via `/gabe-scope-change` to ensure classifier + Change Log + version bump.

All findings feed the Review Confidence Score via the existing rubric. No writes to SCOPE.md or ROADMAP.md.

$ARGUMENTS
