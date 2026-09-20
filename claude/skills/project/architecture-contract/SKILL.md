---
name: architecture-contract
description: The load-bearing design decisions of this project and what breaks if each is violated, plus the module and deployment dependency rules. Load when judging whether a proposed change is allowed.
---

# Architecture contract

**Audience:** about to evaluate a design change, or to decide whether a proposal is allowed
here at all.

<!-- FILL: one paragraph. What this system is, and the single constraint that shapes it. -->

This skill does not restate the rules — `CLAUDE.md` holds those, numbered, and it wins on
conflict. This says **what breaks when each one is violated**, which is the part that decides
arguments.

## When NOT to use this skill

- The procedure for making a change once it is allowed →
  [`change-control`](../change-control/SKILL.md).
- Why something already broke, and what was tried →
  [`failure-archaeology`](../failure-archaeology/SKILL.md).
- What "done" looks like → [`validation-and-qa`](../validation-and-qa/SKILL.md).

## What breaks if you violate it

Keyed to the numbered hard rules in `CLAUDE.md`. Never renumber here; if a rule moves,
this table moves with it in the same commit.

| Rule | What breaks | How you would find out |
| --- | --- | --- |
<!-- FILL: one row per hard rule. The middle column is the point of this file.
     Write the actual consequence, not "it would be inconsistent".
     Good:  "every stored amount is silently wrong by a fraction of a cent, and the
             error compounds across conversions with no way to reconstruct the original"
     Bad:   "money handling would be inconsistent" -->

## Module dependency contract

```
<!-- FILL: the arrows. Which module may import which, one line each.
     shared   <--  api
     shared   <--  web
     (nothing imports api) -->
```

Enforced by <!-- FILL: lint rule / test / nothing, and if nothing, say so plainly -->.

Enforced in **both directions** where both matter, and the two directions usually have
different reasons. Write each reason down — a rule whose reason is "symmetry" is a rule
someone will delete.

## Deployment contract

<!-- FILL: what runs where, what talks to what, and which of those hops is allowed to fail.
     Name the ones that are load-bearing:
     - which service holds a credential and which must not
     - which service can reach the database and which must not
     - what a push to the default branch actually does -->

## Protected values

Values that look like configuration and are not. Changing one is a migration, not an edit.

<!-- FILL: e.g. a currency exponent, a primary key strategy, a storage unit, a timezone
     policy, a public URL that other systems resolve. For each: what it is and what
     changing it would require. -->

## Known weak points

Said plainly, because a weak point nobody wrote down is a weak point that gets discovered
during an incident.

<!-- FILL: the places you already know are thin. Each with: what it is, what it costs today,
     and the condition that would make it worth fixing. It is fine for this list to be
     uncomfortable — that is the point. -->

## Provenance and maintenance

<!-- FILL: verified date, and what this was read against. -->
