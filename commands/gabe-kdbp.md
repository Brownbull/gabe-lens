Load and follow the skill at `skills/gabe-kdbp/SKILL.md` (project-local) or `~/.claude/skills/gabe-kdbp/SKILL.md` (global).

Lightweight alignment guardian. Watches for drift signals and suggests the right Gabe tool.

Arguments:
- `init [project-name]`: initialize .kdbp/ in current project (interactive)
- `status`: show current session state (edit counts, gravity wells, test gaps)
- `check`: run all 4 checks against current session state
- `ledger`: show recent session history
- No args: same as `status`

$ARGUMENTS
