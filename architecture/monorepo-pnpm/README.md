# pnpm monorepo

The layout, and the four files that make it work. Copy from `files/`; the reasoning is here
and in [`stack/pnpm-monorepo`](../../claude/skills/stack/pnpm-monorepo/SKILL.md).

```
apps/       deployable things      @scope/api, @scope/web
packages/   things apps import     @scope/shared
```

## Files

| File | What it decides |
| --- | --- |
| [`files/pnpm-workspace.yaml`](files/pnpm-workspace.yaml) | Package globs, build allowlists, advisory overrides |
| [`files/tsconfig.base.json`](files/tsconfig.base.json) | The strictness every package inherits |
| [`files/package.json`](files/package.json) | Root scripts, engine and package-manager pins |
| [`files/.prettierrc.json`](files/.prettierrc.json) | Formatting, decided once |
| [`files/.editorconfig`](files/.editorconfig) | What editors agree on before any tooling loads |

## The decisions worth knowing before you copy

**One config at the root, not one per package.** Per-package configs diverge silently, and
the divergence surfaces only when a file moves between packages and starts failing a rule it
never saw. Package-specific rules are scoped blocks in the root config —
see [`../boundaries/`](../boundaries/).

**`noUncheckedIndexedAccess` is on.** It is the single setting that catches the most real
bugs and annoys people the most: `arr[0]` becomes `T | undefined`, which it always was. Turn
it on at the start of a project, never in the middle.

**Workspace dependencies are `"workspace:*"`.** A version range resolves to the registry the
moment the package is published or a name collides, and the failure looks like a version
mismatch rather than a wrong package.

**Both pins are load-bearing.** `engines.node` and `packageManager` are read by CI, so drift
shows up as a red build rather than as a mystery that only reproduces on one machine.

## The overrides discipline

The part people get wrong. Four rules:

1. **Stay inside the requester's semver range.** Crossing a major to silence an advisory
   trades a known problem for an unknown one.
2. **Consolidate by hand after `pnpm audit --fix`.** Its output is a starting point.
3. **Every entry carries an upper bound.** This one is not theoretical: an open-ended
   `'>=3.1.5'` on a transitive dependency resolved forward to `4.x` and brought in four
   advisories that had not existed before. `'>=3.1.5 <4'` is the whole fix.
4. **Say which entries reach production.** A dev-only override is a different risk from one
   in the runtime tree; treating them alike means over-reacting to one and under-reacting to
   the other.

Keep an **accepted advisories** allowlist alongside, each entry with its identifier, module
and a prose reason. [`../ci-cd/audit-gate.mjs`](../ci-cd/audit-gate.mjs) enforces it in both
directions — a new advisory fails, and so does an allowlisted one that is no longer reported.
