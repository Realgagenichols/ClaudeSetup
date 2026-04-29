---
name: implement
description: "Execute a plan with subagent-driven development. Usage: /implement"
argument-hint: ""
user-invocable: true
---

# Implement

Execute the plan in `tasks/todo.md` by dispatching a fresh subagent per task with two-stage review (spec compliance → code quality), followed by the full 3-stage review pipeline at the end.

## When to Use

- You have an approved plan in `tasks/todo.md` with requirement-traced tasks
- You want isolated context per task (prevents cross-contamination)
- You want structured review after each task

## Step 1: Load Context

Read these files:
- `tasks/todo.md` — the approved plan (source of truth for tasks)
- `SPEC.md` — requirements with RFC 2119 keywords and Given/When/Then scenarios
- `CLAUDE.md` — project conventions
- `tasks/lessons.md` — patterns to avoid
- `~/.claude/lessons/cross-cutting.md` — cross-cutting patterns
- If brownfield: the relevant `changes/<name>/` folder

Identify all pending tasks (unchecked items in todo.md).

**Validate the plan exists:** If `tasks/todo.md` is missing, contains only template placeholders (e.g., `[Primary feature]`, `[Requirement 1]`), or has no unchecked items, STOP and tell the user:
> "No actionable plan found in tasks/todo.md. Run `/plan` first to create an implementation plan from your SPEC.md."

## Step 2: Per-Task Execution Loop

For each pending task in `tasks/todo.md`:

### 2a. Prepare Subagent Context

**Re-read `tasks/lessons.md` before EVERY dispatch** — not just at the start. Lessons captured during prior tasks or review iterations must be available to the next subagent.

Build the implementer prompt using the template at `~/.claude/skills/implement/implementer-prompt.md`. Fill in:
- **Task name and description** from todo.md
- **Project conventions** from CLAUDE.md (logging rules, uv/ruff/pytest, no PII, env vars)
- **Relevant lessons** from tasks/lessons.md AND ~/.claude/lessons/cross-cutting.md that apply to this task (freshly read)
- **Requirement IDs and scenarios** from SPEC.md that this task addresses (include the RFC 2119 keyword)
- **Brownfield context** if applicable (change folder path, delta spec)

### 2b. Dispatch Implementer

Dispatch a subagent with the prepared prompt using the `Agent` tool.

**Model selection:**
- Simple/mechanical tasks (rename, move, boilerplate): default model
- Integration work (connecting modules, API wiring): default model
- Architecture decisions or complex logic: opus model

### 2c. Handle Implementer Response

| Status | Action |
|---|---|
| DONE | Check the Findings section of the report — if it contains new patterns or edge cases, capture them in `tasks/lessons.md` before proceeding. Then proceed to spec review. |
| DONE_WITH_CONCERNS | Read concerns AND Findings. Decide if concerns need attention before review. Capture any Findings as lessons. |
| NEEDS_CONTEXT | Provide requested context, re-dispatch |
| BLOCKED | Stop, report to user, ask for guidance |

### 2d. Spec Review

Dispatch a spec-reviewer subagent using `~/.claude/skills/implement/spec-reviewer-prompt.md`. The reviewer:
- Checks each requirement ID this task addresses
- Verifies Given/When/Then scenarios have tests
- Uses RFC 2119 severity: missing SHALL = CRITICAL, missing SHOULD = WARNING
- Does NOT trust the implementer's self-report — reads the code

If issues found: re-dispatch implementer with the findings → re-review. Max 2 iterations before escalating to user.

### 2e. Quality Review

Dispatch a quality-reviewer subagent using `~/.claude/skills/implement/quality-reviewer-prompt.md`. The reviewer checks:
- Code quality, security, test coverage
- Cross-cutting patterns from lessons
- Integration contracts, resource cleanup
- Performance red flags

If CRITICAL issues found: re-dispatch implementer → re-review. Max 2 iterations.

### 2f. Mark Complete

Update `tasks/todo.md`: check off the completed task (`- [x]`).

Then check SPEC.md: if ALL tasks referencing a requirement ID (e.g., R1) are now complete in todo.md, check off that requirement in SPEC.md (`- [x] **R1:**`). This keeps the spec's high-level progress in sync with granular task completion.

### 2g. Capture Lessons

If any review iteration found a pattern worth remembering (recurring issue, surprising edge case, project-specific gotcha), append it to `tasks/lessons.md` immediately. Don't wait for user correction.

### 2h. Next Task

Repeat from 2a for the next pending task.

## Step 3: Final Review Pipeline

After ALL tasks are complete, run the full 3-stage review pipeline:

1. **Stage 1 — Spec compliance**: Already done per-task. Do a final pass: read SPEC.md and verify every R/S requirement is implemented and every scenario has a test.

2. **Stage 2 — Quality review**: Dispatch the `/reviewer` agent using `Agent` tool with `subagent_type: "Reviewer"`. This is your independent Opus reviewer that reads SPEC.md, lessons.md, and cross-cutting lessons.

3. **Stage 3 — Final gate**: Run `/review --fix` for context-aware self-review with auto-fix.

If any stage finds issues, fix them and re-run that stage.

## Step 4: Finish

After the review pipeline passes:
- Update `tasks/todo.md` with a Review section summarizing results
- **Brownfield cleanup** (if a `changes/<name>/` folder exists for this work):
  1. Merge delta specs into main SPEC.md: ADDED requirements → append, MODIFIED → replace (preserve checkbox state from the existing SPEC.md for requirements already marked complete), REMOVED → delete
  2. Archive the change folder: `mv changes/<name>/ changes/archive/YYYY-MM-DD-<name>/`
  3. Verify SPEC.md is consistent after merge
- Invoke `superpowers:finishing-a-development-branch` for merge/PR options
- Check if any lessons should be promoted to `~/.claude/lessons/cross-cutting.md`

## Red Flags — STOP If You Notice

- Dispatching multiple implementers in parallel on the same codebase
- Skipping spec review or quality review "because the change is small"
- Marking a task complete without verifying tests pass
- Proceeding after 2 failed review iterations without escalating to user
- Using TodoWrite or TaskCreate instead of tasks/todo.md

## Model Guidance

| Task Type | Model |
|---|---|
| Mechanical (rename, boilerplate, config) | Default |
| Standard (feature implementation, test writing) | Default |
| Complex (architecture, multi-module integration, design decisions) | Opus |
| Per-task reviewers (spec, quality) | Default (prompts are self-contained) |
| `/reviewer` agent (Stage 2) | Opus (set in AGENT.md frontmatter) |
