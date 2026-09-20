# Agent memory

The convention lives in [`memory-system`](../skills/meta/memory-system/SKILL.md); the
templates live here.

```
.claude/agent-memory/<agent-name>/
  MEMORY.md                 index, ≤ 40 lines, one line per note
  project_<topic>.md        a fact about this project's surfaces
  reference_<topic>.md      a technique that travels to other projects
  pattern_<topic>.md        a named, repeatable pattern
  feedback_<topic>.md       a correction the owner issued
```

The prefix is load-bearing. It says whether a note travels (`reference_`, `pattern_`) or dies
with the project (`project_`), and it makes the `feedback_` notes findable as a set when an
agent keeps missing the same thing.

| File | Copy to |
| --- | --- |
| [`MEMORY.template.md`](MEMORY.template.md) | `<agent>/MEMORY.md` |
| [`note.template.md`](note.template.md) | `<agent>/<prefix>_<topic>.md` |

## The two rules that keep it useful

**Zones append. One agent prunes** — the documentation keeper, roughly every ten ADRs. The
test is a single question: *would removing this cause a mistake?*

**Verify before trusting.** A note reflects what was true when it was written. If it names a
file, a function or a flag, check that it still exists before acting on it.
