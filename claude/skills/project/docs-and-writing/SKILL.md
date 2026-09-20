---
name: docs-and-writing
description: The four living documents of this project, what each is and is not, the ADR template and numbering, house style, and how anything is superseded. Load before touching any document of record.
paths: 'CLAUDE.md, ARCHITECTURE.md, DECISIONS.md, README.md, .claude/skills/**, .claude/agents/**'
---

# Docs and writing

**Audience:** about to write or change a document of record, a skill, or an agent file.

## When NOT to use this skill

- The size limits alone → `doc-budgets` in the bank's meta set.
- How to write a skill's frontmatter and body → `skill-authoring`.
- A past incident's narrative → [`failure-archaeology`](../failure-archaeology/SKILL.md).

## 1. The four living documents

| File | Is | Is **not** | Size |
| --- | --- | --- | --- |
| `CLAUDE.md` | Cross-cutting facts, the agent roster, the Definition of Done | Procedures, zone conventions, history | ≤ 200 lines |
| `ARCHITECTURE.md` | Structure and rationale, module map, request lifecycle, "Planned, not yet built" | How-to steps, decision history | No cap — and it may **shrink** |
| `DECISIONS.md` | Append-only ADR log, newest at the bottom, with an index at the top | Tutorials, descriptions of the current state | Grows forever; entries ≤ 30 lines |
| `README.md` | Clean-machine setup, config table, scripts, troubleshooting | Architecture rationale, internal conventions | Readable before the first install |

**Before adding a fifth root file**, know that each of these earned its place. A fifth needs
an ADR and a named owner, or it becomes the file nobody updates.

## 2. The ADR template

```markdown
## ADR-0NN — Short declarative title of what was decided

- **Context:** the forces — what problem or constraint, what broke, what was required.
- **Decision:** what was chosen, concretely enough to reimplement without asking.
- **Alternatives:** each rejected option with a one-line reason it lost.
- **Consequences:** what this makes easier or harder later; the revisit condition, if one exists.
```

A good **Consequences** line names the condition under which this gets reopened. An ADR with
no revisit condition is a decision nobody can ever revisit without looking reckless.

**Numbering takes two greps, not one:**

```bash
grep -oE '^## ADR-[0-9]+' DECISIONS.md | tail -1          # the last number in the log
grep -rn 'ADR-[0-9]+' --include='*.html' --include='*.md' .  # numbers spent outside the log
```

The entry goes at the end of the file **and** into the index at the top, where any superseded
entry has its status changed in the same pass.

Nobody assigns themselves a number mid-work. Write `ADR pending:` on one line and let the
documentation owner sweep for it.

## 3. House style

1. **One language, everywhere.** Pick it once; do not mix per file.
2. **Terse.** The whole doc set readable in fifteen minutes — *measured* with `wc -l`, not
   remembered.
3. **Docs follow code.** Never speculation, never a plan written as description.
4. **No overselling.** Anything unbuilt is "planned", never present tense.
5. **Date-stamp volatile facts.** `date +%F`. A version, a count or a measurement with no
   date cannot be audited.
6. **Voice by kind.** Imperative for runbooks, declarative for contracts. Commands fenced and
   copy-pasteable. Tables when three or more facts run in parallel. Jargon defined once, at
   first use.
7. **No secrets, no personal data, no absolute paths** in any document.
8. **When measurement contradicts an upstream doc, say the upstream doc is wrong** — and name
   it. Deferring to a doc you have just disproved is how a wrong fact becomes permanent.

## 4. Team upkeep

| Trigger | What must happen, in the same commit |
| --- | --- |
| A feature landed | The docs it made stale get updated |
| A convention changed | The zone's `SKILL.md` changes with it |
| A delegation misfired | The agent's `description` (routing) or body (context) gets fixed |

## 5. Superseding

- **ADRs are append-only once committed.** Never rewrite one that has shipped; supersede it
  and update the index.
- **An ADR still only in the working tree is a draft.** Rewrite it in place so it reads as if
  it was born decided — no `**Correction**` appendices, no sentences addressed to a reader who
  was going to decide.
- **Skills and agent files are living files, not logs.** Retire by deleting the directory.
  Never leave a "deprecated" tombstone.
- **Before deleting or renaming a skill**, sweep and fix every reference in the same commit:
  ```bash
  grep -rn '<skill-name>' CLAUDE.md .claude/
  ```

## 6. Review checklist

- [ ] The fact has exactly one home
- [ ] Volatile facts carry a date
- [ ] Nothing unbuilt is described in the present tense
- [ ] Commands were run, or are labelled `UNVERIFIED`
- [ ] Within budget (`wc -l`)
- [ ] The index and the entry agree
- [ ] No secrets, no personal data, no absolute paths
- [ ] No AI trailers <!-- FILL: keep or drop, per this project's owner rule -->

## Provenance and maintenance

<!-- FILL: verified date. -->
