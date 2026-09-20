---
name: memory-system
description: How an agent keeps notes between sessions — the index, the four note kinds, the note shape, and who prunes. Load before writing agent memory or designing an agent that has any.
---

# Agent memory

**Audience:** an agent about to write a note, or whoever is setting memory up for a team.

Memory is what stops a team of agents from relearning the same thing every week. It is also
what quietly rots into 900 KB of half-true notes if nobody owns pruning. Both halves matter.

## When NOT to use this skill

- Writing a convention that is *law* for a zone — that belongs in a `SKILL.md`, not a note.
  See [`skill-authoring`](../skill-authoring/SKILL.md). A note is what one agent learned; a
  skill is what every agent must obey.
- A decision with alternatives and consequences → an ADR, see
  `playbooks/documentation-system.md`.
- A past incident and its settled outcome → the project's `failure-archaeology` skill.

## Layout

```
.claude/agent-memory/
  <agent-name>/
    MEMORY.md                       index, ≤ 40 lines, one line per note
    project_<topic>.md              a fact about this project's surfaces
    reference_<topic>.md            a reusable technique, not project-specific
    pattern_<topic>.md              a named, repeatable code or UI pattern
    feedback_<topic>.md             a correction the owner issued
```

The prefix is the note's kind, and it is load-bearing: it tells a reader whether a note
travels to another project (`reference_`, `pattern_`) or dies with this one (`project_`),
and it makes `feedback_` notes findable as a set when an agent keeps missing the same thing.

## The index

`MEMORY.md` is one line per note, each a link plus a clause of gist — enough to decide
whether to open it:

```markdown
- [Query keys are derived, never typed](project_query_keys.md) — one factory, invalidation follows
- [Never retune a fixture to pass](feedback_never_retune_a_fixture.md) — fix the code or the assertion
```

No frontmatter, no sections, no content. The moment the index holds content it stops being
an index.

## The note

```markdown
---
name: never-retune-a-fixture-to-pass
description: One line, used to decide relevance during recall.
metadata:
  type: feedback
---

The fact, stated plainly and in full.

**Why:** what makes it true, or what broke that made it a rule.

**How to apply:** what to do differently next time, concretely.

See also [[query-keys-are-derived]].
```

- **One note, one fact.** A note holding three facts gets recalled for one and applied for
  all three.
- **`Why` and `How to apply` are mandatory** for `feedback_` and `project_` notes. A fact
  with no application is trivia the agent will read and ignore.
- **`[[wiki-links]]` liberally.** A link to a note that does not exist yet is not an error —
  it marks something worth writing.
- **Absolute dates.** "Last week" is false by the next session.

## Pruning — the half everyone skips

Zones append. **One agent weeds**, and it is the documentation agent, not the zone that
wrote the note. Roughly every ten ADRs, or whenever the index crosses its budget.

The prune test is a single question: **would removing this cause a mistake?** If not, it goes.
Notes that describe code that no longer exists go first; a note pointing at a deleted file is
worse than no note, because it is confidently wrong.

Before trusting any recalled note that names a file, function or flag, **verify it still
exists.** A note reflects what was true when it was written.

## Provenance and maintenance

Distilled 2026-09-20 from a memory tree of seven agents carrying ~120 notes. The four
prefixes, the `Why` / `How to apply` shape and the "would removing this cause
a mistake?" prune test are that system's own conventions; the index budget comes from
[`doc-budgets`](../doc-budgets/SKILL.md).
