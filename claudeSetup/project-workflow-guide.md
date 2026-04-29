# Project Workflow Guide

A complete how-to for the Claude Code development setup — from scaffolding a new project through shipping production-ready code.

## Quick Reference: The Commands

| Command | When to Use | What It Does |
|---|---|---|
| `/new-project [--team] [--lang python] name "desc"` | Starting a new project | Scaffolds files, writes initial SPEC.md |
| `/brainstorm [topic]` | Before any implementation | Explores design, reads lessons, updates SPEC.md |
| `/plan [feature]` | After SPEC.md is approved | Creates hierarchical tasks in `tasks/todo.md` with R-ID traceability |
| `/implement` | After plan is approved | Dispatches subagents per task, runs per-task reviews, then full pipeline |
| `/review [--fix] [focus]` | Before presenting work | Final review gate with RFC 2119 severity, scenario checks, auto-fix |

## The Full Lifecycle

```
/new-project → /brainstorm → /plan → /implement → /review → ship
                                         ↑              |
                                         └──── fix ─────┘
```

---

## Phase 1: Start a Project

### Personal Mode (default)
```
/new-project --lang python my-tool "CLI tool that scans repos for credential leaks"
```

This creates:
```
my-tool/
├── SPEC.md                  ← Source of truth (RFC 2119 + Given/When/Then)
├── CLAUDE.md                ← Project guidance (references your review pipeline, skills)
├── README.md
├── pyproject.toml           ← uv + ruff + pytest configured
├── my_tool/
│   ├── __init__.py
│   └── main.py              ← argparse entry point
├── tests/
│   ├── conftest.py          ← Factory fixtures
│   └── test_placeholder.py
└── tasks/
    ├── todo.md              ← Task plan (filled during /plan)
    └── lessons.md           ← Starts empty, accumulates project-specific corrections
```

The skill will ask you clarifying questions and write an initial SPEC.md draft. Review and approve before proceeding.

### Team Mode
```
/new-project --team --lang python api-gateway "REST API gateway for internal services"
```

Same structure, but:
- `CLAUDE.md` is tool-agnostic (no references to /review, /reviewer, or superpowers)
- `changes/` directory is scaffolded with a `README.md` explaining the brownfield workflow
- Compatible with any AI assistant (Claude Code, Cursor, Copilot, OpenSpec CLI)

### When to Use `--team`
- The project will be worked on by people who don't have your custom skills
- You want to share the project across different AI tools
- You're handing off to teammates

Specs are format-compatible between both modes. A teammate can work on a `--team` project and hand it back — your tools understand the format.

---

## Phase 2: Design (Brainstorm)

```
/brainstorm add user authentication
```

### What Happens
1. **Reads lessons** — `tasks/lessons.md` and `~/.claude/lessons/cross-cutting.md` before anything else. Past mistakes shape design.
2. **Explores context** — reads existing code, docs, recent commits
3. **Asks questions** — one at a time, prefers multiple choice
4. **Proposes 2-3 approaches** — with trade-offs and a recommendation
5. **Presents design** — section by section, asks for approval
6. **Updates SPEC.md** — with refined requirements using RFC 2119 keywords, requirement IDs, and Given/When/Then scenarios
7. **Fills in CLAUDE.md Architecture** — if the project's CLAUDE.md has a placeholder Architecture section, fills it with a summary of the approved design
8. **Writes design doc** — rationale and alternatives to `docs/design/`
9. **Self-reviews the spec** — checks for placeholders, contradictions, ambiguity
10. **You review** — make edits if needed, then run `/plan` when ready

### The Spec Format

After brainstorming, your SPEC.md looks like:

```markdown
## Requirements

### Must Have

#### R1: Credential scanning
The system SHALL scan repository files for hardcoded credentials.

##### Scenario: Detect AWS access key
- GIVEN a file containing `AKIA` followed by 16 alphanumeric characters
- WHEN the scanner processes the file
- THEN it reports a finding with file path, line number, and credential type
- AND the credential value is redacted in the output

##### Scenario: Skip binary files
- WHEN the scanner encounters a .jpg or .png file
- THEN it skips the file without error

### Should Have

#### S1: Incremental scanning
The system SHOULD support scanning only files changed since the last scan.

### Nice to Have

#### N1: Custom patterns
The system MAY support user-defined regex patterns.
```

