---
name: brainstorm
description: "Explore ideas and design before implementation. Usage: /brainstorm [topic]"
argument-hint: "[topic or feature description]"
user-invocable: true
---

# Brainstorm

Explore ideas, design solutions, and refine specs before any code is written.

<HARD-GATE>
Do NOT write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY task regardless of perceived simplicity.
</HARD-GATE>

## Arguments

Parse `$ARGUMENTS`:
- **Topic** (optional): Description of what to brainstorm. If omitted, ask the user.

## Process

### Step 1: Read Lessons and Context

**Before anything else**, read these files if they exist:
- `tasks/lessons.md` — project-specific corrections and patterns
- `~/.claude/lessons/cross-cutting.md` — cross-cutting patterns from all past projects
- `SPEC.md` — current requirements (if modifying existing project)
- `CLAUDE.md` — project conventions

Past mistakes MUST inform design decisions. Do not propose approaches that repeat known patterns from lessons.

### Step 2: Determine Greenfield vs. Brownfield

- **Greenfield** (new feature, SPEC.md requirements are empty/placeholder): design will update SPEC.md directly
- **Brownfield** (modifying existing functionality, SPEC.md has real requirements): create a change folder at `changes/<change-name>/` with proposal.md and delta specs

### Step 3: Explore Project Context

Check files, docs, recent commits. Understand what exists before proposing changes. Follow existing patterns.

### Step 4: Ask Clarifying Questions

- One question at a time — do not overwhelm
- Prefer multiple choice when possible
- Focus on: purpose, constraints, success criteria, edge cases
- For brownfield: what's changing and why, what should NOT change

### Step 5: Propose 2-3 Approaches

- Present options conversationally with trade-offs
- Lead with your recommended option and explain why
- Reference any lessons that influenced your recommendation
- Apply YAGNI ruthlessly — remove unnecessary features

### Step 6: Present Design

Present the design in sections scaled to complexity:
- Architecture and components
- Data flow
- Error handling
- Testing approach (reference Given/When/Then scenarios)
- Ask after each section whether it looks right

### Step 7: Update SPEC.md (Greenfield) or Create Delta Spec (Brownfield)

**Greenfield:** Update the project's SPEC.md with the approved design:
- Requirements use RFC 2119 keywords (SHALL/SHOULD/MAY) with IDs (R1, R2, S1, N1)
- Each requirement has at least one Given/When/Then scenario
- Architecture section reflects the design decisions
- Acceptance criteria are specific and testable

**Brownfield:** Create change folder:
```
changes/<change-name>/
├── proposal.md        ← Why, What Changes, Impact
├── specs/
│   └── <area>.md      ← Delta spec (ADDED/MODIFIED/REMOVED)
└── design.md          ← Technical approach
```
Delta specs use ADDED/MODIFIED/REMOVED sections with the same RFC 2119 + scenario format.

### Step 7b: Fill in Project CLAUDE.md Architecture

If the project's `CLAUDE.md` has an empty or placeholder Architecture section (`<!-- Fill in after SPEC.md is finalized -->`), fill it in now with a concise summary of the architecture from the approved design: key components, their responsibilities, and how they interact. This gives future sessions immediate architectural context.

### Step 8: Write Design Document

Save the design rationale (the WHY behind decisions, alternatives considered):
- Greenfield: `docs/design/<topic>-design.md`
- Brownfield: `changes/<change-name>/design.md`

Commit the design document to git.

### Step 9: Spec Self-Review

After writing, review with fresh eyes:
1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections? Fix them.
2. **Internal consistency:** Do sections contradict each other?
3. **Scope check:** Focused enough for a single implementation plan?
4. **Ambiguity check:** Could any requirement be interpreted two ways? Pick one.
5. **Lessons check:** Does any requirement conflict with a known lesson?

### Step 10: User Reviews

> "Spec written and committed. Please review and let me know if you want changes before we start planning."

Wait for user response. If changes requested, apply them and re-run self-review.

### Step 11: Offer Planning

Once the user approves:
> "Spec approved. Run `/plan` when you're ready to create the implementation plan, or edit SPEC.md further first."

Do NOT auto-invoke `/plan`. The user may want to review or edit SPEC.md before planning begins.

## Key Principles

- **One question at a time** — don't overwhelm
- **YAGNI ruthlessly** — remove unnecessary features
- **Lessons inform design** — past mistakes shape current decisions
- **SPEC.md is the source of truth** — always update it, don't leave a separate design doc as the only record of requirements
- **Brownfield uses change folders** — delta specs, not in-place SPEC.md edits for existing functionality
