---
name: domain-reference
description: The domain theory this project encodes — the vocabulary, the invariants and the traps a general-purpose model gets wrong. Load before judging whether domain logic is correct.
---

# Domain reference

**Audience:** about to write or judge logic that depends on how this domain actually works,
rather than on how code is usually written.

This is a knowledge pack, not a how-to. It exists because a model will confidently produce
domain logic that is idiomatic and wrong, and the only defence is having the domain's rules
written where they will be read first.

## When NOT to use this skill

- How the domain is *implemented* here → the zone conventions skill for that area.
- Why the implementation was chosen →
  [`architecture-contract`](../architecture-contract/SKILL.md).

## Vocabulary

Each term defined exactly once, here.

| Term | Means | Does **not** mean |
| --- | --- | --- |
<!-- FILL. The third column is where the value is — most domain bugs are a term being used
     in its everyday sense inside code that needs its technical one. -->

## Invariants

Statements that are always true. If one is false, something upstream is already broken and
the fix is not local.

<!-- FILL: numbered, each with how it could be violated and what would be observable if it
     were. -->

## The traps

Where general-purpose intuition is wrong here.

<!-- FILL: the specific ones. Examples of the *shape*:
     - a representation choice whose obvious alternative silently loses precision
     - a boundary (a day, a period, a region) that is not where the code's default puts it
     - an operation that looks commutative and is not
     - a standard everyone half-remembers, with the clause everyone forgets
   For each: the intuition, why it is wrong, and what to do instead. -->

## Provenance and maintenance

<!-- FILL: the sources — standards, specifications, papers — with the date each was read.
     Domain facts drift slowly, but they do drift, and a standard has a version. -->
