# Vendored skills

Third-party skills are **referenced here, not copied here**. `skills-lock.json` records where
each one came from; `scripts/sync-skill.mjs` fetches it.

The bodies are not committed for two reasons: they are someone else's work under their own
licence, and a committed copy drifts from upstream with nothing to signal that it has.

```bash
node scripts/sync-skill.mjs                              # fetch all, verify
node scripts/sync-skill.mjs vercel-react-best-practices  # just one
node scripts/sync-skill.mjs --check                      # verify, write nothing
node scripts/sync-skill.mjs --relock                     # re-pin to HEAD and rehash
```

## What you actually get

The sync fetches the **whole skill directory**, not just its entry file. That distinction is
the entire point here: `vercel-react-best-practices`' `SKILL.md` is a 149-line index, and the
content is 72 rule files beside it.

| Skill | Files | Licence | Is |
| --- | --- | --- | --- |
| `impeccable` | 52 | Apache-2.0 | A whole design language with ~40 verb playbooks — critique, audit, polish, distill, harden, typeset, colorize, animate. Ships iOS and Android references and a live browser-iteration mode. ⚠ see below |
| `vercel-react-best-practices` | 76 | MIT | 70 performance rules across 8 priority-ordered categories, one file each |
| `vercel-composition-patterns` | 14 | MIT | Compound components, render props, explicit variants, React 19 API changes |
| `vercel-react-view-transitions` | 9 | MIT | The View Transitions API: CSS recipes, patterns, framework notes, troubleshooting |
| `design-taste-frontend` | 1 | MIT | ~1,200 lines: anti-templated design direction for landing pages and redesigns |
| `web-design-guidelines` | 1 | MIT | A reviewer that fetches the current Web Interface Guidelines at run time |

153 files, one command. Each vendored directory gets an `UPSTREAM.md` recording source, ref,
file count, licence and any caution, because the copy is not ours. Where a licence requires
it — Apache-2.0 section 4(d) — the upstream `LICENSE` and `NOTICE` are fetched alongside and
sit beside the skill.

## ⚠ `impeccable` runs a binary

`scripts/impeccable` is an executable launcher that **downloads and runs a self-contained
binary on first use**, and the skill's own `allowed-tools` grants `Bash(npx impeccable *)`.

That is not a reason to avoid it. It is a reason to treat it the way
[`playbooks/security-baseline.md`](../../../playbooks/security-baseline.md) treats any new
dependency: know who maintains it, know what it pulls in, and read `scripts/` before running
anything. The sync preserves the executable bit — a launcher that arrives without it fails in
a way that looks like a missing file — so the decision to run it stays yours and is not made
by accident.

`impeccable` is also the largest entry by far (~2.1 MB, of which a 1.1 MB font index), which
is its own argument for fetching rather than committing.

## The lockfile

| Field | Means |
| --- | --- |
| `source` | `owner/repo` on GitHub |
| `sourceType` | `github` |
| `ref` | The commit to fetch. **`null` means unpinned** — the skill will change under you |
| `skillPath` | Path to `SKILL.md` inside that repo; its directory is what gets fetched |
| `license` | The upstream SPDX identifier. Recorded per entry, because they differ |
| `legalFiles` | Root files the licence requires to travel with the work (`LICENSE`, `NOTICE`) |
| `caution` | A one-line warning surfaced on every fetch and written into `UPSTREAM.md` |
| `computedHash` | **sha256 of the raw entry file at that ref**; a mismatch is reported, never silently accepted |
| `treeHash` | sha256 over every path and blob sha in the directory, so a change to any rule file is caught |

All five entries are pinned to a commit. An unpinned entry (`ref: null`) is a skill that
changes under you between two runs of the same script, which is the thing a lockfile exists
to prevent — `sync-skill.mjs` says so explicitly when a mismatch comes from one.

**A note on the hashes.** These are sha256 of the file exactly as GitHub serves it at that
commit, so anyone can reproduce them:

```bash
curl -fsSL https://raw.githubusercontent.com/<source>/<ref>/<skillPath> | shasum -a 256
```

They deliberately differ from the hashes an installer tool writes, which are computed over
content it has already transformed. A hash you cannot reproduce from the source is a hash
that cannot verify anything, so these were recomputed from the pinned refs on 2026-09-20.

## The consumption policy

This is the part that matters more than the lockfile.

**Vendored skills are advisory, not law.** They were written against a different stack, by
people who do not know this codebase. Four rules keep that from becoming a problem:

1. **Do not preload them in agent frontmatter.** Loading cost exceeds the payback. Invoke by
   name when the task actually calls for one.
2. **On conflict, the project's own design document wins.** Always, without discussion. A
   vendored skill that overrules the project's design system has inverted the hierarchy.
3. **List the rule families that do not apply, and why.** A React skill written for a
   server-rendering framework carries whole categories — server components, hydration,
   async route handlers, dynamic import budgets — that are noise in a client-only app.
   Write the list down in the consuming agent's body so nobody re-derives it each time.
4. **Record what was deliberately not installed.** A skill absent because it targets a
   platform you do not use looks identical to a skill nobody got around to. Name them.

An example of the fourth, from a project deployed outside Vercel: `vercel-optimize`,
`deploy-to-vercel` and `vercel-cli-with-tokens` are not installed, and that is the reason.

## The override table

Rule 3 in practice. Keep one of these per project, in the consuming agent's body or the
project's skills README — the whole value is that nobody re-derives it on each encounter.

| Skill | Load when | Rules that do **not** apply here |
| --- | --- | --- |
| `vercel-react-best-practices` | Reviewing or writing React for bundle size, re-renders, loops | `client-swr-dedup` (no client fetching); `bundle-defer-third-party` (no third parties, by audit); `server-after-nonblocking` on a route that must await its upstream to return a real error |
| `web-design-guidelines` | A UI, accessibility or UX review | Title Case and "avoid first person" (the house voice is first person, sentence case); curly quotes; "URL reflects state"; `:focus-visible` on the skip link — it is `:focus` deliberately, so a keyboard user sees it on the first tab |
| `vercel-react-best-practices` | In a client-only app | The whole `server-*`, `rendering-hydration-*`, `async-api-routes` and `async-suspense-boundaries` families |
| `impeccable` | A redesign, a critique, or a surface that needs to stop looking templated | Its `live` browser-iteration mode where the project has no runnable dev server; its native `ios`/`android` references on a web-only project; anything that would run its binary without that being a decision you made |

The third row is the common case and the one worth stating explicitly: entire rule families
are written for a rendering model the project does not use. Skipping them is a decision, and
this is where it gets written down rather than rediscovered.

## Provenance and maintenance

Hashes and refs read 2026-09-20, recomputed from each pinned ref.
