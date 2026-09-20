---
name: container-deploy
description: Compose and image conventions — dev runs only the database, prod gates schema through a one-shot service, and enforced absences are documented inline. Load before touching a Dockerfile or compose file.
paths: 'Dockerfile*, docker-compose*.yml, .dockerignore, nginx.conf'
---

# Containers and deployment

**Audience:** changing an image, a compose file, or how a deploy happens.

Copy-ready files live in `architecture/containers/`.

## When NOT to use this skill

- Workspace and dependency configuration → [`pnpm-monorepo`](../pnpm-monorepo/SKILL.md).
- The pipeline that builds and scans these → `architecture/ci-cd/`.
- Which env var goes where → the project's `config-and-env` skill.

## Development: only the database runs in a container

Applications run on the host under the dev server, because reload speed is the whole point
of a dev loop and a bind-mounted container build is slower at it. The database runs in a
container because its version must match production exactly.

Publish its port **to loopback only**:

```yaml
ports: ['127.0.0.1:5432:5432']
```

A bare `5432:5432` publishes the database to every machine on the network, which is not what
anyone intends and is not visible in any output.

## Production: the migrate service is a gate, not a step

A one-shot service that runs migrations and exits, with everything else waiting on it:

```yaml
migrate:
  build: { context: ., target: build }   # reuse the build stage: a container run, not a second image
  command: sh -c "prisma migrate deploy && prisma db seed"
  depends_on: { db: { condition: service_healthy } }
  restart: 'no'                          # exiting 0 is success, not a reason to restart
```

`target: build` matters because the runtime image should not ship a migration CLI. Reusing
the build stage costs a container run instead of a second image to maintain.

`NODE_ENV=production` here is load-bearing twice: it arms the seed's guard, and it puts the
seed in bootstrap-only mode.

## Document enforced absences inline

The most valuable comments in a compose file are about what a service deliberately does
**not** have:

```yaml
mcp:
  # No DATABASE_URL, ever. This service formats and forwards; a test proves it
  # carries no database client at all.
  # No MCP_TOKEN either — loadConfig refuses to start in http mode if one is set,
  # so a well-meaning addition in the deploy panel takes the service down rather
  # than quietly granting anonymous access.
```

An absence that is enforced is a design decision. An absence that is merely current is a bug
waiting for someone helpful.

Prefer **failing loudly over degrading quietly** for this class of guard. A service that
refuses to boot when handed a credential it should not have is a service whose misconfiguration
is a page, not a breach.

## Resource limits carry their measurement

```yaml
deploy: { resources: { limits: { memory: 256M } } }
# Measured 47 MiB idle. The cap exists because the host has 3.8 GB and no swap,
# so a leak here restarts this container instead of the kernel killing something else.
```

A limit with no number behind it gets raised the first time it is hit.

## Service-to-service hops use service names

Internal traffic goes to `http://api:3000`, not through the public hostname. The internal hop
should not depend on DNS, the reverse proxy or certificate renewal. Public discovery URLs
stay public names, deliberately — that is a different concern and it belongs in config.

## `.dockerignore`

Exclude `.git`, `node_modules`, build output, every `.env` except the example, the agent
config directory, and **`*.md`** — so a documentation-only commit never triggers an image
rebuild.

## Provenance and maintenance

Extracted 2026-09-20 from a production compose file. The loopback binding, the
migrate gate and the enforced-absence comments are all from that file; the memory cap example
carries its original measurement.
