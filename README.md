# Claude Code Portable Setup

Portable workflow configuration for Claude Code. Includes custom skills, project templates, cross-cutting lessons, and a reviewer agent.

## What's Included

| Component | Description |
|-----------|-------------|
| **CLAUDE.md** | Workflow orchestration: plan-first, subagent strategy, verification pipeline, lessons capture |
| **settings.json** | Model (Opus 1M), permissions deny list, safety hooks (rm-rf/force-push blocking), status line |
| **statusline-command.sh** | Context %, cost estimation, rate limits, session time with color coding |
| **5 custom skills** | `/brainstorm`, `/plan`, `/implement`, `/new-project`, `/review` |
| **3 template layers** | common (SPEC.md, tasks), team (OpenSpec-compatible), python (uv/ruff/pytest) |
| **cross-cutting.md** | 8 reusable bug patterns (regex specificity, false positives, shell portability, etc.) |
| **reviewer agent** | Independent Opus code reviewer checking spec compliance, security, test coverage |

## What's NOT Included

- Security plugins (data-classification, detect-secrets)
- Session data, caches, telemetry

## Install

```bash
./install.sh
```

The script:
1. Backs up any existing `~/.claude/settings.json` and `CLAUDE.md`
2. Creates the directory structure under `~/.claude/`
3. Copies all workflow files
4. Installs plugins (superpowers, frontend-design, skill-creator)

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code/overview)
- `jq` (used by hooks and status line): `brew install jq`

## Workflow

```
/new-project --lang python myapp "Description"   # Scaffold + write SPEC.md
/brainstorm [topic]                                # Explore design before code
/plan                                              # Create tasks/todo.md from SPEC.md
/implement                                         # Subagent-driven execution with review
/review --fix                                      # Final quality gate with auto-fix
```

## Plugins

Installed automatically by the script:

| Plugin | Purpose |
|--------|---------|
| superpowers | TDD, debugging, verification, git worktrees, code review workflows |
| frontend-design | Design-grade UI components |
| skill-creator | Create and test custom skills |
