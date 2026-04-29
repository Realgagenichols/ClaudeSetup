# Change Workflow

This directory holds proposed changes to the project. Each change gets its own folder with all planning artifacts together.

## When to Use Change Folders

- **Greenfield** (new project, empty SPEC.md): Edit SPEC.md directly
- **Brownfield** (modifying existing functionality): Create a change folder

## Creating a Change

```
changes/<change-name>/
├── proposal.md       ← Why this change, what's in/out of scope, impact
├── specs/            ← Delta specs (ADDED/MODIFIED/REMOVED requirements)
│   └── <area>.md
└── design.md         ← Technical approach, architecture decisions
```

Task tracking always lives in `tasks/todo.md` at the project root — not inside the change folder.

## Proposal Format

```markdown
# [Change Name]

## Why
[Motivation — what problem this solves, who benefits]

## What Changes
[Scope — what's being added, modified, or removed]

## Impact
[Affected areas — which specs, modules, and tests are touched]
```

## Delta Spec Format

Delta specs describe what's changing using three sections. Each requirement uses the same format as SPEC.md (RFC 2119 keywords + Given/When/Then scenarios).

```markdown
## ADDED

#### R4: [New requirement name]
The system SHALL [new behavior].

##### Scenario: [Test case]
- WHEN [action]
- THEN [outcome]

## MODIFIED

#### R1: [Existing requirement] (was: "[original description]")
The system SHALL [updated behavior].

##### Scenario: [Updated test case]
- WHEN [action]
- THEN [new expected outcome]

## REMOVED

#### R5: [Deprecated requirement]
Removed because: [rationale]
```

## Completing a Change

1. Implement all tasks in `tasks/todo.md`
2. Verify all new/modified scenarios pass as tests
3. Run code review
4. Merge delta specs into main SPEC.md:
   - ADDED requirements → append to SPEC.md
   - MODIFIED requirements → replace the original in SPEC.md
   - REMOVED requirements → delete from SPEC.md
5. Move the change folder to `changes/archive/YYYY-MM-DD-<name>/`