**RFC 2119 keywords matter:**
- **SHALL/MUST** = mandatory, missing = CRITICAL in review
- **SHOULD** = strongly recommended, missing = WARNING in review
- **MAY** = optional, missing = INFO (noted, not a defect)

### Brownfield Changes

If you're modifying an existing project, `/brainstorm` detects this and creates a change folder:

```
changes/add-auth/
├── proposal.md        ← Why, what changes, impact
├── specs/
│   └── auth.md        ← Delta spec (ADDED/MODIFIED/REMOVED)
└── design.md          ← Technical approach
```

Delta specs describe what's changing:
```markdown
## ADDED
#### R4: Session management
The system SHALL create a session token on successful login.

## MODIFIED
#### R1: Startup (was: "system SHALL start on port 8080")
The system SHALL start on the port specified by $PORT, defaulting to 8080.

## REMOVED
(none)
```

---

## Phase 3: Plan

```
/plan add-auth
```

### What Happens
1. **Reads lessons** — before planning, checks for patterns that should become specific tasks
2. **Maps requirements to tasks** — every R/S requirement gets implementation + test tasks
3. **Archives old plan** — if `tasks/todo.md` exists with completed tasks, archives it to `tasks/todo.YYYY-MM-DD.md` (with counter for same-day re-plans) to preserve work history
4. **Writes `tasks/todo.md`** — hierarchical, numbered, with R-ID references
5. **Self-reviews against SPEC.md** — verifies every requirement and scenario is covered
6. **You review** — approve, then run `/implement`

### The Plan Format

```markdown
# my-tool — Task Plan

## 1. Core Scanning Engine
- [ ] 1.1 Implement file walker with binary detection — R1
- [ ] 1.2 Implement pattern matching engine — R1
- [ ] 1.3 Tests for R1 scenarios (detect AWS key, skip binary) — R1

## 2. Output Formatting
- [ ] 2.1 Implement finding report with redaction — R1
- [ ] 2.2 Tests for redaction scenarios — R1

## 3. Incremental Mode
- [ ] 3.1 Implement git-diff-based file filtering — S1
- [ ] 3.2 Tests for S1 scenarios — S1

## 4. Polish
- [ ] 4.1 Error handling and edge cases — R1, S1
- [ ] 4.2 README.md with usage examples
- [ ] 4.3 Linter clean (zero warnings)

## Review
<!-- Results added after each section -->
```

Every task traces to a requirement. If a task doesn't map to an R-ID, it probably doesn't belong.

---

## Phase 4: Implement

```
/implement
```

### What Happens

**First:** Validates that `tasks/todo.md` has real tasks — if it's missing, has only template placeholders, or has no unchecked items, stops and directs you to run `/plan` first.

For **each task** in `tasks/todo.md`:

1. **Dispatch implementer subagent** — fresh context with:
   - Task description and requirement IDs
   - Project conventions from CLAUDE.md
   - Relevant lessons from `tasks/lessons.md` AND `~/.claude/lessons/cross-cutting.md` (re-read before every dispatch)
   - SPEC.md scenarios for this task
   - Brownfield context if applicable
2. **Implementer builds** — follows TDD (test first, then implement), commits
3. **Process Findings** — checks the implementer's Findings section for new patterns, captures them in `tasks/lessons.md`
4. **Spec review** — a reviewer subagent checks:
   - Is each requirement for this task implemented?
   - Does each Given/When/Then scenario have a test?
   - RFC 2119 severity: missing SHALL = CRITICAL, missing SHOULD = WARNING
5. **Quality review** — another reviewer checks:
   - Security, cross-cutting bug patterns, test quality
   - Integration contracts, resource cleanup, performance
   - Dynamic patterns from lessons
6. **Fix loop** — if issues found, implementer fixes and re-reviews (max 2 iterations)
7. **Mark complete** — check off in `tasks/todo.md`, and if all tasks for a requirement are done, check off that requirement in SPEC.md
8. **Capture lessons** — any new patterns from review go to `tasks/lessons.md`

After **all tasks** complete, the 3-stage final review runs:

```
Stage 1: Already done per-task (spec + quality reviews)

Stage 2: /reviewer agent (Opus, read-only)
   → Independent whole-project review
   → Reads SPEC.md, lessons.md, cross-cutting lessons
   → Checks every requirement, scenario, pattern

Stage 3: /review --fix
   → Automated checks (pytest, ruff)
   → Deep review with RFC 2119 severity
   → Auto-fixes CRITICAL and WARNING issues
   → Updates SPEC.md checkboxes (checks off passing, unchecks failing)
   → Re-reviews after fixing
```

For brownfield changes, `/implement` then merges delta specs into SPEC.md (preserving checkbox state) and archives the change folder. Then chains to `superpowers:finishing-a-development-branch` for merge/PR options.

---

## Phase 5: Review

The review pipeline runs automatically at the end of `/implement`, but you can also invoke it standalone:

```
/review              # Report only
/review --fix        # Report + auto-fix critical/warning issues
/review security     # Focus on security only
/review tests        # Focus on test coverage only
```

### What It Checks

| Category | What It Looks For |
|---|---|
| **Spec Compliance** | Every R/S requirement implemented, every scenario tested, RFC 2119 severity |
| **Security** | No secrets/PII in code or logs, env vars for config, input validation |
| **Cross-Cutting Patterns** | Dynamic from `tasks/lessons.md` + `~/.claude/lessons/cross-cutting.md` |
| **Test Quality** | Positive + negative tests, scenario coverage, factory fixtures, no flaky tests |
| **Integration** | API contracts, backward compatibility, cross-module consistency |
| **Data/Migration** | Schema migrations, backward-compatible data formats, config compatibility |
| **Performance** | O(n^2) on unbounded inputs, N+1 queries, missing pagination, memory bounds |
| **Code Quality** | Dead code, long functions, error handling, logging, resource cleanup, concurrency |

### Severity Mapping

```
SHALL/MUST requirement missing  → CRITICAL (must fix before shipping)
SHOULD requirement missing      → WARNING (should fix before shipping)
MAY requirement missing         → INFO (noted, not a defect)
Failing tests                   → CRITICAL
Security issue                  → CRITICAL
Edge-case scenario not tested   → WARNING
```

---

## The Lessons System

Lessons are the mechanism that makes the system get smarter over time.

### Where Lessons Are Written

| Trigger | What Gets Written | Where |
|---|---|---|
| User corrects something | The correction pattern | `tasks/lessons.md` (immediately) |
| Debugging resolves a bug | Root cause pattern | `tasks/lessons.md` (immediately) |
| Review finds a new pattern | The pattern | `tasks/lessons.md` (by /implement) |
| Implementer discovers edge case | Noted in report | `tasks/lessons.md` (by orchestrator) |

### Where Lessons Are Read

| Consumer | When | What It Reads |
|---|---|---|
| `/brainstorm` | Step 1, before exploring | `tasks/lessons.md` + `cross-cutting.md` |
| `/plan` | Step 1, before planning | `tasks/lessons.md` + `cross-cutting.md` |
| `/implement` | Step 1 + each subagent dispatch | Both files, injected into prompts |
| `/review` | Step 1, before reviewing | Both files, applied as checklist |
| `/reviewer` agent | Before reviewing | Both files |

### Promotion

When a lesson applies beyond the current project:

```
tasks/lessons.md (project)
    ↓ promote when:
    ↓   (a) same pattern in 2+ projects, OR
    ↓   (b) generically applicable (platform, dependency, etc.)
    ↓ format: ## Pattern N: [Name] with Source, Rule, Test
    ↓
~/.claude/lessons/cross-cutting.md (global)
    ↓ read dynamically at runtime by:
    ↓
Every skill (/brainstorm, /plan, /implement, /review, /reviewer)
```

---

## Brownfield Changes (Modifying Existing Projects)

### When to Use Change Folders

- **Greenfield** (new project, empty SPEC.md): Edit SPEC.md directly with `/brainstorm`
- **Brownfield** (existing project, real requirements in SPEC.md): Create a change folder

### The Flow

1. `/brainstorm add-dark-mode` → creates `changes/add-dark-mode/` with proposal + delta specs + design
2. `/plan add-dark-mode` → writes tasks to `tasks/todo.md` referencing delta spec requirements
3. `/implement` → builds from the plan, reviews against the delta spec
4. When done: merge deltas into main SPEC.md, archive folder to `changes/archive/YYYY-MM-DD-add-dark-mode/`

