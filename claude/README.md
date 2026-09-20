# The Claude Code bank

Everything here is meant to be copied into a project's `.claude/`, or into `~/.claude/` for
the user-level set. `scripts/install.sh` does the second; `scripts/new-project.sh` does the
first.

```
claude/
  skills/
    meta/       how this system writes itself — read these first
    project/    the eleven templates installed per project
    core/       skills that travel to any repository
    stack/      skills that are true only for a given stack
    vendored/   third-party skills, referenced by lockfile and never copied
  agents/
    zone/       ownership by surface — one agent per area of the codebase
    role/       ownership by task — review, release, specs, operations
  commands/     slash commands
  hooks/        things that must happen every time, without the model choosing to
  settings/     starting points for settings.json
  memory/       the agent-memory convention and its templates
```

## Where to start

| You want to | Read |
| --- | --- |
| Add a skill anywhere | [`skills/meta/skill-authoring`](skills/meta/skill-authoring/SKILL.md) |
| Add an agent | [`skills/meta/agent-authoring`](skills/meta/agent-authoring/SKILL.md) |
| Set a project up from scratch | [`skills/project/README.md`](skills/project/README.md) |
| Understand the agent families | [`agents/README.md`](agents/README.md) |
| Make something happen automatically | [`hooks/README.md`](hooks/README.md) |

## The one rule that is not written in any single file

**A fact has one home.** If it is in a skill, it is not also in `CLAUDE.md`. If it is in the
architecture contract, the agent file references it by name rather than restating it. Two
copies drift, and a reader who finds the stale one cannot tell.
