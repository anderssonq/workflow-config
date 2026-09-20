# Containers and deployment

| File | Is |
| --- | --- |
| [`docker-compose.yml`](docker-compose.yml) | Development: only the database runs in a container |
| [`docker-compose.prod.yml`](docker-compose.prod.yml) | Production: four services and a schema gate |
| [`Dockerfile.node`](Dockerfile.node) | Multi-stage Node image |
| [`.dockerignore`](.dockerignore) | What never enters a build context |

Conventions and reasoning:
[`stack/container-deploy`](../../claude/skills/stack/container-deploy/SKILL.md).

## The three things worth copying even if you use none of these files

**Publish development database ports to loopback only.** `'127.0.0.1:5432:5432'`, never
`'5432:5432'`. The second publishes your database to every machine on the network, it is
invisible in any output, and nobody intends it.

**Make the migration a one-shot service, not a step in the app's entrypoint.** It gets
`restart: 'no'`, everything else waits on it, and it reuses the build stage rather than
needing a second image — so the runtime image never ships a migration CLI.

**Write enforced absences into the file, as comments.** The most useful comments in a compose
file are about what a service deliberately does *not* have: no database URL, no credential,
no CLI. An absence that is enforced is a design decision. An absence that is merely current
is a bug waiting for someone helpful.
