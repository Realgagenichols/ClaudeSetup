# Claude Code Workflow Integration

How custom skills, kept superpowers, agents, OpenSpec-compatible spec format, and global CLAUDE.md work together as a unified system.

## The Core Principle

> **Custom skills define the core workflow. Superpowers provides standalone process discipline.**

Five custom skills (`/brainstorm`, `/plan`, `/implement`, `/review`, `/new-project`) handle the entire development chain with full project context — lessons, SPEC.md, CLAUDE.md conventions, and RFC 2119 awareness baked into every step. Superpowers skills are kept for standalone process discipline (TDD, debugging, verification, git worktrees, finishing branches) where they don't need project context.

## Priority Order

When instructions conflict:

1. **Your explicit instructions** (CLAUDE.md, direct requests) — highest
2. **Custom skills** — enforce your workflow with project context
3. **Superpowers skills** — standalone process discipline
4. **Default system prompt** — lowest

## Phase-by-Phase Breakdown

### Phase 1: Scaffold — `/new-project`

**Who leads:** Custom `/new-project` skill

The project starts with your template system. `/new-project` creates the directory structure, copies common + language templates, substitutes variables, and generates an initial SPEC.md interactively. With `--team`, it produces tool-agnostic output compatible with any AI assistant.

```
myapp/
├── SPEC.md              ← source of truth (RFC 2119 + Given/When/Then)
├── CLAUDE.md            ← project-specific guidance
├── tasks/
│   ├── todo.md          ← plan & progress tracking
│   └── lessons.md       ← starts empty, accumulates project-specific corrections
├── src/                 ← implementation
└── tests/               ← test suite
```

### Phase 2: Design — `/brainstorm`

**Who leads:** Custom `/brainstorm` skill (replaces superpowers:brainstorming)

Before any implementation, `/brainstorm` enforces a hard gate: read lessons first, explore context, ask clarifying questions, propose 2-3 approaches, present the design, and get user approval.

After approval:
- **Greenfield:** Updates SPEC.md directly with refined requirements (RFC 2119 keywords, requirement IDs, Given/When/Then scenarios)
- **Brownfield:** Creates a change folder (`changes/<name>/`) with proposal.md, delta specs (ADDED/MODIFIED/REMOVED), and design.md

After updating SPEC.md, `/brainstorm` also fills in the project `CLAUDE.md` Architecture section if it's still a placeholder — giving future sessions immediate architectural context.

The design document captures rationale and alternatives. SPEC.md captures what to build. Both are committed to git.

### Phase 3: Plan — `/plan`

**Who leads:** Custom `/plan` skill (replaces superpowers:writing-plans)

`/plan` reads lessons before planning, then creates bite-sized tasks (2-5 minutes each) with exact file paths, requirement ID references, and TDD discipline. Output goes to `tasks/todo.md` — the single location for task tracking. If `todo.md` already exists with completed tasks, it's archived first (`todo.YYYY-MM-DD.md`) to preserve the record of prior work.

Every task references SPEC.md requirement IDs (R1, R2, S1). If a task doesn't map to a requirement, it probably doesn't belong. The plan self-reviews against SPEC.md to verify every requirement and scenario is covered.

### Phase 4: Implement — `/implement`

**Who leads:** Custom `/implement` skill (replaces superpowers:subagent-driven-development)

`/implement` first validates that `tasks/todo.md` contains real tasks — if it's missing, has only template placeholders, or has no unchecked items, it stops and directs you to run `/plan` first.

A fresh subagent is dispatched per task with full context baked into the prompt template:
- Project conventions from CLAUDE.md
- Relevant lessons from `tasks/lessons.md` (re-read before EVERY dispatch, not just at the start)
- SPEC.md requirement IDs and scenarios for this task
- Brownfield context if applicable

Each subagent follows TDD (via superpowers:test-driven-development) and commits after implementation. When the implementer reports DONE, the orchestrator checks the Findings section for new patterns and captures them in `tasks/lessons.md` before proceeding.

**Per-task review cycle:** After each task, two reviewer subagents check the work:
1. **Spec reviewer** — RFC 2119 severity mapping (missing SHALL = CRITICAL, missing SHOULD = WARNING), scenario-level coverage checking
2. **Quality reviewer** — security, cross-cutting bug patterns from lessons, integration contracts, performance, code quality

If issues are found, the implementer fixes and re-reviews (max 2 iterations before escalating). New patterns discovered during review are captured in `tasks/lessons.md`. When all tasks for a requirement are complete, the requirement's checkbox in SPEC.md is checked off.

If bugs arise, superpowers' `systematic-debugging` skill provides structured root-cause analysis.

### Phase 5: Review — The 3-Stage Pipeline

**Who leads:** Custom skills + custom agent

After ALL tasks are complete, the full review pipeline runs:

```
Stage 1: Spec compliance (already completed per-task during /implement)
   └─ Final pass verifies every R/S requirement is implemented and every scenario tested

Stage 2: /reviewer agent (Opus, read-only, independent)
   └─ Fresh perspective — did NOT build this code
   └─ Reads SPEC.md + lessons.md + cross-cutting lessons dynamically
   └─ 8 check categories: spec, patterns, security, tests, integration, migration, performance, quality

Stage 3: /review --fix (context-aware final gate)
   └─ Runs automated checks (pytest, ruff)
   └─ Deep review with RFC 2119 severity and scenario coverage
   └─ Auto-fixes CRITICAL and WARNING issues
   └─ Updates SPEC.md checkboxes (checks off passing, unchecks failing)
   └─ Re-runs deep review after fixing to catch fix-introduced issues
```

