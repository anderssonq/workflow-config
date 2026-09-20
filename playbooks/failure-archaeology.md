# Failure archaeology

Why a project keeps a chronicle of its own dead ends, and how to write one.

## The problem it solves

Without a record, every settled question reopens on a schedule. Someone proposes the library
that was tried and rejected. Someone "fixes" the weird configuration that is weird for a
reason. Someone upgrades the pinned dependency that is pinned because of an incompatibility
nobody wrote down.

Each of those costs the same as the first time, and the person paying has no way to know
they are repeating anything. The chronicle is the only cheap defence.

## Append-only, and why that matters

Entries are added. They are never rewritten to look smarter in hindsight.

An edited entry stops being evidence of **what was known at the time**, which is the only
thing that makes it useful. "We chose X because Y was not available yet" is a different fact
from "we chose X", and the first one is the one that tells you whether to reconsider.

## The entry

```markdown
### F-07 — The seed restored an account the owner had deleted

**When:** 2026-08-14. **Surface:** production migrate step.
**What happened:** the seed was written to be idempotent, so it upserted. In production it
ran on every deploy and recreated a row the owner had deliberately removed.
**Root cause:** "idempotent" was read as "safe to re-run", when it meant "converges to the
seed's view of the world" — which stops being the same thing the moment a human edits the data.
**Settled by:** the seed is bootstrap-only in production, gated on an empty table.
**Revisit if:** a real data-migration mechanism exists that is not the seed.
```

Two lines carry the value:

- **Root cause** — the misunderstanding, not the symptom. A chronicle of symptoms teaches
  nobody anything, because the next symptom looks different.
- **Revisit if** — without it the entry reads as dogma, and dogma gets ignored by the first
  person who disagrees with it.

Numbered `F-01`, `F-02`, and never renumbered. A reference to `F-07` in a comment or a skill
has to keep resolving.

## Settled design battles

A separate section, same discipline: what was considered, why it lost, and what would reopen
it. This is where "we thought about a plugin system and decided against it" lives, so that it
is a decision rather than an oversight.

Rejections without a revisit condition become folklore. Folklore gets overturned by whoever
is most confident that day.

## The WATCH list

Things that work today and will not forever.

| What | Why it is a bomb | Trips when |
| --- | --- | --- |
| A 32-bit column | The value grows monotonically | It crosses 2³¹ |
| A pinned major | Upstream is EOL | A CVE lands with no backport |
| A rate limit at 60% | Traffic grows | Growth continues |

The value of the third column is that it turns anxiety into a trigger. A bomb with a named
trip condition is something you can monitor instead of worry about.

## The probe method

Before adopting anything on the strength of its documentation, prove it cheaply:

1. **State the claim so it can be false.** "Upgrading X keeps Y working" — not "should be
   fine".
2. **Find the smallest thing that would be false if the claim is false.** Usually one command
   or one file, not a branch.
3. **Run it. Record the output, with the date, in the chronicle.**
4. **If the probe fails, the entry stays.** A failed probe is the most valuable kind: it is
   the reason the next person does not spend a day on it.

A probe takes minutes. The upgrade it prevents takes days, and the rollback takes longer.

## Where it lives

Per project, as
[`claude/skills/project/failure-archaeology`](../claude/skills/project/failure-archaeology/SKILL.md).
It is a skill rather than a document because its whole job is to be loaded *before* someone
proposes a fix — and skills load on triggers, while documents load when someone remembers.
