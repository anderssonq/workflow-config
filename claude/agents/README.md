# Agents

Two families. They are not alternatives — most projects end up with both.

## Zone agents — ownership by surface

One agent per area of the codebase, each owning exact paths, each loading that area's
conventions as law. The orchestrator routes by *where the change lives*.

| Agent | Owns |
| --- | --- |
| [`api-feature`](zone/api-feature.md) | Backend source and its tests |
| [`db-schema`](zone/db-schema.md) | Schema, migrations, seed |
| [`web-ui`](zone/web-ui.md) | Everything rendered |
| [`infra`](zone/infra.md) | Images, compose, deploy config |
| [`release-manager`](zone/release-manager.md) | Versions, changelog, tags |
| [`docs-keeper`](zone/docs-keeper.md) | The living documents **and the agent team itself** |

`docs-keeper` is the one people leave out and then miss. Without it, skills describe a
codebase that no longer exists, and misroutes are rediscovered rather than fixed.

## Role agents — ownership by task

Invoked for a job, regardless of where in the tree it lands.

| Agent | For |
| --- | --- |
| [`pr-review-agent`](role/pr-review-agent.md) | Review **and** the PR description |
| [`pr-description-agent`](role/pr-description-agent.md) | The PR description only |
| [`spec-context-agent`](role/spec-context-agent.md) | Specs before any code is written |
| [`knowledge-graph-agent`](role/knowledge-graph-agent.md) | Mapping and querying a codebase |
| [`release-deploy`](role/release-deploy.md) | Releases where **push is deploy** |
| [`ops-server`](role/ops-server.md) | Reading and operating a live host |

## Two rules that apply to every agent here

1. **Never fan two agents onto the same files.** Ownership is exclusive; overlap produces
   conflicting edits that neither agent can see.
2. **Every agent states what it must not do.** An agent with capabilities and no boundary
   will eventually use all of them.

Write new ones against [`agent-authoring`](../skills/meta/agent-authoring/SKILL.md).
