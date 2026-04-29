---
name: review
description: "Review code for bugs, spec compliance, and quality. Usage: /review [--fix] [focus area]"
argument-hint: "[--fix] [security|tests|spec|quality]"
user-invocable: true
---

# Code Review

Perform an independent code review of the current project.

## Arguments

Parse `$ARGUMENTS`:
- **`--fix`** (optional): After reporting findings, automatically fix each issue. Without this flag, only report.
- **Focus area** (optional): Narrow the review to a specific concern. Examples: `security`, `tests`, `spec`, `quality`.

## Step 1: Gather Context

Read these files if they exist in the current project:
- `SPEC.md` — Requirements and acceptance criteria
- `tasks/lessons.md` — Known bugs and patterns to watch for
- `tasks/todo.md` — Current task status
- `CLAUDE.md` — Project-specific guidance

Also read the cross-cutting lessons (stable canonical location):
- `~/.claude/lessons/cross-cutting.md` — patterns distilled from all past projects

**Important**: Use patterns from `tasks/lessons.md` AND cross-cutting lessons dynamically — do NOT rely only on the hardcoded checklist below. The lessons files are the living source of truth for known bug patterns.

## Step 2: Identify Files to Review

- If this is a git repo: `git diff --name-only HEAD~5` to find recently changed files (adjust range as needed). Fall back to `git diff --name-only` for staged changes.
- If not a git repo: find all source files (`.py`, `.js`, `.ts`, etc.) excluding `.venv/`, `node_modules/`, `__pycache__/`.
- Read every file that will be reviewed.

## Step 3: Run Automated Checks

Run these commands and capture output:
- **Python projects**: `uv run pytest -v 2>&1` and `uv run ruff check . 2>&1`
- **Node projects**: `npm test 2>&1` and `npx eslint . 2>&1`
- Detect project type from `pyproject.toml` (Python) or `package.json` (Node).

Include test/lint results in the review — failing tests are CRITICAL findings.

## Step 4: Deep Review

Review all identified files against these checklists:

### Spec Compliance (if SPEC.md exists)

**RFC 2119 severity mapping** — requirements use keywords with distinct obligation levels:
- **SHALL / MUST** → missing implementation is **CRITICAL**
- **SHOULD** → missing implementation is **WARNING**
- **MAY** → missing implementation is **INFO** (note, not a defect)

For each requirement (R1, R2, etc.):
- Is it implemented?
- Does each Given/When/Then scenario have a corresponding test case? Check at the SCENARIO level, not just the requirement level. A requirement with only the happy-path scenario tested but edge-case scenarios missing is a WARNING.
- Are acceptance criteria met?
- Is anything built that's listed under "Out of Scope"?
- **Checkbox consistency**: Is the SPEC.md checkbox state accurate? A requirement checked off (`- [x]`) but NOT implemented or failing tests is CRITICAL. A requirement implemented and passing but NOT checked off should be flagged as WARNING (and fixed in `--fix` mode).

### Security
- No hardcoded secrets, API keys, passwords, or tokens
- No PII/PCI/NPI in log statements
- Environment variables for configuration
- Input validation at system boundaries

### Cross-Cutting Patterns (from lessons — read dynamically)
Check every pattern found in `tasks/lessons.md` and cross-cutting lessons files. Common patterns include:
- Regex specificity: substring collisions between patterns
- Business logic edge cases: valid real-world inputs incorrectly handled
- Context-sensitive classification: position/context ignored
- Platform portability: bash 4+ features, Python SSL on macOS
- Dependency pinning: ranges vs exact versions
- AI/LLM edge cases: prompt injection, hallucination handling
- Build system: hatchling package discovery, module naming
- UX/presentation: truncation, encoding, display edge cases

**Do not limit yourself to the list above** — read the actual lessons files and check every pattern found there.

### Test Quality
- Each detection rule / business logic function has positive AND negative tests
- Each Given/When/Then scenario from SPEC.md has a corresponding test
- Edge cases and regression scenarios covered
- Tests use factory fixtures, not real files/APIs
- No flaky tests depending on timing, network, or system state

### Integration & Contracts
- If multiple modules interact: are API contracts (function signatures, return types, error codes) consistent between caller and callee?
- Are there integration or end-to-end tests that exercise the assembled system, not just individual units?
- For HTTP/API endpoints: are request/response schemas validated? Are error responses consistent?
- For brownfield changes: do modified interfaces maintain backward compatibility with existing callers?

### Data & Migration (if persistent state exists)
- If database schema changes: is there a migration script? Is it reversible?
- Are stored data formats backward-compatible with the previous version?
- Config file changes: will existing configs still load correctly?
- Cache invalidation: will stale cached data cause issues after deployment?

### Performance & Scalability (check if applicable)
- Algorithms operating on collections: is the complexity appropriate for expected data sizes? Flag O(n^2) or worse on unbounded inputs.
- Database queries: N+1 query patterns, missing indexes on filtered/joined columns, unbounded SELECT without LIMIT
- Missing pagination on list endpoints or data retrieval
- Unbounded memory allocation (loading entire files/datasets into memory)

### Code Quality
- Unused imports, dead code
- Functions over 50 lines
- Error handling at appropriate levels
- Structured logging (no print() in production code)
- Resource cleanup (file handles, connections, cursors closed)
- Concurrency safety (if applicable): race conditions, deadlocks, missing timeouts

## Step 5: Report

Output a structured review report:

```
## Review Summary
- Files reviewed: N
- Automated checks: pytest [PASS/FAIL], ruff [PASS/FAIL]
- Issues found: X critical, Y warning, Z info

## CRITICAL
- **file.py:42** — [Issue title]
  [Why it matters]
  Fix: [Concrete suggestion]

## WARNING
- **file.py:15** — [Issue title]
  Fix: [Suggestion]

## INFO
- **file.py:8** — [Observation]

## Spec Coverage
For each requirement, show status and scenario coverage:
- [x] **R1** (SHALL): implemented in module.py, tested in test_module.py
  - [x] Scenario: happy path — test_module.py:15
  - [ ] Scenario: edge case — NOT FOUND ← WARNING
- [ ] **R2** (SHALL): NOT FOUND ← CRITICAL
- [x] **N1** (MAY): implemented — INFO (optional, not required)
```

## Step 6: Fix (only if `--fix` flag is present)

If `$ARGUMENTS` contains `--fix`:
1. For each CRITICAL and WARNING finding, apply the suggested fix
2. **Update SPEC.md checkboxes**: For any requirement that is now implemented with passing tests, check it off (`- [x]`). For any requirement previously checked off but now failing, uncheck it (`- [ ]`).
3. After all fixes, re-run the **full deep review** (Step 4) once to catch any issues introduced by the fixes
4. If the re-review finds new CRITICAL issues, fix those too and re-run automated checks
5. Report what was fixed, any new findings from re-review, and the final test/lint status
6. Do NOT fix INFO-level findings automatically

If `--fix` is NOT present, end after the report. Do not modify any files.
