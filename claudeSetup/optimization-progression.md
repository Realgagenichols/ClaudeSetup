# Claude Code Setup Optimization Progression

Six rounds of iterative analysis and improvement, using teams of four independent analyst agents per round. Each round read all files fresh and identified inefficiencies. Fixes were applied between rounds. This document captures what was found, what was fixed, and how the system evolved.

## Methodology

Each round dispatched **four independent analyst agents in parallel**, each with a unique prompt and analytical focus. They read many of the same files but looked for different classes of problems:

| Analyst | Focus | What They Look For |
|---|---|---|
| **Spec Flow** | Spec-driven development lifecycle | Information loss between phases, traceability gaps (spec → tasks → tests), requirements being silently dropped, handoff mismatches between skills |
| **Review Pipeline** | Code review and quality assurance | Bug classes that slip through all review stages, redundancy between stages, missing checks (integration, performance, migration), timing/ordering issues |
| **Subagent Orchestration** | Subagent context and handoffs | What context subagents don't receive, whether CLAUDE.md rules are enforced in prompt templates, TodoWrite conflicts, recovery from failures, handoff information loss |
| **Lessons Feedback** | Learning and feedback loop | Where lessons are written vs. read, whether the capture-to-prevention path works, cross-project propagation, stale/hardcoded patterns, promotion mechanisms |

**Convergence analysis** after each round identified findings flagged by 2+ analysts independently — these were treated as the highest-signal gaps, since independent observers reaching the same conclusion without coordinating is strong evidence of a real problem.

---

## Round 1: Baseline Analysis

**28 findings across 4 analysts. Everything needed work.**

The setup had a mature foundation (CLAUDE.md, /review skill, /reviewer agent, /new-project skill, templates, superpowers plugin) but the pieces weren't wired together.

### Critical Findings
| Gap | Impact |
|---|---|
| Spec requirements had no IDs — traceability impossible | Couldn't trace spec → task → test |
| Brainstorming created a separate design doc, never updated SPEC.md | Two sources of truth, SPEC.md went stale |
| Plans wrote to `docs/superpowers/plans/`, not `tasks/todo.md` | Two competing task locations |
| Superpowers skills used TodoWrite (banned by CLAUDE.md) | Direct conflict with file-based tracking |
| Lessons.md was written but rarely read | Write-only feedback loop |
| Hardcoded cross-cutting lessons path only worked for one project | Broken for all other projects |
| Superpowers reviewers had no project context awareness | Blind to SPEC.md, lessons, conventions |
| No brownfield change workflow existed | No way to modify existing specs cleanly |

### Fixes Applied
- Added requirement IDs (R1, R2) to SPEC.md template
- Added CLAUDE.md rules: brainstorming must update SPEC.md, plans reference R-IDs, lessons inform design
- Fixed hardcoded cross-cutting lessons path to dynamic glob
- Updated project CLAUDE.md template with review pipeline and lessons references

---

## Round 2: Format and Traceability

**24 findings. Format gaps and review tool gaps.**

### Critical Findings
| Gap | Impact |
|---|---|
| RFC 2119 keywords adopted but no reviewer understood severity | SHALL and MAY treated identically |
| No scenario-level coverage checking | Requirements "implemented" with only happy path tested |
| Brownfield workflow created but disconnected from superpowers and lessons | Parallel track, no integration |
| No re-verification after `/review --fix` applied changes | Fixes could introduce new bugs undetected |
| Cross-cutting lessons still hardcoded in reviewer/review/SPEC template | Stale snapshots, 3-5 of 8 patterns missing per artifact |

### Fixes Applied
- Updated `/review` skill: RFC 2119 severity mapping (SHALL→CRITICAL, SHOULD→WARNING, MAY→INFO), scenario-level checking, dynamic lessons reading, re-verify loop after --fix
- Updated `/reviewer` agent: same RFC 2119 mapping, scenario checks, dynamic lessons
- Added integration, migration, and performance checks to both review tools
- Added SHOULD section to SPEC.md template

---

## Round 3: Stable Lessons and Pre-Dispatch

**22 findings. Lessons path fragility and subagent context.**

### Critical Findings
| Gap | Impact |
|---|---|
| Cross-cutting lessons path fragile — nothing writes to it | Seeding and reading depended on a file nothing maintained |
| Debugging never captured lessons | Highest-volume lesson source, zero output |
| Subagent pre-dispatch context injection was honor-system | Orchestrator had to remember, nothing enforced it |

