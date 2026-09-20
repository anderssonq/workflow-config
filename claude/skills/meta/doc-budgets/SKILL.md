---
name: doc-budgets
description: The size limits every document in this system is held to, and the reason behind each one. Load when a doc is growing, when splitting one, or when reviewing a docs change.
---

# Documentation budgets

**Audience:** anyone writing or reviewing a document in this system.

A budget is not tidiness. Every one of these exists because something stopped working when
it was exceeded — a skill that no longer fit in a decision, an index nobody read, a
`CLAUDE.md` that blew past the harness budget and started silently truncating.

## The budgets

| Artifact | Budget | Why this number |
| --- | --- | --- |
| Skill `description` | **≤ 35 words** | It is read during routing, alongside every other description. Longer and the distinctions stop being visible. |
| `SKILL.md` | **≤ 350 lines** | Past this the model reads the top and skims the rest — so the rest may as well not be there. Split instead. |
| Agent memory index (`MEMORY.md`) | **≤ 40 lines** | It is an index. At 40 lines it is a document, and the notes it points at stop being found. |
| A single ADR entry | **≤ 30 lines** | An ADR records a decision, not the investigation. The investigation goes in failure archaeology. |
| `CLAUDE.md` | **≤ 200 lines** | It loads on every single turn. Every line is a tax on every request. |
| Project doc set, end to end | **readable in 15 minutes** | Measured with `wc -l`, not remembered. |

## How a budget is enforced

Measured, not estimated:

```bash
wc -l claude/skills/*/*/SKILL.md | sort -rn | head
awk '/^description:/{print FILENAME": "NF-1" words"}' claude/skills/*/*/SKILL.md
```

## What to do when one is exceeded

**Split, do not shrink by deletion.** A skill over budget almost always contains two subjects
that arrived at different times. Find the seam, split there, and name each half in the other
so a reader landing on one knows the other exists.

**A doc pass replaces prose, it never appends a round.** The second pass over a section
rewrites it. Appending a correction to a document that will be read as current is how a
document starts contradicting itself.

## When NOT to use this skill

- Writing the skill itself → [`skill-authoring`](../skill-authoring/SKILL.md).
- The contract of which document holds what → `playbooks/documentation-system.md`.

## Provenance and maintenance

The numbers come from two projects that hit the limits the hard way. One adopted them as an
architecture decision after its skill set outgrew what the model would actually read. The
other let its `CLAUDE.md` reach 254,000 characters — past the harness budget — and had to
split it into per-route skills, dropping to ~94,000. Verified 2026-09-20.
