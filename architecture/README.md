# Architecture

Guides with the actual files beside them. Nothing here is pseudo-code — copy it, then delete
what you do not need.

| Directory | Decides |
| --- | --- |
| [`monorepo-pnpm/`](monorepo-pnpm/) | Workspace layout, strictness, and the overrides discipline |
| [`boundaries/`](boundaries/) | Which module may import which, enforced by the linter |
| [`ci-cd/`](ci-cd/) | Three jobs, a two-directional advisory gate, and what Dependabot cannot see |
| [`containers/`](containers/) | Development compose, production compose, multi-stage images |

## The through-line

Every file here **carries its reasoning inline**, and that is deliberate rather than
decorative. Configuration is the category of file where the reason is never obvious from the
content, and where the next person's instinct — including yours, in a year — is to simplify
what looks redundant.

A comment that says *what* a line does is noise. A comment that says **what breaks if you
remove it** is the only thing standing between a working setup and a confident cleanup:

```yaml
- '127.0.0.1:5432:5432'   # loopback ONLY: a bare 5432:5432 publishes the
                          # database to the whole network, invisibly
```

Four entries in these files exist because something broke, and each says so where it will be
read: the advisory floor with no upper bound that resolved across a major, the seed whose
upsert restored deleted data, the image reference that drifted out from under its scanner,
and the memory cap that carries the measurement that set it.
