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

$ARGUMENTS
