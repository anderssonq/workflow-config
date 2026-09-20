---
name: pnpm-monorepo
description: pnpm workspace conventions — layout, naming, the built-dependency allowlist, and the overrides discipline that keeps advisory pins from making things worse. Load before touching workspace or dependency config.
paths: 'pnpm-workspace.yaml, package.json, tsconfig.base.json'
---

# pnpm monorepo conventions

**Audience:** changing the workspace layout, adding a package, or touching dependencies.

Copy-ready files live in `architecture/monorepo-pnpm/`. This is the reasoning; that is the
material.

## When NOT to use this skill

- Enforcing import boundaries between layers → `architecture/boundaries/`.
- Container builds → [`container-deploy`](../container-deploy/SKILL.md).
- CI configuration → `architecture/ci-cd/`.

## Layout and naming

```
apps/       deployable things
packages/   things apps import
```

- Every package is `@scope/name` and `private: true`. A package that is not published does
  not need a name that survives npm's namespace, but it does need one that survives a grep.
- Workspace dependencies are `"workspace:*"`, never a version range. A range resolves to the
  registry the moment the package is published or the name collides.
- The Node version goes in `engines`, the package manager in `packageManager`. Both pinned;
  both read by CI, so a drift is a red build rather than a mystery.

## One config, not one per package

The type-checker base, the linter and the formatter live at the root. Packages do not define
their own. Package-specific rules are scoped blocks in the root config.

The reason is not tidiness: per-package configs diverge silently, and the divergence is only
discovered when a file moves between packages and starts failing a rule it never saw.

## Built dependencies

pnpm 10 blocks install scripts by default. Two lists make the decision explicit:

```yaml
onlyBuiltDependencies:     # postinstall genuinely required — native builds, clients
  - '@prisma/client'
  - esbuild
ignoredBuiltDependencies:  # deliberately never run
  - '@scarf/scarf'         # telemetry only
```

Every entry in the second list carries the reason inline. "We never run it" is a decision
someone will otherwise reverse by accident.

## The overrides discipline

Advisory floors for transitive dependencies. Four rules, and the third is the one people
learn the hard way:

1. **Stay inside the requester's semver range.** Never cross a major to satisfy an advisory —
   you have traded a known advisory for an unknown incompatibility.
2. **Consolidate by hand after `audit --fix`.** The tool's output is a starting point, not a
   patch.
3. **Every entry carries an upper bound.** An open-ended `'>=3.1.5'` resolved to `4.x` and
   brought in four advisories that did not exist before. `'>=3.1.5 <4'` is the whole fix.
4. **Classify which entries reach production** and say so in a comment. An override for a
   dev-only dependency is a different risk from one in the runtime tree, and treating them
   alike means over-reacting to one and under-reacting to the other.

Maintain an **accepted advisories** allowlist alongside, each entry with a GHSA id, the
module and a prose reason. See `architecture/ci-cd/audit-gate.mjs` for the gate that enforces
it in both directions.

## What Dependabot cannot see

Worth knowing before trusting it as coverage: it reads declared dependencies, so **`overrides`
are invisible to it**, and a `FROM node:${NODE_VERSION}-alpine` in a Dockerfile does not match
its tag pattern. Register the ecosystems anyway — the day you pin a digest, it becomes a
one-file change instead of a new configuration.

## Provenance and maintenance

Extracted 2026-09-20 from a pnpm 10 workspace in production. The `fast-uri` upper-bound rule
is a real regression: an open-ended floor resolved forward across a major and net-added four
advisories.
