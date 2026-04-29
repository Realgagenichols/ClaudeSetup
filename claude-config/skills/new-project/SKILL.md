---
name: new-project
description: "Scaffold a new project. Usage: /new-project [--team] [--lang python] myapp \"What it does\""
argument-hint: --team --lang python myapp "description"
user-invocable: true
allowed-tools: Bash Read Write Glob
---

# Create a New Project

Scaffold a new project using the template system at `~/.claude/templates/`.

## Arguments

Parse the arguments from `$ARGUMENTS`:
- `--team` (optional): Use tool-agnostic, OpenSpec-compatible templates. Produces a project any AI assistant can work with. Without this flag, scaffolds with personal workflow tools (review pipeline, superpowers, custom agents).
- `--lang <language>` (optional): Which language template to use (e.g., `python`, `node`). If omitted, choose the most appropriate language based on the project description and context.
- First positional arg: **project name** (used as directory name and CLI command name)
- Second positional arg: **description** (quoted string describing the project)

Example invocations:
- `/new-project envaudit "Scan projects for hardcoded secrets"`
- `/new-project --lang python envaudit "Scan projects for hardcoded secrets"`
- `/new-project --team api-gateway "REST API gateway for internal services"`
- `/new-project --team --lang python data-pipeline "ETL pipeline for analytics"`

## Template System

Templates live at `~/.claude/templates/` in three layers:

```
~/.claude/templates/
  common/          # Shared base (SPEC.md, tasks/, CLAUDE.md for personal mode)
  team/            # Team mode overlay (tool-agnostic CLAUDE.md, changes/ workflow)
  python/          # Python-specific (pyproject.toml, tests/, src/)
  node/            # (future) Node.js-specific
```

**Personal mode** (default): common + language
**Team mode** (`--team`): common + team overlay + language

## Available Languages

Check which language templates exist:
`ls ~/.claude/templates/ | grep -v common | grep -v team`

## Steps

1. **Determine language**: Use `--lang` if provided, otherwise infer from description. Check that `~/.claude/templates/{language}/` exists.

2. **Create project directory**: Create `{project_name}/` in the current working directory (where the Claude session was started).

3. **Copy common templates**: Copy all files from `~/.claude/templates/common/` into the project directory. For files ending in `.template`, strip the suffix after copying.

4. **If `--team` flag is set — overlay team templates**: Copy all files from `~/.claude/templates/team/` into the project directory, overwriting any common files (this replaces the personal CLAUDE.md with the tool-agnostic version and adds the `changes/` directory with its README).

5. **Copy language templates**: Copy all files from `~/.claude/templates/{language}/` into the project directory, overlaying previous files. For `.template` files, strip the suffix after copying. For the Python `src/` directory, rename it to `{package_name}/` (project name with hyphens replaced by underscores, lowercase).

6. **Substitute variables** in ALL copied files (including non-template files that reference variables):

   | Variable | Value |
   |----------|-------|
   | `{{project_name}}` | The project name argument |
   | `{{description}}` | The description argument |
   | `{{package_name}}` | project_name with hyphens → underscores, lowercase |
   | `{{module_name}}` | Same as package_name |

7. **Fill in the SPEC.md**: Using the project name and description, fill in the SPEC.md with an initial draft. Requirements should use RFC 2119 keywords (SHALL/SHOULD/MAY) and each requirement should have at least one Given/When/Then scenario. Ask the user clarifying questions to complete the requirements, architecture, and acceptance criteria sections. Do NOT proceed to building until the user approves the spec.

8. **Show results**: Display the created directory tree and the filled-in SPEC.md. If `--team` was used, mention that the project uses tool-agnostic templates compatible with any AI assistant and the OpenSpec format.

9. **STOP.** This skill is done. Tell the user:
   > "Project scaffolded and SPEC.md drafted. Review the spec and let me know if you want changes. When ready, run `/plan` to create the implementation plan."

   Do NOT continue to brainstorming, planning, implementation, or any other skill. Do NOT invoke `/brainstorm`, `/plan`, or `/implement`. Do NOT write any code. Wait for the user's next instruction.

## Important Notes

- Do NOT run `git init`, `uv sync`, `npm install`, or any setup commands unless the user explicitly asks
- Do NOT start building the application — this skill ONLY scaffolds and writes the spec. The user decides what happens next.
- Do NOT modify `tasks/lessons.md` — it starts empty on purpose. Cross-cutting lessons are read from `~/.claude/lessons/cross-cutting.md` at review time, not duplicated into each project.
- The `src/` directory in the Python template should be renamed to the package name (e.g., `src/` → `envaudit/`)
- Ensure the `tests/` directory and placeholder test are included
- All `.template` suffixes must be stripped from the final files
- When using `--team`, the CLAUDE.md will NOT reference personal tools (/review, /reviewer agent, superpowers). This is intentional — team projects must work with any AI assistant.
