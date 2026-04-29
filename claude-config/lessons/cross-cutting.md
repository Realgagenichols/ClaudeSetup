# Cross-Cutting Lessons

Recurring patterns that apply to any project regardless of language or domain. Seeded into new projects by `/new-project`, read by `/brainstorm`, `/plan`, `/implement`, `/review`, and `/reviewer` agent.

## How to Apply

For each pattern that applies to the current project, write at least one test covering the described edge case.

## Pattern 1: Overlapping Pattern Specificity

When applying multiple matching patterns of decreasing specificity to the same input (regex, URL routes, validation rules, classification tiers), ensure a more-specific match suppresses overlapping less-specific matches. Without this, the same input gets matched multiple times with conflicting results.

**Rule:** Track what's already been matched. Skip matches that fall within a region already captured by a more-specific pattern.

**Test:** Feed input that matches both a specific and a general pattern. Assert only the specific match is returned.

## Pattern 2: False Positives from Valid Data

Validation and detection logic will encounter legitimate data that superficially resembles invalid data. Promotions look like job overlaps. Partial answers look like incomplete responses. Nested structures look like duplicates.

**Rule:** For every detection/validation rule, ask: "What real-world data would this incorrectly flag?" Write a test for that case.

**Test:** Create data representing a legitimate scenario that superficially matches the detection criteria. Assert it is NOT flagged.

## Pattern 3: Context-Sensitive Classification

When classifying severity, priority, or category, the same signal can mean different things depending on where it appears. A warning in a header is different from a warning in a comment. A retry in an auth flow is different from a retry in a data sync.

**Rule:** Classification should consider position and context, not just the signal itself.

**Test:** Place the same signal in a suspicious context and a benign context. Assert different classifications.

## Pattern 4: Shell Portability

macOS ships bash 3.2 by default. Scripts using bash 4+ features (associative arrays with `declare -A`, `${var,,}` lowercase, `readarray`) will fail silently or error.

**Rule:** Avoid bash 4+ features in scripts that may run on macOS, or explicitly require bash 5+ with a version check. Prefix internal variables in sourced shell libraries to avoid name collisions with the calling script.

**Test:** Run scripts under bash 3.2 (or use `shellcheck` with `--shell=bash` targeting 3.2).

## Pattern 5: Dependency Version Pinning

Version ranges and branch-tip references introduce silent breakage. The most common break after a dependency upgrade is positional arguments changing to keyword-only.

**Rules:**
- Pin to exact releases, not ranges or branch tips
- After upgrading any dependency, check the changelog for breaking changes and grep your call sites for positional argument usage

**Test:** Verify the lockfile matches what's installed. Run the full test suite after any dependency change.

## Pattern 6: Error Handling and Fail-Fast

Silent error swallowing is the most common source of hard-to-debug production issues. Catching broad exceptions (`except Exception`), ignoring return codes, or defaulting to empty values on failure masks the real problem.

**Rules:**
- Validate inputs at system boundaries (user input, API responses, file reads) — fail loudly with a clear message
- Never catch broad exceptions without logging the specific error
- Prefer failing fast over returning defaults that hide errors

**Test:** Pass invalid input at every boundary. Assert the error message is specific and actionable, not a generic fallback.

## Pattern 7: Encoding and Unicode

String comparison, file I/O, and data serialization break silently when encoding assumptions are wrong. UTF-8 with BOM, mixed encodings in CSV files, and unnormalized Unicode (é vs e+combining accent) all cause subtle bugs.

**Rules:**
- Specify encoding explicitly when reading or writing files (`encoding='utf-8'`)
- Normalize Unicode strings before comparison (`unicodedata.normalize('NFC', s)`)
- When comparing user input to stored data, normalize both sides

**Test:** Include test data with non-ASCII characters, BOM prefixes, and composed vs. decomposed Unicode. Assert correct handling.

## Pattern 8: Concurrency and Shared State

Race conditions, TOCTOU (time-of-check-to-time-of-use) bugs, and unsynchronized shared state cause intermittent failures that are hard to reproduce.

**Rules:**
- If two operations must happen atomically, use a lock or transaction — not "it's fast enough"
- File operations: check-then-write is a race condition; use atomic write (write to temp, rename)
- Database: use transactions for multi-step operations; don't assume sequential execution

**Test:** Run concurrent operations against the same resource. Assert no data corruption or lost updates.
