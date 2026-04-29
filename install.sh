#!/usr/bin/env bash
set -euo pipefail

# Claude Code Portable Setup Installer
# Installs workflow configuration, skills, templates, lessons, and agents.
# Safe to re-run — overwrites files in place, skips already-installed plugins.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/claude-config"
TARGET_DIR="${HOME}/.claude"

# Colors
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
DIM=$'\033[2m'
RESET=$'\033[0m'

info()  { echo "${GREEN}[+]${RESET} $1"; }
warn()  { echo "${YELLOW}[!]${RESET} $1"; }
error() { echo "${RED}[x]${RESET} $1"; }
skip()  { echo "${DIM}[=]${RESET} $1"; }

# ── Pre-flight checks ────────────────────────────────────────────────────────

if ! command -v claude &>/dev/null; then
    warn "Claude Code CLI not found. Install it first: https://docs.anthropic.com/en/docs/claude-code/overview"
    warn "Continuing anyway — files will be placed, but plugins won't install."
    CLAUDE_AVAILABLE=false
else
    CLAUDE_AVAILABLE=true
fi

if ! command -v jq &>/dev/null; then
    error "jq is required (used by hooks and status line). Install: brew install jq"
    exit 1
fi

# ── Backup existing config (only on first run) ──────────────────────────────

if [ -f "${TARGET_DIR}/settings.json" ]; then
    # Only backup if the file differs from what we're about to install
    if ! diff -q "${SOURCE_DIR}/settings.json" "${TARGET_DIR}/settings.json" &>/dev/null; then
        # Only backup if no backup exists yet (don't stack backups on re-runs)
        if ! ls "${TARGET_DIR}"/settings.json.backup.* &>/dev/null 2>&1; then
            backup="${TARGET_DIR}/settings.json.backup.$(date +%Y%m%d%H%M%S)"
            cp "${TARGET_DIR}/settings.json" "$backup"
            warn "Existing settings.json backed up to: ${backup}"
        else
            skip "settings.json backup already exists, skipping backup"
        fi
    fi
fi

if [ -f "${TARGET_DIR}/CLAUDE.md" ]; then
    if ! diff -q "${SOURCE_DIR}/CLAUDE.md" "${TARGET_DIR}/CLAUDE.md" &>/dev/null; then
        if ! ls "${TARGET_DIR}"/CLAUDE.md.backup.* &>/dev/null 2>&1; then
            backup="${TARGET_DIR}/CLAUDE.md.backup.$(date +%Y%m%d%H%M%S)"
            cp "${TARGET_DIR}/CLAUDE.md" "$backup"
            warn "Existing CLAUDE.md backed up to: ${backup}"
        else
            skip "CLAUDE.md backup already exists, skipping backup"
        fi
    fi
fi

# ── Create directory structure ───────────────────────────────────────────────

info "Ensuring directory structure..."
mkdir -p "${TARGET_DIR}"/{skills/{brainstorm,plan,implement,new-project,review},templates/{common/tasks,team/changes,python/{src,tests}},lessons,agents/reviewer}

# ── Helper: copy if changed ─────────────────────────────────────────────────

copy_file() {
    local src="$1" dst="$2"
    if [ -f "$dst" ] && diff -q "$src" "$dst" &>/dev/null; then
        return 0  # identical, skip
    fi
    cp "$src" "$dst"
    echo "  updated: ${dst#$TARGET_DIR/}"
}

CHANGED=0
copy_tracked() {
    local src="$1" dst="$2"
    if [ -f "$dst" ] && diff -q "$src" "$dst" &>/dev/null; then
        return 0
    fi
    cp "$src" "$dst"
    echo "  updated: ${dst#$TARGET_DIR/}"
    CHANGED=1
}

# ── Copy files ───────────────────────────────────────────────────────────────

info "Syncing workflow configuration..."

# Core config
copy_tracked "${SOURCE_DIR}/settings.json"         "${TARGET_DIR}/settings.json"
copy_tracked "${SOURCE_DIR}/CLAUDE.md"             "${TARGET_DIR}/CLAUDE.md"
copy_tracked "${SOURCE_DIR}/statusline-command.sh"  "${TARGET_DIR}/statusline-command.sh"
chmod +x "${TARGET_DIR}/statusline-command.sh"

