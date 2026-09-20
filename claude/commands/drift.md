---
description: Find where the documents of record disagree with the code
argument-hint: [area]  optional — a path or subsystem to narrow the sweep
allowed-tools: Read, Bash, Grep, Glob
---

# Documentation drift: $ARGUMENTS

Find disagreements between what the docs claim and what the repository contains. **Report
them; do not fix code.** A doc pass that edits source has become a back door.

Check, in this order:

1. **Named things that no longer exist.** Every file path, script name, command, environment
   variable, package and directory mentioned in `CLAUDE.md`, `README.md`, `ARCHITECTURE.md`
   and every `SKILL.md` — does it resolve?
2. **Things that exist and are documented nowhere.** New top-level directories, new scripts,
   new environment variables in the schema but not in the example file.
3. **Skills whose `name` does not match their directory.** These silently never load.
4. **Cross-references to retired skills or agents.**
5. **Undated volatile facts** — versions, counts, measurements with no date beside them.
6. **Present tense for things not built.** Anything described as existing that lives only in
   a "planned" section, or nowhere.
7. **Budgets exceeded**: `wc -l` on every `SKILL.md`, word count on every `description`.

Report as a table: `claim` · `where it is written` · `what is actually true`. Order by how
badly a reader would be misled, not by file.
