---
name: plan
description: "Create an implementation plan from a spec. Usage: /plan [feature-name]"
argument-hint: "[feature or change name]"
user-invocable: true
---

# Plan

Create a detailed implementation plan from an approved SPEC.md or change folder, writing to `tasks/todo.md`.

## Arguments

Parse `$ARGUMENTS`:
- **Feature name** (optional): Which feature or change to plan. If omitted, plan from the current SPEC.md.

## Step 1: Read Context

Read these files before planning:
- `SPEC.md` — the approved requirements (source of truth)
- `tasks/lessons.md` — project-specific patterns to avoid
- `~/.claude/lessons/cross-cutting.md` — cross-cutting patterns
- `CLAUDE.md` — project conventions
- If brownfield: `changes/<name>/proposal.md` and `changes/<name>/specs/` for the delta spec. Note: the plan still goes to `tasks/todo.md` (not `changes/<name>/tasks.md`). The change folder holds proposal, delta specs, and design only — task tracking is always centralized in `tasks/todo.md`.

Lessons MUST influence the plan. If a lesson says "test regex collisions" and the feature involves regex, add a specific task for it.

## Step 2: Map Requirements to Tasks

For each SPEC.md requirement (R1, R2, S1, etc.) or delta spec entry (ADDED/MODIFIED):
1. Identify what implementation work is needed
2. Identify what tests are needed (one per Given/When/Then scenario minimum)
3. Break into bite-sized tasks (2-5 minutes each)
4. Group by feature area with hierarchical numbering

Every task MUST reference the requirement ID(s) it addresses.

## Step 3: Write Plan to `tasks/todo.md`

**Before writing:** Check if `tasks/todo.md` already exists with completed tasks (checked-off items). If so, archive it first by renaming to `tasks/todo.YYYY-MM-DD.md` (using today's date). If that archive file already exists (same-day re-plan), append a counter: `todo.YYYY-MM-DD-2.md`, `todo.YYYY-MM-DD-3.md`, etc. This preserves the record of prior work. Then write the new plan.

Write the plan using this format:

```markdown
# [project-name] — Task Plan

## 1. [Feature Area]
- [ ] 1.1 [Task description] — R1
- [ ] 1.2 [Task description] — R1
- [ ] 1.3 Write tests for R1 scenarios — R1

## 2. [Feature Area]
- [ ] 2.1 [Task description] — R2, R3
- [ ] 2.2 Write tests for R2 scenarios — R2
- [ ] 2.3 Write tests for R3 scenarios — R3

## 3. Integration & Polish
- [ ] 3.1 Integration test for [cross-module flow]
- [ ] 3.2 Error handling and edge cases — R1, R2
- [ ] 3.3 README.md with usage examples
- [ ] 3.4 Linter clean (zero warnings)

## Review
<!-- Results added after each section -->
```

**Rules:**
- Each task is small enough to implement and verify in one step
- Include exact file paths where known
- Include the test command to verify each task
- TDD: test tasks come immediately after their implementation task
- Commit after each completed task
- If a task doesn't map to a requirement, question whether it belongs

## Step 4: Plan Self-Review

Check the plan against SPEC.md:
1. **Coverage:** Is every R/S requirement addressed by at least one task?
2. **Scenario coverage:** Does every Given/When/Then scenario have a corresponding test task?
3. **Traceability:** Does every task reference a requirement ID?
4. **Ordering:** Are dependencies respected? (setup before implementation, implementation before tests is acceptable if TDD is applied within each task)
5. **Lessons:** Are known patterns from lessons.md addressed with specific tasks?
6. **Completeness:** No TBD, no vague tasks, no "figure out later"

If gaps found, fix them before presenting.

## Step 5: User Reviews Plan

> "Plan written to `tasks/todo.md`. Please review — each task references its SPEC.md requirement."

Wait for user approval. Apply changes if requested.

## Step 6: Offer Execution

Once approved:
> "Plan approved. Run `/implement` to start executing tasks with subagent-driven development, or work through the tasks manually."

## Key Principles

- **`tasks/todo.md` is the ONLY plan location** — never write to docs/superpowers/plans/ or other locations
- **Every task traces to a requirement** — if it doesn't, it shouldn't exist
- **Lessons shape the plan** — don't just acknowledge lessons, create specific tasks for them
- **Bite-sized tasks** — 2-5 minutes, one clear outcome, verifiable
- **Never use TodoWrite or TaskCreate** — file-based tracking only
