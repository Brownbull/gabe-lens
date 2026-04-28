#!/bin/bash
# Install Gabe Suite to ~/.claude/
# Can be run standalone or called by refrepos/setup/install.sh
#
# Usage:
#   ./install.sh                 # Install to ~/.claude (Claude Code) AND ~/.agents (Codex CLI)
#   ./install.sh --claude-only   # Install only to ~/.claude
#   ./install.sh --codex-only    # Install only to ~/.agents (skills + templates; no commands)
#   ./install.sh --dry-run       # Show what would be done
#   ./install.sh --uninstall     # Remove all gabe-* skills + commands from both homes

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
UNINSTALL=false
INSTALL_CLAUDE=true
INSTALL_AGENTS=true

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --uninstall) UNINSTALL=true ;;
        --claude-only) INSTALL_AGENTS=false ;;
        --codex-only) INSTALL_CLAUDE=false ;;
    esac
done

run() {
    if $DRY_RUN; then
        echo "  [DRY RUN] $*"
    else
        eval "$@"
    fi
}

SKILLS=(gabe-align gabe-arch gabe-assess gabe-debt gabe-docs gabe-health gabe-help gabe-lens gabe-mockup gabe-review gabe-roast)
COMMANDS_ONLY=(gabe-init gabe-commit gabe-push gabe-plan gabe-teach gabe-scope gabe-scope-change gabe-scope-addition gabe-scope-pivot gabe-execute gabe-mockup gabe-next)

if $UNINSTALL; then
    echo "=== Uninstall Gabe Suite ==="
    for skill in "${SKILLS[@]}"; do
        if $INSTALL_CLAUDE; then
            run "rm -rf ~/.claude/skills/$skill"
            run "rm -f ~/.claude/commands/$skill.md"
        fi
        if $INSTALL_AGENTS; then
            run "rm -rf ~/.agents/skills/$skill"
        fi
    done
    if $INSTALL_CLAUDE; then
        for cmd in "${COMMANDS_ONLY[@]}"; do
            run "rm -f ~/.claude/commands/$cmd.md"
        done
        run "rm -rf ~/.claude/templates/gabe"
        run "rm -rf ~/.claude/prompts/gabe-scope"
        run "rm -rf ~/.claude/schemas/gabe-scope"
    fi
    if $INSTALL_AGENTS; then
        run "rm -rf ~/.agents/templates/gabe"
    fi
    echo "Done."
    exit 0
fi

echo "=== Install Gabe Suite ==="
echo "Source: $SCRIPT_DIR"
TARGETS=""
$INSTALL_CLAUDE && TARGETS="$TARGETS ~/.claude/"
$INSTALL_AGENTS && TARGETS="$TARGETS ~/.agents/"
echo "Targets:$TARGETS"
echo ""

INSTALLED=0
for skill in "${SKILLS[@]}"; do
    if [ ! -d "$SCRIPT_DIR/skills/$skill" ]; then
        echo "  SKIP: skills/$skill/ not found"
        continue
    fi
    if $INSTALL_CLAUDE; then
        run "mkdir -p ~/.claude/skills/$skill"
        run "cp -r \"$SCRIPT_DIR/skills/$skill/\"* ~/.claude/skills/$skill/"
        if [ -f "$SCRIPT_DIR/commands/$skill.md" ]; then
            run "cp \"$SCRIPT_DIR/commands/$skill.md\" ~/.claude/commands/$skill.md"
        fi
    fi
    if $INSTALL_AGENTS; then
        run "mkdir -p ~/.agents/skills/$skill"
        run "cp -r \"$SCRIPT_DIR/skills/$skill/\"* ~/.agents/skills/$skill/"
        # Codex does not consume command files — skip commands/$skill.md here.
    fi
    echo "  OK: $skill"
    INSTALLED=$((INSTALLED + 1))
done

# Commands without a skill directory (Claude Code only — Codex CLI doesn't support custom slash commands)
if $INSTALL_CLAUDE; then
    for cmd in "${COMMANDS_ONLY[@]}"; do
        if [ -f "$SCRIPT_DIR/commands/$cmd.md" ]; then
            run "mkdir -p ~/.claude/commands"
            run "cp \"$SCRIPT_DIR/commands/$cmd.md\" ~/.claude/commands/$cmd.md"
            echo "  OK: $cmd (command only)"
            INSTALLED=$((INSTALLED + 1))
        fi
    done
fi