### Phase 6: Verify — Evidence Before Claims

**Who leads:** Superpowers `verification-before-completion` skill

Identify the command that proves the claim, run it fresh, read full output, confirm it matches, THEN assert completion. No "should work" or "probably passes."

### Phase 7: Ship — Finish Branch

**Who leads:** Superpowers `finishing-a-development-branch` skill

For brownfield changes, `/implement` first merges delta specs into SPEC.md (preserving checkbox state) and archives the change folder to `changes/archive/YYYY-MM-DD-<name>/`. Then `superpowers:finishing-a-development-branch` presents 4 options: merge locally, push PR, keep branch, or discard.

After shipping: check if any lessons in `tasks/lessons.md` should be promoted to `~/.claude/lessons/cross-cutting.md` (criteria: same pattern in 2+ projects, or generically applicable).

## The Lessons Feedback Loop

This makes the system get smarter over time:

```
User correction / debugging resolution / review discovery
       ↓
Immediately update tasks/lessons.md
       ↓
Re-read before every subagent dispatch during /implement
       ↓
/brainstorm reads lessons before proposing designs
       ↓
/plan reads lessons and creates specific tasks for known patterns
       ↓
/reviewer agent reads lessons during independent review
       ↓
/review --fix reads lessons during final gate
       ↓
Promote to ~/.claude/lessons/cross-cutting.md when broadly applicable
       ↓
All skills read ~/.claude/lessons/cross-cutting.md dynamically at runtime
       ↓
New projects start informed by every past correction
```

## Spec Format (OpenSpec-Compatible)

Both personal and team modes use the same spec format so artifacts are interchangeable:

- **Requirements** use RFC 2119 keywords: SHALL (must), SHOULD (strongly recommended), MAY (optional)
- **Requirement IDs** (R1, S1, N1) enable traceability from spec → tasks → tests
- **Scenarios** use Given/When/Then format, mapping directly to test cases
- **Brownfield changes** use delta specs (ADDED/MODIFIED/REMOVED) in change folders

### Two Scaffolding Modes

| | Personal (default) | Team (`--team`) |
|---|---|---|
| Spec format | RFC 2119 + Given/When/Then + IDs | Same |
| Project CLAUDE.md | References /review, /reviewer, custom skills | Tool-agnostic concepts only |
| changes/ directory | Available for brownfield | Scaffolded with README |
| Compatible with | Claude Code + your custom setup | Any AI assistant |

A teammate can work on a `--team` project and hand it back to you — your tools understand the spec format. You can work with your full pipeline and hand it to them — they can read the specs and use their own tools.

## Quick Reference

| Workflow Step | Tool / Skill | Source |
|---|---|---|
| Scaffold project | `/new-project` | Custom skill |
| Design exploration | `/brainstorm` | Custom skill |
| Write design spec | SPEC.md (greenfield) or `changes/<name>/design.md` (brownfield) | Custom skill |
| Write implementation plan | `tasks/todo.md` | Custom skill (`/plan`) |
| Track progress | `tasks/todo.md` | Custom |
| Implement with TDD | `/implement` + `superpowers:test-driven-development` | Custom skill + Superpowers |
| Debug issues | `superpowers:systematic-debugging` | Superpowers |
| Review: spec compliance | Per-task spec reviewer (built into `/implement`) | Custom skill |
| Review: code quality | `/reviewer` agent (Opus) | Custom agent |
| Review: final gate + fix | `/review --fix` | Custom skill |
| Verify completion | `superpowers:verification-before-completion` | Superpowers |
| Ship / merge | `superpowers:finishing-a-development-branch` | Superpowers |
| Capture lessons | `tasks/lessons.md` | Custom |
| Promote lessons | `~/.claude/lessons/cross-cutting.md` | Custom |
| Isolated branches | `superpowers:using-git-worktrees` | Superpowers |
| Parallel work | `superpowers:dispatching-parallel-agents` | Superpowers |

## What Each System Contributes

**Custom skills provide (core workflow + project context):**
- `/brainstorm` — design gate with lessons-informed exploration, updates SPEC.md, brownfield support
- `/plan` — requirement-traced task breakdown in `tasks/todo.md`
- `/implement` — context-aware subagent orchestration with per-task reviews and lessons capture
- `/review` — RFC 2119 severity, scenario-level coverage, dynamic lessons, integration/migration/performance checks, auto-fix with re-verify
- `/new-project` — consistent scaffolding with team portability
- `/reviewer` agent — independent Opus reviewer with full project context
- Lessons system — 5 producers, 7 consumers, promotion pipeline, dynamic cross-cutting reads

**Superpowers provides (standalone process discipline):**
- TDD iron law — no production code before failing test
- Systematic debugging — root cause before fixes, 3-fail circuit breaker
- Verification — evidence before completion claims
- Git worktrees — isolated branches with setup verification
- Finishing branches — structured merge/PR options
- Parallel dispatch — independent tasks run simultaneously
- Receiving code review — technical evaluation, not blind agreement
