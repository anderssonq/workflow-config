---
name: config-and-env
description: Every configuration axis of this project with its named source of truth, and the one-commit procedure for adding a variable. Load before adding, renaming or reading a config value.
paths: '.env.example, **/config/**, tsconfig*.json, *.config.*'
---

# Config and environment

**Audience:** about to add, rename, read or debug a configuration value.

The rule that makes this file worth having: **every axis has exactly one named source of
truth.** A value read from two places is a value that will disagree with itself in production.

## When NOT to use this skill

- Starting the thing up → [`build-run-and-operate`](../build-run-and-operate/SKILL.md).
- Why a config axis exists at all →
  [`architecture-contract`](../architecture-contract/SKILL.md).
- A value that only looks like config → the "Protected values" section of that same skill.

## The catalog

| Axis | Source of truth | Read by | Notes |
| --- | --- | --- | --- |
<!-- FILL: one row per axis. Be exhaustive; the gaps are where the bugs are.
     Typical axes: runtime env vars, build-time inlined vars, feature flags, the
     type-checker config, the linter config, the formatter, the package manager pin,
     container build args, client-side storage keys, CI variables. -->

## Build-time versus runtime

The distinction that causes the most confusion, so state it explicitly here:

<!-- FILL: which variables are inlined at build time (and therefore stale until a rebuild,
     and therefore public if the bundle is public), and which are read at runtime.
     Name the prefix or mechanism that decides, e.g. NEXT_PUBLIC_ / VITE_. -->

**A build-time variable is not a secret.** If it reaches the client bundle, it is published.

## Adding a variable — one commit, all the steps

```
1. Add it to the validated schema, with its type and its default (or mark it required).
2. Add it to `.env.example`, with a comment saying what it is for — never a real value.
3. Add it to the deployment configuration.
4. Add the row to the catalog above.
5. Use it through the validated config object, never through the raw environment.
```

Steps 1 and 2 travel together, always. A schema that knows about a variable the example file
does not is a variable the next person on a clean machine cannot discover.

## The env-var doctrine

**An environment variable is a way for production to disagree with the repo about published
identity.** Anything that is part of who this project *is* — a canonical URL, a social handle,
a display name — belongs in a committed constant, not in the environment. The failure mode is
quiet: production drifts, and two documents that should agree end up naming different things
in the same response.

Environment variables are for what genuinely differs between environments: endpoints,
credentials, resource limits, and flags that are meant to differ.

## Secrets

- Never in the repo, never in a log, never in an error message, never in a client bundle.
- `.env.example` carries **names and comments only**.
- A placeholder that the runner substitutes (`{{secret:NAME}}`) and that reporting redacts
  is the right shape for anything a tool has to be handed.

## Provenance and maintenance

<!-- FILL: verified date. -->
