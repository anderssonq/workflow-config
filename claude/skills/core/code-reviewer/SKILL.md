---
name: code-reviewer
description: Senior-level review of a diff or branch — correctness, security, performance, tests, and the conventions the project itself declares. Load when reviewing a PR, a branch or staged changes.
---

# Code review

**Audience:** reviewing someone's change (or your own) before it merges.

A review is a search for the specific way *this* change breaks, not a recitation of general
advice. Findings that cannot be turned into an edit are noise.

## When NOT to use this skill

- Writing the PR description → [`pr-description-generator`](../pr-description-generator/SKILL.md).
  Review first, then write; the review is the material.
- Deciding whether the change is allowed at all → the project's `architecture-contract` and
  `change-control` skills.
- Checking that it *works* → the project's `validation-and-qa` skill. A review reads; QA runs.

## Before reading a single line

1. **Find the base.** `git merge-base --fork-point origin/main HEAD`, falling back to
   `origin/main` when the reflog is gone.
2. **Read the project's own law first** — `CLAUDE.md`, the zone's `SKILL.md`, the nearest
   `ARCHITECTURE.md`. A convention you invent is a finding the author will correctly reject.
3. **Size the change.** `git diff --stat $BASE...HEAD`. A 40-file diff with one real change
   and 39 renames is reviewed differently from a 3-file diff that touches auth.

## What to look for, in priority order

**1. Correctness — the finding must name inputs and the wrong output.**
"This could break" is not a finding. "With `items: []` this returns `undefined` and line 40
dereferences it" is.
- Off-by-one, empty collection, single element, and the boundary the author tested at.
- `null` / `undefined` reaching a dereference.
- Async: unawaited promises, races between two writers, cleanup that runs after unmount.
- Error paths: a `catch` that swallows, a retry with no ceiling, a partial write with no
  rollback.

**2. Security**
- Input that reaches a query, a shell, a path or a template without validation.
- Authorization checked at the wrong layer — or checked once and assumed thereafter.
- Secrets in logs, in errors, in client bundles, in commits.
- A new dependency: who owns it, when was it last released, what does it pull in.

**3. Data and performance**
- A query inside a loop (N+1), a `SELECT *` on a wide table, a missing index on a new filter.
- Unbounded growth: a list that never paginates, a cache with no eviction, a log that never
  rotates.
- Work moved to the client that was cheaper on the server, or the reverse.

**4. Tests**
- Does a test fail if the change is reverted? If not, the test does not cover the change.
- Are the *edge* cases tested, or only the path the author already knew worked?
- **A fixture retuned to make a test pass is a finding, not a fix.**

**5. Conventions and simplification**
- Does this reimplement something the repo already has? Search before accepting a new helper.
- Is a rule living in a component that belongs in a pure module where it can be tested?
- Naming, error shape, module boundaries — against the project's declared conventions only.

## Reporting

Order by severity, most severe first. For each finding:

```
file.ts:120  [correctness]
The claim in one sentence.
Failure: with <concrete input/state>, <concrete wrong result>.
```

- **Verify before reporting.** Open the file and confirm the surrounding code actually does
  what the diff suggests. A confident wrong finding costs more than a missed one.
- Say when you found nothing. "No correctness issues; two simplifications below" is a result.
- Separate *must fix* from *worth considering*. Mixing them makes the reviewer the bottleneck.

## Provenance and maintenance

Rewritten 2026-09-20. It replaces a generated scaffold whose three helper scripts and three
reference files were identical boilerplate that returned `{'status': 'success', 'findings': []}`
— they were deleted in the same commit rather than implemented, because the skill's value was
always the prompt, never the tooling.
