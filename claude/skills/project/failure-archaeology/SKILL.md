---
name: failure-archaeology
description: The append-only chronicle of fought-and-settled battles here — incidents, rejected designs with their revisit conditions, the WATCH list, and the probe method. Load before an upgrade, a revert, or reopening a settled design.
---

# Failure archaeology

**Audience:** about to propose a fix, a revert, a refactor, a dependency change or an
upgrade. Read this first. Most of those proposals have been made before.

This file exists because the alternative is rediscovering the same dead end every few months,
each time at full cost. It is **append-only**: entries are added, never rewritten, because an
entry that gets edited to look smarter stops being evidence.

## When NOT to use this skill

- Triaging something broken *right now* →
  [`debugging-playbook`](../debugging-playbook/SKILL.md). This is history; that is triage.
- A decision that was made and stands → `DECISIONS.md`.
- A rule and what breaks if you violate it →
  [`architecture-contract`](../architecture-contract/SKILL.md).

## Part 1 — Incident chronicle

One entry per named incident, numbered `F-01`, `F-02`, … Never renumbered, never removed.

```markdown
### F-07 — The seed restored an account the owner had deleted

**When:** 2026-08-14. **Surface:** production migrate step.
**What happened:** the seed was written to be idempotent, so it upserted. In production it
ran on every deploy and recreated a row the owner had deliberately removed.
**Root cause:** "idempotent" was read as "safe to re-run", when it meant "converges to the
seed's view of the world" — which is not the same thing once a human has edited the data.
**Settled by:** the seed is bootstrap-only in production, gated on an empty table.
**Revisit if:** a real data-migration mechanism exists that is not the seed.
```

The two lines that carry the value are **Root cause** and **Revisit if**. A chronicle of
symptoms teaches nobody anything.

<!-- FILL: the incidents. Start at F-01 with the oldest one you still remember clearly. -->

## Part 2 — Settled design battles

Designs that were considered and rejected, each with the condition that would reopen it.
Without that condition this section reads as dogma and gets ignored.

| Rejected | Why it lost | Revisit if |
| --- | --- | --- |
<!-- FILL -->

## Part 3 — The WATCH list

Time bombs. Things that work today and will not forever.

| What | Why it is a bomb | Trips when |
| --- | --- | --- |
<!-- FILL: e.g. a 32-bit column that a growing value will overflow; a pinned version whose
     upstream is EOL; a rate limit you are at 60% of; a certificate. -->

## Part 4 — The probe method

Before adopting anything on the strength of its documentation, prove it here, cheaply:

1. **State the claim as a falsifiable sentence.** "Upgrading X keeps Y working" — not
   "upgrading X should be fine".
2. **Find the smallest thing that would be false if the claim is false.** Usually one command
   or one file, not a branch.
3. **Run it and record the output**, with the date, in this file.
4. **If the claim fails, the entry stays.** A failed probe is the most valuable kind: it is
   the reason the next person does not spend a day on it.

A probe takes minutes. The upgrade it prevents takes days.

## Provenance and maintenance

<!-- FILL: verified date. -->
