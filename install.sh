#!/bin/bash
# Install Gabe Suite to ~/.claude/ and ~/.agents/
# Can be run standalone or called by refrepos/setup/install.sh
#
# Usage:
#   ./install.sh                 # Install to ~/.claude (Claude Code) AND ~/.agents (Codex CLI)
#   ./install.sh --claude-only   # Install only to ~/.claude
#   ./install.sh --codex-only    # Install only to ~/.agents (skills + templates + command reference docs)
#   ./install.sh --dry-run       # Show what would be done
#   ./install.sh --uninstall     # Remove all gabe-* skills + command files from both homes

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
COMMANDS=()
if [ -d "$SCRIPT_DIR/commands" ]; then
    for command_path in "$SCRIPT_DIR"/commands/gabe-*.md; do
        [ -e "$command_path" ] || continue
        command_file="$(basename "$command_path")"
        COMMANDS+=("${command_file%.md}")
    done
fi

if $UNINSTALL; then
    echo "=== Uninstall Gabe Suite ==="
    for skill in "${SKILLS[@]}"; do
        if $INSTALL_CLAUDE; then
            run "rm -rf ~/.claude/skills/$skill"
        fi
        if $INSTALL_AGENTS; then
            run "rm -rf ~/.agents/skills/$skill"
        fi
    done
    for cmd in "${COMMANDS[@]}"; do
        if $INSTALL_CLAUDE; then
            run "rm -f ~/.claude/commands/$cmd.md"
        fi
        if $INSTALL_AGENTS; then
            run "rm -f ~/.agents/commands/$cmd.md"
        fi
    done
    $INSTALL_AGENTS && run "rmdir ~/.agents/commands 2>/dev/null || true"
    if $INSTALL_CLAUDE; then
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

# Ensure parent dirs exist before any cp — per-skill subdirs are created in the loop
$INSTALL_CLAUDE && run "mkdir -p ~/.claude/commands"
$INSTALL_AGENTS && run "mkdir -p ~/.agents/commands"

INSTALLED=0
for skill in "${SKILLS[@]}"; do
    if [ ! -d "$SCRIPT_DIR/skills/$skill" ]; then
        echo "  SKIP: skills/$skill/ not found"
        continue
    fi
    if $INSTALL_CLAUDE; then
        run "mkdir -p ~/.claude/skills/$skill"
        run "cp -r \"$SCRIPT_DIR/skills/$skill/\"* ~/.claude/skills/$skill/"
    fi
    if $INSTALL_AGENTS; then
        run "mkdir -p ~/.agents/skills/$skill"
        run "cp -r \"$SCRIPT_DIR/skills/$skill/\"* ~/.agents/skills/$skill/"
    fi
    echo "  OK: $skill"
    INSTALLED=$((INSTALLED + 1))
done

# Command files. Claude Code consumes these as slash commands. Codex keeps the
# same files as local command references; command behavior still comes from skills.
for cmd in "${COMMANDS[@]}"; do
    if [ -f "$SCRIPT_DIR/commands/$cmd.md" ]; then
        if $INSTALL_CLAUDE; then
            run "mkdir -p ~/.claude/commands"
            run "cp \"$SCRIPT_DIR/commands/$cmd.md\" ~/.claude/commands/$cmd.md"
        fi
        if $INSTALL_AGENTS; then
            run "mkdir -p ~/.agents/commands"
            run "cp \"$SCRIPT_DIR/commands/$cmd.md\" ~/.agents/commands/$cmd.md"
        fi
        if $INSTALL_CLAUDE && $INSTALL_AGENTS; then
            echo "  OK: $cmd (Claude command + Codex reference)"
        elif $INSTALL_CLAUDE; then
            echo "  OK: $cmd (Claude command)"
        else
            echo "  OK: $cmd (Codex command reference)"
        fi
        INSTALLED=$((INSTALLED + 1))
    fi
done


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
echo "Installed $INSTALLED/$((${#SKILLS[@]} + ${#COMMANDS[@]})) components."
