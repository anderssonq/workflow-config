---
name: agent-authoring
description: How to define a subagent that gets picked for the right job, knows its boundary, and returns something the orchestrator can use. Load before adding or changing an agent.
---

# Writing an agent

**Audience:** whoever is about to add or change a file under `claude/agents/`.

An agent is a routing decision plus a boundary. Most agent files fail at one of the two:
they describe what the agent can do without saying what it must not, or they are so broadly
described that the orchestrator picks them for everything.

## When NOT to use this skill

- Writing the knowledge the agent loads → [`skill-authoring`](../skill-authoring/SKILL.md).
- Deciding *whether* to delegate at all → `playbooks/delegation-and-orchestration.md`.
- Writing the notes the agent keeps between sessions →
  [`memory-system`](../memory-system/SKILL.md).

## Frontmatter

```yaml
---
name: web-ui
description: >
  Frontend owner (React). Use PROACTIVELY for any change under src/components,
  src/hooks or src/lib — screens, components, query state, styling, tests.
  Not for API code (api-feature), schema (db-schema) or containers (infra).
tools: Read, Edit, Write, Bash, Grep, Glob
skills: web-conventions, web-visual-conventions
memory: project
color: blue
---
```

- **`description` does two jobs.** It starts with `Use PROACTIVELY for …` and the paths or
  surfaces the agent owns, and it ends by naming what is *not* its and whose it is. The
  second half is what stops misrouting, and it is the half people skip.
- **`tools` is explicit.** An agent that only reads should not be able to write.
- **`skills` preloads the law.** The agent should not have to discover its own conventions.
- **`memory: project`** if the agent should accumulate notes across sessions.

## The body: four things, in order

1. **What this agent owns** — exact paths, not prose. "Everything under `apps/api/src`",
   not "the backend".
2. **How it works** — the ordered workflow, including the order that matters. If schema must
   be migrated before the client is regenerated, say so and say why.
3. **MUST NOT** — the boundary, stated as prohibitions. This is the most valuable section in
   the file. Examples worth stealing:
   - *never run `git push`, `git tag` or `git commit`; print the commands and let the owner
     run them* — for a release agent on a repo where push is deploy,
   - *never rewrite the working tree* (no stash / checkout / restore / `reset --hard`) —
     parallel sessions may be holding uncommitted work; read old content with
     `git show HEAD:<path>`,
   - *reading the server is free, writing needs an explicit yes for that specific action*,
   - *report drift in another zone; do not fix it*.
4. **Expected return** — what the agent hands back. An orchestrator that has to re-read the
   diff to find out what happened got nothing from delegating.

## Autonomy ceilings

An agent whose actions reach the outside world states its own ceiling in its body, and the
ceiling is a default, not a judgement call made per run:

- a content agent defaults to **draft**; it publishes only when the owner says so,
- a release agent does not run at all unless asked, because on a repo that auto-deploys,
  **push is deploy**,
- an infrastructure agent may read production freely and write to it only on an explicit,
  specific yes.

Write the ceiling down. An agent that decides its own autonomy per invocation does not have one.

## The two failure modes, and their fixes

| Symptom | Fix |
| --- | --- |
| The orchestrator picked the wrong agent | The `description` — sharpen the routing half, in both agents |
| The right agent did the wrong thing | The body — the workflow or the MUST-NOT section |

Fixing either belongs in the same commit as the work that exposed it. That is the team-upkeep
clause of the Definition of Done, not an optional cleanup.

## Provenance and maintenance

Distilled 2026-09-20 from eighteen agent definitions across four repositories — a mix of
zone-owner agents and role agents, in three independent sets. The
`Use PROACTIVELY … Not for X (other-agent)` shape and the MUST-NOT section are the two
conventions every set shares.