### Delta Spec Format

```markdown
## ADDED
#### R4: [New requirement]
The system SHALL [behavior].
##### Scenario: [test case]

## MODIFIED
#### R1: [Changed requirement] (was: "[original]")
The system SHALL [updated behavior].
##### Scenario: [updated test case]

## REMOVED
#### R5: [Deprecated requirement]
Removed because: [rationale]
```

---

## Superpowers Skills (Kept)

These superpowers skills are used alongside your custom skills for process discipline:

| Skill | When It's Used |
|---|---|
| `superpowers:test-driven-development` | During implementation — RED (failing test) → GREEN (minimal code) → REFACTOR |
| `superpowers:systematic-debugging` | When a bug appears — root cause investigation before any fix |
| `superpowers:verification-before-completion` | Before claiming work is done — run the proof, read the output |
| `superpowers:using-git-worktrees` | When you need an isolated branch for feature work |
| `superpowers:finishing-a-development-branch` | After /implement completes — merge, PR, keep, or discard |
| `superpowers:dispatching-parallel-agents` | When 2+ independent tasks can run simultaneously |
| `superpowers:receiving-code-review` | When evaluating review feedback — technical rigor, not blind agreement |

---

## Security Layer

Your setup includes pre-tool hooks that run automatically:

| Hook | Trigger | What It Does |
|---|---|---|
| `classify_hook.py` | Before any file read | Data classification — blocks sensitive files |
| `detect-secrets.sh` | Before any file write/edit | TruffleHog scan — blocks secrets in code |
| `detect-secrets.sh` | Before any prompt submission | Blocks prompts containing credentials |
| Bash guard | Before any bash command | Blocks `rm -rf` and force-push to main/master |
| Permission deny list | Always | Prevents reading .env, .pem, .key, credentials, SSH keys, AWS configs |

These run for you and any subagents dispatched within the same session.

---

## Python Project Standards

| Tool | Purpose | Command |
|---|---|---|
| `uv` | Package management | `uv add <pkg>`, `uv run <cmd>`, `uv sync` |
| `ruff` | Linting | `uv run ruff check .`, `uv run ruff check --fix .` |
| `pytest` | Testing | `uv run pytest -v` |
| Factory fixtures | Test data | In `conftest.py` — no real files/APIs/databases |
| `@pytest.mark.regression` | Regression tests | Mark tests that cover bugs caught by review |

---

## File Reference

### Global (your `~/.claude/` directory)

| File | Purpose |
|---|---|
| `CLAUDE.md` | Global instructions — workflow, principles, tool standards |
| `settings.json` | Model config, hooks, plugins, permissions |
| `skills/brainstorm/SKILL.md` | Design exploration skill |
| `skills/plan/SKILL.md` | Implementation planning skill |
| `skills/implement/SKILL.md` | Subagent-driven execution skill |
| `skills/implement/implementer-prompt.md` | Subagent prompt template |
| `skills/implement/spec-reviewer-prompt.md` | Spec review template |
| `skills/implement/quality-reviewer-prompt.md` | Quality review template |
| `skills/review/SKILL.md` | Code review skill |
| `skills/new-project/SKILL.md` | Project scaffolding skill |
| `agents/reviewer/AGENT.md` | Independent Opus reviewer agent |
| `lessons/cross-cutting.md` | Cross-cutting patterns (8 patterns from past projects) |
| `templates/common/` | Shared templates (SPEC.md, CLAUDE.md, tasks/) |
| `templates/team/` | Team-mode overlay (tool-agnostic CLAUDE.md, changes/) |
| `templates/python/` | Python templates (pyproject.toml, src/, tests/) |

### Per-Project

| File | Purpose |
|---|---|
| `SPEC.md` | Source of truth — RFC 2119 requirements + Given/When/Then scenarios |
| `CLAUDE.md` | Project-specific guidance and conventions |
| `tasks/todo.md` | Implementation plan with R-ID-traced tasks |
| `tasks/lessons.md` | Project-specific corrections and patterns (starts empty, accumulates during development) |
| `changes/` | Brownfield change folders (proposal + delta specs + design) |
| `changes/archive/` | Completed changes with timestamps |
| `docs/design/` | Design documents from brainstorming |