### Fixes Applied
- Created `~/.claude/lessons/cross-cutting.md` as stable canonical location with all 8 patterns
- Updated all tools (/review, /reviewer, /new-project) to use stable path
- Added debugging capture rule to CLAUDE.md
- Added explicit 5-item pre-dispatch checklist to CLAUDE.md
- Added lesson promotion workflow with criteria (2+ projects or generically applicable)

---

## Round 4: The Hard Floor

**20 findings. Mostly repeats of the superpowers plugin boundary.**

### Critical Findings
All four analysts flagged the same structural issue for the fourth consecutive round:
| Gap | Impact |
|---|---|
| Superpowers brainstorming never updates SPEC.md | CLAUDE.md rule exists but skill ignores it |
| Superpowers writing-plans saves to wrong location, no R-IDs | CLAUDE.md rule exists but skill ignores it |
| Superpowers subagent prompts have no context injection slots | Pre-dispatch checklist exists but templates don't acknowledge injected context |
| Superpowers reviewers lack RFC 2119 and lessons | Custom tools upgraded, plugin tools unchanged |
| Superpowers skills use TodoWrite | Banned by CLAUDE.md, impossible to prevent structurally |

### Assessment
These were initially labeled "unfixable" because the superpowers plugin files live in a cache directory managed by the plugin system. Editing them would be overwritten on update.

### Decision: Build Custom Replacements
Instead of accepting the limitation, we rebuilt the three problematic skills as custom skills in `~/.claude/skills/`:
- `/brainstorm` — replaces `superpowers:brainstorming`
- `/plan` — replaces `superpowers:writing-plans`
- `/implement` — replaces `superpowers:subagent-driven-development`

Each custom skill preserves the process discipline from superpowers while baking in full project context: lessons reading, SPEC.md updates, RFC 2119 awareness, requirement ID traceability, brownfield support, and todo.md tracking.

Three prompt templates were created for `/implement`:
- `implementer-prompt.md` — explicit sections for project conventions, lessons, requirement IDs, brownfield context
- `spec-reviewer-prompt.md` — RFC 2119 severity mapping, scenario-level checking
- `quality-reviewer-prompt.md` — self-contained full checklist (security, lessons, integration, migration, performance)

### CLAUDE.md Updated
Section 6 now routes to custom skills and lists which superpowers skills to keep (TDD, debugging, verification, git-worktrees, finishing-branch) vs. not use (brainstorming, writing-plans, subagent-driven-development).

---

## Round 5: Post-Custom-Skills Verification

**~18 findings. Refinement-level issues only.**

The custom skills resolved all major structural gaps. Remaining findings were:

| Gap | Fix Applied |
|---|---|
| Lesson promotion contradicted itself (two targets) | Clarified single target: `cross-cutting.md` with concrete criteria |
| `/brainstorm` auto-chained to `/plan` without user opt-in | Changed to offer, not auto-invoke |
| Brownfield `changes/<name>/tasks.md` vs `tasks/todo.md` split | Clarified: tasks always in `tasks/todo.md`, change folders hold proposal + specs + design only |
| Implementer prompt hardcoded Python commands | Added project type detection (Python/Node/other) |
| Model guidance table inconsistent with /reviewer agent model | Fixed table to show Opus for Stage 2 |

---

## Round 6: Final Verification

**4 analysts, 0 structural gaps found.**

| Analyst | Verdict |
|---|---|
| Spec flow | "The system is solid." |
| Review pipeline | "Ready for production use." |
| Subagent orchestration | "No real issues found. The system is coherent." |
| Lessons feedback loop | "The system is solid. No real findings." |

Two edge cases noted by the review analyst (not fixed, situational):
- No runtime smoke test gate (matters for server projects, less for CLI tools)
- No explicit cross-task interface drift detection during multi-task execution

One copy-paste artifact in `changes/README.md` and one model guidance table inconsistency — both fixed.

---

## Final System Architecture

