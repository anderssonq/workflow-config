---
name: change-control
description: How a change is classified, gated, committed and closed here — the non-negotiables with the evidence behind each, and the complexity gate. Load before starting any change.
---

# Change control

**Audience:** about to start a change, or about to decide whether one is worth making.

## When NOT to use this skill

- Whether the design is *allowed* → [`architecture-contract`](../architecture-contract/SKILL.md).
- What counts as proof that it works → [`validation-and-qa`](../validation-and-qa/SKILL.md).
- How to write the docs the change requires →
  [`docs-and-writing`](../docs-and-writing/SKILL.md).

## Classify first

| Class | Looks like | Gate |
| --- | --- | --- |
| Trivial | Typo, comment, a constant with no consumer | Definition of Done only |
| Local | One module, no public surface changed | DoD + the zone's conventions |
| Contract | A shared type, an endpoint, a schema, an env var | DoD + an ADR + both sides updated in one commit |
| Structural | A new module, a new dependency, a boundary moved | DoD + ADR + the complexity gate below |

Misclassifying downward is the common failure: a "small" change to a shared type is a
contract change, and it needs the ADR whether or not it is three lines.

## Definition of Done

Deferred to `CLAUDE.md`, which **wins on conflict**. Do not restate it here; two copies of a
DoD is how a project ends up with two.

## Non-negotiables

Each one has evidence behind it. A rule with no evidence column is a preference, and gets
argued with on every PR until it is dropped.

| Rule | Why | Evidence |
| --- | --- | --- |
<!-- FILL: the rules this project will not relitigate. The Evidence column names the
     incident, the ADR or the measurement. Example rows:
     | Never commit without asking | Parallel sessions share the working tree | F-07 |
     | No AI trailers in commit messages | Owner rule; overrides harness defaults | owner, 2026-05 | -->

## Commit discipline

See `playbooks/git-and-commits.md` for the full policy. The clauses that bite most often:

- **One commit per session or plan**, not per logical change.
- **Never commit without being asked.** Never push.
- **Never rewrite the working tree** — no `stash`, `checkout`, `restore`, `reset --hard`.
  Another session may be holding uncommitted work. Read old content with
  `git show HEAD:<path>`.

## The idea lifecycle

```
hunch  →  ADR  →  experiment  →  adopt, or retire with the reason
```

A hunch is free and lives in conversation. It becomes an ADR when someone would have to
undo work to reverse it. It becomes an experiment when the ADR names a falsifiable outcome.
**Retiring is a real ending** — write the reason down; an idea that quietly stops being
mentioned gets re-proposed in six months.

## The complexity gate

Before a structural change, answer all four in writing:

1. What is true today that makes this necessary? (Not "it would be cleaner".)
2. What is the smallest version that tests the claim?
3. What does this make harder later?
4. What would have to be true for us to undo it?

If (1) is a preference or (4) is "nothing, we would never undo it", the gate is not passed.

## Provenance and maintenance

<!-- FILL: verified date. -->
