#!/bin/bash
# Install Gabe Suite to ~/.claude/
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

SKILLS=(gabe-align gabe-arch gabe-assess gabe-docs gabe-health gabe-help gabe-lens gabe-review gabe-roast)
COMMANDS_ONLY=(gabe-init gabe-commit gabe-push gabe-plan gabe-teach gabe-scope gabe-scope-change gabe-scope-addition gabe-scope-pivot gabe-execute gabe-next)

if $UNINSTALL; then
    echo "=== Uninstall Gabe Suite ==="
    for skill in "${SKILLS[@]}"; do
        run "rm -rf ~/.claude/skills/$skill"
        run "rm -f ~/.claude/commands/$skill.md"
    done
    for cmd in "${COMMANDS_ONLY[@]}"; do
        run "rm -f ~/.claude/commands/$cmd.md"
    done
    run "rm -rf ~/.claude/templates/gabe"
    run "rm -rf ~/.claude/prompts/gabe-scope"
    run "rm -rf ~/.claude/schemas/gabe-scope"
    echo "Done."
    exit 0
fi

echo "=== Install Gabe Suite ==="
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


# Templates — bundled source of truth for .kdbp/ files created by /gabe-init and other commands
if [ -d "$SCRIPT_DIR/templates" ]; then
    run "mkdir -p ~/.claude/templates/gabe"
    # Copy .md + .yaml + .json templates (SCOPE.md, ROADMAP.md, scope-references.yaml, scope-session.example.json, etc.)
    run "cp \"$SCRIPT_DIR/templates/\"*.md ~/.claude/templates/gabe/ 2>/dev/null || true"
    run "cp \"$SCRIPT_DIR/templates/\"*.yaml ~/.claude/templates/gabe/ 2>/dev/null || true"
    run "cp \"$SCRIPT_DIR/templates/\"*.json ~/.claude/templates/gabe/ 2>/dev/null || true"
    TEMPLATE_COUNT=$(ls -1 "$SCRIPT_DIR/templates/" 2>/dev/null | grep -v '^tier-sections$' | wc -l)
    echo "  OK: $TEMPLATE_COUNT templates → ~/.claude/templates/gabe/"

    # Tier-section catalog (subdirectory) — consumed by /gabe-plan to assemble trade-off matrices
    if [ -d "$SCRIPT_DIR/templates/tier-sections" ]; then
        run "mkdir -p ~/.claude/templates/gabe/tier-sections"
        run "cp \"$SCRIPT_DIR/templates/tier-sections/\"*.md ~/.claude/templates/gabe/tier-sections/ 2>/dev/null || true"
        SECTION_COUNT=$(ls -1 "$SCRIPT_DIR/templates/tier-sections/"*.md 2>/dev/null | wc -l)
        echo "  OK: $SECTION_COUNT tier-sections → ~/.claude/templates/gabe/tier-sections/"
    fi
fi

# Prompts (Option A — ship to runtime) — consumed by /gabe-scope family at execution time
if [ -d "$SCRIPT_DIR/prompts" ]; then
    run "mkdir -p ~/.claude/prompts/gabe-scope"
    run "cp \"$SCRIPT_DIR/prompts/\"*.md ~/.claude/prompts/gabe-scope/ 2>/dev/null || true"
    PROMPT_COUNT=$(ls -1 "$SCRIPT_DIR/prompts/"*.md 2>/dev/null | wc -l)
    echo "  OK: $PROMPT_COUNT prompts → ~/.claude/prompts/gabe-scope/"
fi

# Schemas — JSON Schema validators for scope-session.json + scope-references.yaml
if [ -d "$SCRIPT_DIR/schemas" ]; then
    run "mkdir -p ~/.claude/schemas/gabe-scope"
    run "cp \"$SCRIPT_DIR/schemas/\"*.json ~/.claude/schemas/gabe-scope/ 2>/dev/null || true"
    run "cp \"$SCRIPT_DIR/schemas/\"validate.py ~/.claude/schemas/gabe-scope/ 2>/dev/null || true"
    SCHEMA_COUNT=$(ls -1 "$SCRIPT_DIR/schemas/"*.json 2>/dev/null | wc -l)
    echo "  OK: $SCHEMA_COUNT schemas → ~/.claude/schemas/gabe-scope/"
fi

echo ""
echo "Installed $INSTALLED/$((${#SKILLS[@]} + ${#COMMANDS_ONLY[@]})) components."