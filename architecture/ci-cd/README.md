# CI and dependency gates

Three jobs, deliberately separate, plus a dependency gate that fails in both directions.

| File | Is |
| --- | --- |
| [`ci.yml`](ci.yml) | The workflow: `verify`, `audit`, `scan` |
| [`audit-gate.mjs`](audit-gate.mjs) | The advisory gate the `audit` job runs |
| [`dependabot.yml`](dependabot.yml) | Four ecosystems, each with what it can actually see |

## Why three jobs and not three steps

**So that three different reds stay readable.** A lint failure, a new advisory and a base
image CVE are three unrelated kinds of problem with three unrelated responses. Collapsed into
one job, the second and third are invisible behind the first, and the run is red for "a
reason" rather than for something.

An advisory can also appear on a branch that changed no dependency — upstream published, not
you. That has no business failing the job that builds your code.

## `verify` — lint · build · test

- **Build before test.** A shared package consumed as built output has to exist before
  anything type-checks against it. Getting this backwards produces a failure that looks like
  a missing module and is actually an ordering bug.
- **A service container matching development.** The same database major, so a difference
  between local and CI is a real difference.
- **Environment values are throwaway literals, not repository secrets** — with a comment
  saying so. Making them secrets implies they matter, and then nobody dares change them.
- **Every third-party action pinned by commit SHA**, with the resolved tag in a trailing
  comment, and the bump procedure written in the file. A tag is mutable; a SHA is the only
  pin that means anything.

## `audit` — the gate that fails both ways

The bar is not "clean". It is **"clean, or exactly the advisories named in the allowlist"**,
and it fails in both directions:

- a new advisory fails, and
- **an allowlisted advisory that is no longer reported also fails.**

The second is the point. A stale exception is how an allowlist rots into a blindfold: the
entry outlives the problem, nobody notices, and the next real advisory in that module is
silently permitted.

Each allowlist entry carries an identifier, a module and a prose reason. Adding a second one
needs an ADR — the first exception is a judgement call, the second is a policy.

## `scan` — base image CVEs, report only

Preceded by a step that **asserts the hardcoded image references still match the repository**
and fails loudly if they have drifted. A scanner pointed at an image you stopped using is a
green check that means nothing.

Findings go to the step summary rather than the security tab, so the job needs no extra token
scope. The file says what this does **not** cover, and what would justify making it blocking.

## Dependabot, and what it cannot see

Three of the four ecosystems see less than their names suggest. Registering them anyway is
deliberate: the day you pin a digest, it becomes a one-file change instead of a new
configuration.

Read the header comment in [`dependabot.yml`](dependabot.yml) before merging anything it
opens — **on a repository where the default branch deploys, a dependency PR is a proposal to
ship**, not a chore.
