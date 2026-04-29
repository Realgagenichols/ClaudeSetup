# Why We Don't Use OpenSpec CLI (And Why That's Fine)

## TL;DR

We evaluated OpenSpec and adopted its best ideas — RFC 2119 keywords, Given/When/Then scenarios, delta specs, change folders — directly into our template system. We get the same spec format with zero external dependencies, plus review, traceability, and learning capabilities that OpenSpec doesn't have.

## What We Adopted From OpenSpec

- **RFC 2119 keywords** (SHALL/SHOULD/MAY) for requirement precision
- **Given/When/Then scenarios** that map directly to test cases
- **Delta specs** (ADDED/MODIFIED/REMOVED) for brownfield changes
- **Change folder isolation** (proposal.md, specs/, design.md per change — task tracking stays in `tasks/todo.md`)
- **Archive workflow** with timestamped history

Our specs are format-compatible with OpenSpec. A teammate using the OpenSpec CLI produces specs we can work with, and vice versa.

## What We Have That OpenSpec Doesn't

| Capability | Our Setup | OpenSpec |
|---|---|---|
| Requirement IDs (R1, R2) with traceability | Enforced through every skill and review stage: spec → tasks → tests | Format supports it, tooling doesn't enforce it |
| Code review | 3-stage pipeline (per-task spec/quality review → independent Opus reviewer → auto-fix) | Single-pass verify |
| Learning from mistakes | lessons.md captured immediately, read by 7 consumers across all phases | Nothing |
| TDD enforcement | Mandatory test-first (superpowers:test-driven-development) | No process gates |
| Systematic debugging | Root-cause-first methodology with circuit breaker (superpowers:systematic-debugging) | Nothing |
| Security hooks | Secret detection, data classification, destructive command guards | Nothing |
| Subagent orchestration | Custom `/implement` skill: context-aware prompts, per-task reviews, lessons capture | Single-agent execution |

## Why Not Install It Anyway?

We evaluated three approaches with independent analysis agents:

1. **Native only** (what we chose) — zero dependencies, tighter integration, more rigorous format
2. **OpenSpec CLI only** — would lose our review pipeline, lessons loop, TDD, and security layer
3. **Both together** — creates duplicate change tracking (`changes/` vs `openspec/changes/`), dual spec sources of truth, and added complexity with no clear benefit

Even the evaluator tasked with arguing FOR OpenSpec concluded: *"OpenSpec's CLI is essentially a packaged version of the workflow you already built. Installing it would add a dependency to get less capability than you already have."*

## The Team Compatibility Question

Our `/new-project --team` flag scaffolds tool-agnostic projects that any AI assistant can work with. These use the same spec format (RFC 2119, Given/When/Then, delta specs) without referencing our specific tools. A teammate using OpenSpec, Cursor, Copilot, or plain Claude Code can work on these projects.

## When to Revisit

If OpenSpec adds:
- Formal requirement ID tracking and spec-to-test traceability
- Schema validation beyond YAML structure checks
- Automated test generation from Given/When/Then scenarios
- A learning/feedback mechanism

Until then, our native implementation is the more capable system.
