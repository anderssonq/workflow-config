---
name: validation-and-qa
description: What counts as proof here — the evidence bar, the acceptance commands, the QA matrix, and what a feature's tests must actually demonstrate. Load before calling anything done.
---

# Validation and QA

**Audience:** about to claim something works.

## When NOT to use this skill

- Reading someone's change for defects → the bank's `code-reviewer`. A review reads; this runs.
- Triaging a failure → [`debugging-playbook`](../debugging-playbook/SKILL.md).
- What "done" formally requires → `CLAUDE.md`'s Definition of Done, which wins on conflict.

## The evidence bar

**Verify, do not assume.** Four rules, each paid for:

1. **Never report something as working without running it.** Not "the image should build" —
   build it. Not "this endpoint returns 200" — curl it and paste the code.
2. **Measure, do not eyeball.** A number with a command next to it is evidence. An impression
   is not.
3. **Never retune a fixture to make a test pass.** Either the code is wrong or the assertion
   is wrong. Changing the input until it agrees is neither.
4. **A test that passes when the change is reverted does not cover the change.** Revert it and
   watch it fail, once, before trusting it.

## Acceptance commands

The exact sequence, in order, that must be green:

```bash
<!-- FILL: the real commands. This is the same gate CI runs — if the two lists differ,
     one of them is wrong. Note which step depends on which, e.g. a build that must
     precede tests because a package is consumed as built output. -->
```

## The QA matrix

Behaviour that varies along more than one axis is tested along all of them, not along the one
you happened to be looking at.

<!-- FILL: the axes for this project. Examples:
     - a UI: theme × locale × reduced-motion × viewport
     - an API: authenticated × anonymous × expired token × wrong owner
     - a CLI: tty × piped × no colour × non-zero exit
     Write the combinations that are actually checked, and say which are skipped and why. -->

## What a feature's tests must prove

| Layer | Minimum |
| --- | --- |
| Unit | The rule, including its boundary and its refusal path |
| Integration | The contract between two modules that changed |
| End-to-end | The new surface, once, through the real stack |

And the project-specific proofs that generic advice will not give you:

<!-- FILL. The valuable ones are the counter-intuitive proofs, e.g.
     "the seed is proven by seed → delete a row → seed, because an upsert-based seed
      passes a plain re-run and still destroys data"
     "the MCP package is proven to hold no database access by a test that greps its
      own dependency tree, four ways" -->

## Provenance and maintenance

<!-- FILL: verified date. -->
