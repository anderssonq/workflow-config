---
name: build-run-and-operate
description: Starting this project from zero, the ports and processes it uses, its data lifecycle, the smoke test, and how a deploy actually happens. Load when running, deploying or operating it.
paths: 'package.json, Makefile, docker-compose*.yml, Dockerfile*'
---

# Build, run and operate

**Audience:** about to run this on a machine, or to deploy it, or to work out what is
already running.

## When NOT to use this skill

- Which value goes where → [`config-and-env`](../config-and-env/SKILL.md).
- It started and then broke → [`debugging-playbook`](../debugging-playbook/SKILL.md).
- Cutting a version and a tag → the release agent, not this skill.

## From zero on a clean machine

```bash
<!-- FILL: the real sequence, verified on a machine that had none of it.
     Include the toolchain versions and how they are pinned. -->
```

## Ports and processes

| Process | Port | Started by | Notes |
| --- | --- | --- | --- |
<!-- FILL. Say which ports are published to the host and which are bound to loopback only. -->

## Data lifecycle

<!-- FILL: create, migrate, seed, reset, and — most importantly — which of those are safe
     to run against real data and which are not. Say it in the imperative, and say what
     is irreversible. -->

## The smoke test

Measure, do not eyeball. One command, one verdict:

```bash
<!-- FILL: the actual smoke script, or the handful of probes that constitute it.
     Each probe prints what it checked and its result, and the script exits non-zero
     if any failed. A smoke test whose output you have to interpret is not one. -->
```

## Reading the output

<!-- FILL: log format, level conventions, the fields worth filtering on, and two or three
     recipes. -->

## Deploy

<!-- FILL: what actually triggers a deploy. If pushing the default branch deploys, say so
     here in bold — it changes what every agent and every person is allowed to do without
     asking. Name the rollback path, and whether it has ever been used. -->

## Artifact map

| Artifact | Built from | Contains | Does **not** contain |
| --- | --- | --- | --- |
<!-- FILL. The last column is the useful one: an image that deliberately ships without a
     CLI, a service that deliberately holds no credential, a bundle that deliberately
     excludes docs. Absences that are enforced belong here. -->

## Provenance and maintenance

<!-- FILL: verified date. -->
