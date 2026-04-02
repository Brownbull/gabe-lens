Load and follow the skill at `skills/gabe-cr/SKILL.md` (project-local) or `~/.claude/skills/gabe-cr/SKILL.md` (global).

Review code changes with risk pricing and deferred item tracking.

Arguments:
- No args: review all uncommitted changes (git diff HEAD)
- `brief`: findings table only, no dashboard
- `deferred`: show deferred items dashboard only
- `post-review`: parse the most recent code review output and add risk pricing
- `[file or folder]`: review specific target

Before reviewing, check for `.kdbp/deferred-cr.md` or `.planning/deferred-cr.md` to load the deferred backlog. If deferred items exist, check whether the current diff addresses them.

$ARGUMENTS