### Custom Skills (fully owned, context-aware)
```
/new-project [--team] [--lang python] name "desc"
    → Scaffolds project with SPEC.md (RFC 2119 + Given/When/Then)
    → lessons.md starts empty (cross-cutting lessons read dynamically at runtime)
    → --team flag produces tool-agnostic, OpenSpec-compatible output
    → STOP after scaffolding — does not auto-continue to brainstorm/plan/implement

/brainstorm [topic]
    → Reads lessons before exploring
    → Updates SPEC.md with refined requirements (greenfield)
    → Fills in project CLAUDE.md Architecture section
    → Creates change folders with delta specs (brownfield)
    → Offers /plan when user approves (does not auto-invoke)

/plan [feature]
    → Reads lessons before planning
    → Archives existing todo.md if it has completed tasks (todo.YYYY-MM-DD.md)
    → Writes hierarchical tasks to tasks/todo.md with R-ID traceability
    → Self-reviews against SPEC.md for coverage gaps
    → Offers /implement when user approves

/implement
    → Validates plan exists (stops if todo.md is missing/placeholder/empty)
    → Fresh subagent per task with context-aware prompts
    → Processes implementer Findings into lessons on DONE (not just DONE_WITH_CONCERNS)
    → Per-task spec review (RFC 2119 severity + scenario-level)
    → Per-task quality review (full checklist including integration/performance)
    → Checks off SPEC.md requirements as tasks complete
    → 3-stage final review: /reviewer agent (Opus) → /review --fix
    → Brownfield: merges delta specs into SPEC.md (preserving checkboxes), archives change folder
    → Chains to superpowers:finishing-a-development-branch

/review [--fix] [focus]
    → RFC 2119 severity mapping (SHALL→CRITICAL, SHOULD→WARNING, MAY→INFO)
    → Scenario-level coverage (each Given/When/Then must have a test)
    → Checkbox consistency (checked but failing = CRITICAL, passing but unchecked = fix in --fix mode)
    → Dynamic lessons from tasks/lessons.md + cross-cutting.md
    → Integration, migration, performance, concurrency checks
    → Updates SPEC.md checkboxes in --fix mode
    → Re-verify loop after --fix applies changes
```

### Kept Superpowers Skills (standalone, process discipline)
- `superpowers:test-driven-development` — TDD iron law
- `superpowers:systematic-debugging` — root cause methodology
- `superpowers:verification-before-completion` — evidence before claims
- `superpowers:using-git-worktrees` — isolated branches
- `superpowers:finishing-a-development-branch` — merge/PR options
- `superpowers:dispatching-parallel-agents` — parallel independent work
- `superpowers:receiving-code-review` — technical evaluation of feedback

### Spec Format (OpenSpec-compatible)
- RFC 2119 keywords: SHALL (must), SHOULD (strongly recommended), MAY (optional)
- Requirement IDs: R1, R2, S1, N1
- Given/When/Then scenarios per requirement
- Delta specs for brownfield (ADDED/MODIFIED/REMOVED)
- Compatible with teammates using OpenSpec CLI or any AI assistant

### Lessons Lifecycle
```
User correction / debugging resolution / implementer Findings / review discovery
    → tasks/lessons.md (immediate capture)
        → Read by /brainstorm, /plan, /implement (before every dispatch), /review, /reviewer
        → Promote to ~/.claude/lessons/cross-cutting.md when:
            (a) pattern appears in 2+ projects, OR
            (b) pattern is generically applicable
                → Read dynamically at runtime by every skill (not seeded into projects)
```

### Review Pipeline (3 stages, mandatory)
```
Stage 1: Per-task during /implement
    → Spec reviewer (RFC 2119 + scenario coverage)
    → Quality reviewer (full checklist + dynamic lessons)

Stage 2: /reviewer agent (Opus, read-only, independent)
    → Whole-project review with full project context

Stage 3: /review --fix (context-aware final gate)
    → Automated checks + deep review + auto-fix
    → Updates SPEC.md checkboxes (checks off passing, unchecks failing)
    → Re-verify loop after fixes applied
```

## Key Metrics

| Metric | Round 1 | Round 6 |
|---|---|---|
| Total findings | 28 | 2 (1 typo, 1 doc inconsistency) |
| Structural gaps | 8 critical | 0 |
| Analysts saying "solid" | 0/4 | 4/4 |
| Lessons consumers | 2 (review time only) | 7 (every phase) |
| Lessons producers | 1 (user correction only) | 5 (corrections, debugging, reviews, implementers, promotions) |
| Spec format | Bare checkboxes | RFC 2119 + Given/When/Then + IDs |
| Traceability | None | Spec → tasks → tests, every layer |
| Superpowers plugin dependency | Full (blind) | Partial (standalone skills only, custom replacements for core workflow) |
| Team portability | None | --team flag, OpenSpec-compatible format |
