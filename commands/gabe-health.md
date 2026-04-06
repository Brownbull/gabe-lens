Load and follow the skill at `skills/gabe-health/SKILL.md` (project-local) or `~/.claude/skills/gabe-health/SKILL.md` (global).

Codebase health analysis — structural fragility, churn, coupling, and scope drift.

Arguments:
- No args: full analysis (all 5 checks)
- `hotspots`: churn hotspots only
- `coupling`: coupling clusters only
- `fragile`: bug-fix concentration only
- `gods`: god files only
- `scope`: plan vs actual comparison
- `[path]`: analyze a specific directory
- `--days N`: lookback window (default: 60)

$ARGUMENTS
