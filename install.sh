#!/bin/bash
# Install Gabe Lens suite to ~/.claude/
# Can be run standalone or called by refrepos/setup/install.sh
#
# Usage:
#   ./install.sh              # Install all skills + commands
#   ./install.sh --dry-run    # Show what would be done
#   ./install.sh --uninstall  # Remove all gabe-* skills + commands

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
UNINSTALL=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --uninstall) UNINSTALL=true ;;
    esac
done

run() {
    if $DRY_RUN; then
        echo "  [DRY RUN] $*"
    else
        eval "$@"
    fi
}

SKILLS=(gabe-align gabe-assess gabe-health gabe-help gabe-lens gabe-review gabe-roast)
COMMANDS_ONLY=(gabe-init gabe-commit gabe-push)

if $UNINSTALL; then
    echo "=== Uninstall Gabe Lens Suite ==="
    for skill in "${SKILLS[@]}"; do
        run "rm -rf ~/.claude/skills/$skill"
        run "rm -f ~/.claude/commands/$skill.md"
    done
    for cmd in "${COMMANDS_ONLY[@]}"; do
        run "rm -f ~/.claude/commands/$cmd.md"
    done
    echo "Done."
    exit 0
fi

echo "=== Install Gabe Lens Suite ==="
echo "Source: $SCRIPT_DIR"
echo "Target: ~/.claude/"
echo ""

INSTALLED=0
for skill in "${SKILLS[@]}"; do
    if [ ! -d "$SCRIPT_DIR/skills/$skill" ]; then
        echo "  SKIP: skills/$skill/ not found"
        continue
    fi
    run "mkdir -p ~/.claude/skills/$skill"
    run "cp -r \"$SCRIPT_DIR/skills/$skill/\"* ~/.claude/skills/$skill/"
    if [ -f "$SCRIPT_DIR/commands/$skill.md" ]; then
        run "cp \"$SCRIPT_DIR/commands/$skill.md\" ~/.claude/commands/$skill.md"
    fi
    echo "  OK: $skill"
    INSTALLED=$((INSTALLED + 1))
done

# Commands without a skill directory (command file is the full spec)
for cmd in "${COMMANDS_ONLY[@]}"; do
    if [ -f "$SCRIPT_DIR/commands/$cmd.md" ]; then
        run "mkdir -p ~/.claude/commands"
        run "cp \"$SCRIPT_DIR/commands/$cmd.md\" ~/.claude/commands/$cmd.md"
        echo "  OK: $cmd (command only)"
        INSTALLED=$((INSTALLED + 1))
    fi
done

echo ""
echo "Installed $INSTALLED/$((${#SKILLS[@]} + ${#COMMANDS_ONLY[@]})) components."