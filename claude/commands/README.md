# Slash commands

Drop into a project's `.claude/commands/`. Each is a markdown file whose name is the command:
`ship.md` becomes `/ship`.

```markdown
---
description: One line, shown in the command list
argument-hint: <what to type after the command>  e.g. <ticket-id>
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Title: $ARGUMENTS

The prompt. `$ARGUMENTS` is substituted with what the user typed.
```

`argument-hint` is what stops a command from being invoked with the wrong shape of input,
and it is the field most often left out.

| Command | Does |
| --- | --- |
| [`/gate`](gate.md) | Runs the project's acceptance gate and reports honestly |
| [`/adr`](adr.md) | Sweeps for pending ADRs, assigns numbers, updates the index |
| [`/drift`](drift.md) | Finds where the docs and the code disagree |
