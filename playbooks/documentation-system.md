# The documentation system

Four documents, one ADR log, and a set of rules about which holds what. The per-project
template is
[`claude/skills/project/docs-and-writing`](../claude/skills/project/docs-and-writing/SKILL.md);
this is the reasoning behind it.

## Why four, and only four

Every document that exists gets a maintenance cost and a chance to disagree with the others.
Four is what survived: each answers a question the others cannot, and each has a clear
"is not" that keeps content from drifting into it.

| File | Answers | Is **not** |
| --- | --- | --- |
| `CLAUDE.md` | What must be true on every turn | A procedure manual or a history |
| `ARCHITECTURE.md` | How it is built, and why that way | A how-to, or a decision log |
| `DECISIONS.md` | What was decided, when, and against what | A description of the present |
| `README.md` | How a stranger gets it running | Rationale or internal convention |

`ARCHITECTURE.md` has no line cap and **may shrink**. That is unusual enough to say out
loud: when a subsystem is deleted, its section goes, and the document gets shorter. A
document that only ever grows is a document nobody is maintaining.

`CLAUDE.md` has the tightest budget because it loads on every turn. Every line in it is a
tax on every request for the rest of the project's life.

## The fifth file

There is usually one legitimate exception — a `CHANGELOG.md`, most often. Let it be a
decision: it needs an ADR and a named owner. The point is not bureaucracy, it is that the
sixth and seventh files arrive without one, and then nothing is maintained.

## ADRs

```markdown
## ADR-0NN — Short declarative title of what was decided

- **Context:** the forces — what problem or constraint, what broke, what was required.
- **Decision:** what was chosen, concretely enough to reimplement without asking.
- **Alternatives:** each rejected option with a one-line reason it lost.
- **Consequences:** what this makes easier or harder later; the revisit condition, if one exists.
```

**Append-only once committed.** An ADR that gets edited to look smarter stops being evidence
of what was known at the time, which is the only thing an ADR is for.

**An ADR still in the working tree is a draft.** Rewrite it freely so it reads as if it was
born decided — no `**Correction**` appendices, no sentences addressed to a reader who was
about to decide. The log records decisions, not the deliberation.

**The revisit condition is the most valuable line.** "Consequences: this couples X to Y;
revisit if Y ever needs to be replaced" is what lets a future reader reopen the decision
without looking reckless. An ADR with no revisit condition reads as permanent, and permanent
decisions accumulate until nothing can move.

**Numbering takes two greps.** The log's last number, and every number spent outside the log
— in a skill, a comment, a mockup. Taking only the first reissues one of the second.

Nobody assigns themselves a number mid-work. Write `ADR pending:` on one line; the
documentation owner sweeps.

## House style

1. **One language, everywhere.** Chosen once, not per file.
2. **Terse, and measured.** The whole doc set readable in fifteen minutes, checked with
   `wc -l` rather than remembered.
3. **Docs follow code.** Never a plan written in the present tense.
4. **No overselling.** Unbuilt is "planned". The only sanctioned home for future work is a
   "Planned, not yet built" section in `ARCHITECTURE.md`.
5. **Date volatile facts.** Versions, counts, measurements, external behaviour. A number
   with no date cannot be audited, so it will be believed forever.
6. **Voice by kind.** Imperative for runbooks, declarative for contracts. Commands fenced
   and copy-pasteable. Tables when three or more facts run in parallel.
7. **No secrets, no personal data, no absolute paths.** In any document, ever.
8. **When measurement contradicts an upstream document, say the upstream document is wrong**
   — and name it. Deferring to a doc you have just disproved is how a wrong fact becomes
   permanent, and how the next person repeats your experiment.

## A doc pass replaces prose; it never appends a round

The second pass over a section rewrites it. Appending a correction to a document that will be
read as current is how a document starts contradicting itself inside a single page.

## Team upkeep

Documentation is not the only thing that goes stale. The skills and agent files go stale
faster, because nothing renders them wrong.

| Trigger | Same commit |
| --- | --- |
| A feature landed | The docs it made stale |
| A convention changed | The `SKILL.md` that states the convention |
| A delegation misfired | The agent's `description` (routing) or body (context) |

That last row is the one that compounds. A misroute fixed as prose somewhere else will
misroute again next week.

## Retiring

- ADRs are superseded, never deleted.
- Skills and agents are **living files, not logs**: retire by deleting the directory. A
  "deprecated" tombstone is a file that will be read by something that cannot tell.
- Before deleting or renaming either, sweep and fix every reference in the same commit.