# Skills
info "Syncing skills..."
copy_tracked "${SOURCE_DIR}/skills/brainstorm/SKILL.md"              "${TARGET_DIR}/skills/brainstorm/SKILL.md"
copy_tracked "${SOURCE_DIR}/skills/plan/SKILL.md"                    "${TARGET_DIR}/skills/plan/SKILL.md"
copy_tracked "${SOURCE_DIR}/skills/implement/SKILL.md"               "${TARGET_DIR}/skills/implement/SKILL.md"
copy_tracked "${SOURCE_DIR}/skills/implement/implementer-prompt.md"  "${TARGET_DIR}/skills/implement/implementer-prompt.md"
copy_tracked "${SOURCE_DIR}/skills/implement/spec-reviewer-prompt.md" "${TARGET_DIR}/skills/implement/spec-reviewer-prompt.md"
copy_tracked "${SOURCE_DIR}/skills/implement/quality-reviewer-prompt.md" "${TARGET_DIR}/skills/implement/quality-reviewer-prompt.md"
copy_tracked "${SOURCE_DIR}/skills/new-project/SKILL.md"             "${TARGET_DIR}/skills/new-project/SKILL.md"
copy_tracked "${SOURCE_DIR}/skills/review/SKILL.md"                  "${TARGET_DIR}/skills/review/SKILL.md"

# Templates
info "Syncing templates..."
copy_tracked "${SOURCE_DIR}/templates/common/CLAUDE.md.template"     "${TARGET_DIR}/templates/common/CLAUDE.md.template"
copy_tracked "${SOURCE_DIR}/templates/common/SPEC.md.template"       "${TARGET_DIR}/templates/common/SPEC.md.template"
copy_tracked "${SOURCE_DIR}/templates/common/tasks/lessons.md"       "${TARGET_DIR}/templates/common/tasks/lessons.md"
copy_tracked "${SOURCE_DIR}/templates/common/tasks/todo.md.template" "${TARGET_DIR}/templates/common/tasks/todo.md.template"
copy_tracked "${SOURCE_DIR}/templates/team/CLAUDE.md.template"       "${TARGET_DIR}/templates/team/CLAUDE.md.template"
copy_tracked "${SOURCE_DIR}/templates/team/changes/README.md"        "${TARGET_DIR}/templates/team/changes/README.md"
copy_tracked "${SOURCE_DIR}/templates/python/pyproject.toml.template" "${TARGET_DIR}/templates/python/pyproject.toml.template"
copy_tracked "${SOURCE_DIR}/templates/python/README.md.template"     "${TARGET_DIR}/templates/python/README.md.template"

# .gitignore stored without dot prefix to survive transfers
if [ -f "${SOURCE_DIR}/templates/python/gitignore" ]; then
    copy_tracked "${SOURCE_DIR}/templates/python/gitignore"          "${TARGET_DIR}/templates/python/.gitignore"
elif [ -f "${SOURCE_DIR}/templates/python/.gitignore" ]; then
    copy_tracked "${SOURCE_DIR}/templates/python/.gitignore"         "${TARGET_DIR}/templates/python/.gitignore"
fi

copy_tracked "${SOURCE_DIR}/templates/python/src/__init__.py"        "${TARGET_DIR}/templates/python/src/__init__.py"
copy_tracked "${SOURCE_DIR}/templates/python/src/main.py.template"   "${TARGET_DIR}/templates/python/src/main.py.template"
copy_tracked "${SOURCE_DIR}/templates/python/tests/conftest.py.template" "${TARGET_DIR}/templates/python/tests/conftest.py.template"
copy_tracked "${SOURCE_DIR}/templates/python/tests/test_placeholder.py"  "${TARGET_DIR}/templates/python/tests/test_placeholder.py"

# Lessons
info "Syncing lessons..."
copy_tracked "${SOURCE_DIR}/lessons/cross-cutting.md"  "${TARGET_DIR}/lessons/cross-cutting.md"

# Agents
info "Syncing reviewer agent..."
copy_tracked "${SOURCE_DIR}/agents/reviewer/AGENT.md"  "${TARGET_DIR}/agents/reviewer/AGENT.md"

# ── Install plugins (skip if already installed) ──────────────────────────────

if [ "$CLAUDE_AVAILABLE" = true ]; then
    info "Checking plugins..."

    for plugin in superpowers frontend-design skill-creator; do
        full_name="${plugin}@claude-plugins-official"
        # Check if plugin directory already exists
        if [ -d "${TARGET_DIR}/plugins/${full_name}" ]; then
            skip "Plugin ${plugin} already installed"
        else
            info "  Installing ${plugin}..."
            claude plugins install "${full_name}" 2>/dev/null || warn "  Failed to install ${plugin} — install manually later"
        fi
    done
else
    warn "Skipping plugin check (Claude CLI not available)."
    warn "Install these plugins manually after installing Claude Code:"
    warn "  claude plugins install superpowers@claude-plugins-official"
    warn "  claude plugins install frontend-design@claude-plugins-official"
    warn "  claude plugins install skill-creator@claude-plugins-official"
fi

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
if [ "$CHANGED" -eq 1 ]; then
    info "Update complete! Changed files listed above."
else
    info "Everything already up to date."
fi
echo ""
echo "  ${DIM}Workflow:${RESET}"
echo "    /brainstorm → /plan → /implement → /review --fix"
echo ""
