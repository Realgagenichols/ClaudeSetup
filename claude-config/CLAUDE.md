## Workflow Orchestration

### 1. Plan mode default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decision)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building 
- Write detailed specs upfront to reduce ambiguity 
- If you are not absolutely sure of your solution do more research
- Always check API document if they're available 

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate in these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, run linter, demonstrate correctness
- Use `/review` to perform an independent code review before presenting work
- Use `/review --fix` to auto-apply fixes for critical and warning-level issues

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it

### 6. Custom Workflow Skills + Superpowers
Custom skills handle brainstorming, planning, and implementation with full project context. Superpowers handles standalone process skills.

- **Use custom skills for the core workflow:**
  - `/brainstorm` — design exploration (replaces superpowers:brainstorming). Reads lessons, updates SPEC.md, supports brownfield change folders.
  - `/plan` — implementation planning (replaces superpowers:writing-plans). Writes to `tasks/todo.md` with requirement ID traceability.
  - `/implement` — subagent-driven execution (replaces superpowers:subagent-driven-development). Context-aware prompts, built-in review pipeline.
  - `/review [--fix]` — 3-stage final review gate with RFC 2119 severity and scenario-level checking.
- **Keep superpowers for standalone skills:** `superpowers:test-driven-development`, `superpowers:systematic-debugging`, `superpowers:verification-before-completion`, `superpowers:using-git-worktrees`, `superpowers:finishing-a-development-branch`, `superpowers:dispatching-parallel-agents`, `superpowers:receiving-code-review`.
- **Do NOT use** superpowers:brainstorming, superpowers:writing-plans, or superpowers:subagent-driven-development — the custom skills replace these with full project context awareness.
- **Review pipeline (3 stages) — MANDATORY before presenting work as complete:**
  1. **Spec compliance** — per-task spec review during `/implement` (built into the skill)
  2. **Quality review** — dispatch the `/reviewer` agent (Opus, read-only) using `Agent` with `subagent_type: "Reviewer"`
  3. **Final gate** — run `/review --fix` for context-aware self-review with auto-fix
- **Task tracking**: Use `tasks/todo.md` ONLY. Never use TaskCreate, TaskUpdate, or TodoWrite.
- **Lessons capture**: After ANY correction or debugging resolution, immediately update `tasks/lessons.md`. Every bug is a lesson.
- **Lesson promotion**: Promote to `~/.claude/lessons/cross-cutting.md` when: (a) the same pattern appears in 2+ projects, OR (b) the pattern is generic enough to apply to any project (e.g., platform portability, dependency pinning). Match the existing format: `## Pattern N: [Name]` with Source, Rule, and Test sections. Check for duplicates before adding.

## Project Creation

### New Projects
- Use `/new-project` to scaffold from templates: `/new-project [--team] [--lang python] name "description"`
- `--team` flag produces tool-agnostic, OpenSpec-compatible projects for team collaboration
- Templates live at `~/.claude/templates/` (common + team + language-specific layers)
- Every new project gets a `SPEC.md` — this is the source of truth for requirements

### SPEC-Driven Development
- Write `SPEC.md` before building. Requirements use RFC 2119 keywords (SHALL/SHOULD/MAY) with IDs (R1, R2). Each requirement has Given/When/Then scenarios that map directly to tests.
- Build from the spec. Check requirements off as scenarios pass.
- "Out of Scope" section in SPEC.md prevents feature creep
- Acceptance criteria must include: all scenario tests pass, linter clean, all R-requirements covered

### Brownfield Changes
- For modifying existing projects, use change folders: `changes/<change-name>/` with proposal.md, specs/ (delta), design.md. Task tracking stays in `tasks/todo.md` — not inside the change folder.
- Delta specs use ADDED/MODIFIED/REMOVED sections — each with the same RFC 2119 + scenario format as SPEC.md
- When the change is complete: merge deltas into main SPEC.md, archive the change folder to `changes/archive/YYYY-MM-DD-<name>/`
- Design docs for brownfield changes live in `changes/<name>/design.md` (co-located with the change, not in docs/superpowers/specs/)
- **Lessons in brownfield changes**: Read `tasks/lessons.md` before writing the proposal or delta spec. After the change is complete and archived, capture any new lessons learned during the change.

## Task Management
### MANDATORY — DO NOT USE BUILT-IN TASK TOOLS INSTEAD
- **Do NOT use TaskCreate/TaskUpdate** for tracking work. Use the file-based system below.
- These files live in the **project directory** (not a global folder): `<project>/tasks/todo.md` and `<project>/tasks/lessons.md`
- Each project gets its own `tasks/` folder. Lessons are project-specific. If a lesson applies broadly, promote it to `~/.claude/lessons/cross-cutting.md` (the canonical location — NOT this file).

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go in `tasks/todo.md`
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after EVERY user correction — not at end of session, immediately

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
- **Logging**: Logging is very important. It should be well structured. We must NEVER log PCI, PII, NPI, keys, passwords, or secrets

## Scripts

### 1. Python
- Favor using environment variables over CLI flags for secrets and things we would expect to always be set
- Create a README.md for projects and keep it updated
- **uv for package management**:
  - Use `uv add <pkg>` to add dependencies, `uv run` to execute
  - Do not create `requirements.txt` — `pyproject.toml` + `uv.lock` replace it
  - Match project structure to complexity: flat scripts for simple tools, package directory with build-system for multi-module projects
- **ruff for linting**: All projects use ruff. Run `uv run ruff check .` before marking work complete. Auto-fix with `uv run ruff check --fix .`
- **pytest for testing**: Factory fixtures in `conftest.py` — build test data without real files/APIs/databases. Mark regression tests with `@pytest.mark.regression`