# Templates — bundled source of truth for .kdbp/ files created by /gabe-init and other commands
# Installed to every enabled home (Claude and/or Codex) so tier-section lookups succeed in each CLI.
install_templates_to() {
    local home_root="$1"   # e.g. ~/.claude or ~/.agents
    local label="$2"       # display label
    run "mkdir -p $home_root/templates/gabe"
    run "cp \"$SCRIPT_DIR/templates/\"*.md $home_root/templates/gabe/ 2>/dev/null || true"
    run "cp \"$SCRIPT_DIR/templates/\"*.yaml $home_root/templates/gabe/ 2>/dev/null || true"
    run "cp \"$SCRIPT_DIR/templates/\"*.json $home_root/templates/gabe/ 2>/dev/null || true"
    local tpl_count
    tpl_count=$(ls -1 "$SCRIPT_DIR/templates/" 2>/dev/null | grep -v '^tier-sections$' | grep -v '^mockup$' | grep -v '^debt-patterns$' | wc -l)
    echo "  OK: $tpl_count templates → $label/templates/gabe/"

    if [ -d "$SCRIPT_DIR/templates/tier-sections" ]; then
        run "mkdir -p $home_root/templates/gabe/tier-sections"
        run "cp \"$SCRIPT_DIR/templates/tier-sections/\"*.md $home_root/templates/gabe/tier-sections/ 2>/dev/null || true"
        local sec_count
        sec_count=$(ls -1 "$SCRIPT_DIR/templates/tier-sections/"*.md 2>/dev/null | wc -l)
        echo "  OK: $sec_count tier-sections → $label/templates/gabe/tier-sections/"
    fi

    if [ -d "$SCRIPT_DIR/templates/mockup" ]; then
        run "mkdir -p $home_root/templates/gabe/mockup"
        # Recursive copy — picks up tests/mockups/ subtree (hub.spec.ts, tweaks.spec.ts, section-smoke.spec.ts.tmpl)
        run "cp -r \"$SCRIPT_DIR/templates/mockup/\"* $home_root/templates/gabe/mockup/ 2>/dev/null || true"
        local mk_count
        mk_count=$(find "$SCRIPT_DIR/templates/mockup/" -type f 2>/dev/null | wc -l)
        echo "  OK: $mk_count mockup template files → $label/templates/gabe/mockup/ (incl. tests/mockups/)"
    fi

    if [ -d "$SCRIPT_DIR/templates/debt-patterns" ]; then
        run "mkdir -p $home_root/templates/gabe/debt-patterns"
        run "cp \"$SCRIPT_DIR/templates/debt-patterns/\"*.md $home_root/templates/gabe/debt-patterns/ 2>/dev/null || true"
        local dp_count
        dp_count=$(ls -1 "$SCRIPT_DIR/templates/debt-patterns/"*.md 2>/dev/null | wc -l)
        echo "  OK: $dp_count debt-pattern files → $label/templates/gabe/debt-patterns/"
    fi
}

if [ -d "$SCRIPT_DIR/templates" ]; then
    $INSTALL_CLAUDE && install_templates_to "$HOME/.claude" "~/.claude"
    $INSTALL_AGENTS && install_templates_to "$HOME/.agents" "~/.agents"
fi

# Prompts (Option A — ship to runtime) — consumed by /gabe-scope family at execution time.
# Claude-only for now; Codex port of /gabe-scope family is a future pass.
if $INSTALL_CLAUDE && [ -d "$SCRIPT_DIR/prompts" ]; then
    run "mkdir -p ~/.claude/prompts/gabe-scope"
    run "cp \"$SCRIPT_DIR/prompts/\"*.md ~/.claude/prompts/gabe-scope/ 2>/dev/null || true"
    PROMPT_COUNT=$(ls -1 "$SCRIPT_DIR/prompts/"*.md 2>/dev/null | wc -l)
    echo "  OK: $PROMPT_COUNT prompts → ~/.claude/prompts/gabe-scope/"
fi

# Schemas — JSON Schema validators for scope-session.json + scope-references.yaml (Claude-only for now).
if $INSTALL_CLAUDE && [ -d "$SCRIPT_DIR/schemas" ]; then
    run "mkdir -p ~/.claude/schemas/gabe-scope"
    run "cp \"$SCRIPT_DIR/schemas/\"*.json ~/.claude/schemas/gabe-scope/ 2>/dev/null || true"
    run "cp \"$SCRIPT_DIR/schemas/\"validate.py ~/.claude/schemas/gabe-scope/ 2>/dev/null || true"
    SCHEMA_COUNT=$(ls -1 "$SCRIPT_DIR/schemas/"*.json 2>/dev/null | wc -l)
    echo "  OK: $SCHEMA_COUNT schemas → ~/.claude/schemas/gabe-scope/"
fi

echo ""
echo "Installed $INSTALLED/$((${#SKILLS[@]} + ${#COMMANDS_ONLY[@]})) components."