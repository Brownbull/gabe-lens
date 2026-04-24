Load and follow the skill at `skills/gabe-review/SKILL.md` (project-local) or `~/.claude/skills/gabe-review/SKILL.md` (global).

Review code changes with risk pricing, confidence scoring, and interactive triage.

Arguments:
- No args: review all uncommitted changes (git diff HEAD). Writes/resumes the singleton `.kdbp/REVIEW.md` and enters triage.
- `brief`: findings table + confidence score + verdict only, no triage and no REVIEW.md write
- `fix`: skip to triage, auto-fix all findings (writes REVIEW.md en route)
- `deferred`: show deferred items dashboard with triage option (read-only of PENDING.md; does not touch REVIEW.md)
- `post-review`: parse an external code review (CE:review, BMad, ECC) and ingest its findings into `.kdbp/REVIEW.md`. If no external source and an active REVIEW.md already exists, behaves as Resume.
- `inbox`: produce the live `.kdbp/REVIEW.md` and stop — no triage, no writes to PENDING/LEDGER/PLAN. Intended for Codex CLI ("analysis only" policy). Claude picks up via the Resume prompt.
- `resume`: explicitly resume triage on the active `.kdbp/REVIEW.md` (same as the `(r)` option in the collision prompt).
- `close`: archive active REVIEW.md as resolved + write LEDGER/tick PLAN (for when triage was informal).
- `discard`: archive active REVIEW.md as cancelled, skip LEDGER write.
- `[file or folder]`: review specific target (writes REVIEW.md as usual).

All write-producing invocations (default, `fix`, `post-review`, `inbox`, `[file/folder]`) honor the REVIEW.md singleton collision prompt: `(r) Resume | (a) Archive as stale | (x) Replace (archive as superseded) | (c) Cancel`.

Before reviewing, check for `.kdbp/deferred-cr.md` or `.planning/deferred-cr.md` to load the deferred backlog. If deferred items exist, check whether the current diff addresses them.

### Scope-aware review (if SCOPE.md + ROADMAP.md exist)

When project scoped via `/gabe-scope`, add REQ-drift to the findings dimensions:

1. **REQ coverage drift.** For each changed file, try to trace back to a REQ-NN via the current phase's `Covers REQs` column. If a file changes but no REQ in current phase claims it, add MEDIUM finding `req_coverage_gap` — either code is off-scope or the phase is wrong.
2. **REQ inflation.** If a single diff claims to satisfy >3 REQs, flag as HIGH finding `req_inflation` — likely scope creep that should split into multiple commits + phases.
3. **Direct SCOPE.md / ROADMAP.md edit.** If the diff touches SCOPE.md or ROADMAP.md directly (not via `/gabe-scope-change`), flag as CRITICAL finding `scope_bypass` — rerun via `/gabe-scope-change` to ensure classifier + Change Log + version bump.

All findings feed the Review Confidence Score via the existing rubric. No writes to SCOPE.md or ROADMAP.md.

$ARGUMENTS
