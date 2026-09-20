# CLAUDE.md

Guidance for working **inside this repository**. Everything here is about maintaining the
bank; the bank's own contents are the thing being maintained, not instructions to follow.

## What this is

A public repository holding one person's development configuration: Claude Code skills and
agents, dotfiles, architecture templates, and the practices behind them. It is installed onto
machines with `scripts/install.sh` and into projects with `scripts/new-project.sh`.

## Hard rules

1. **Nothing sensitive, ever.** No hostnames, IP addresses, emails, absolute home paths,
   employer names, repository names of private projects, or credential names.
   `scripts/scan-secrets.sh` runs as a pre-commit hook. Do not bypass it; fix the line, or
   add the `allow-secret-pattern` marker only where the pattern exists in order to be
   documented. Names that cannot appear in the published rule list go in `.scan-denylist`,
   which is gitignored — see `playbooks/security-baseline.md`.
2. **Topology is the leak, not credentials.** A credential gets noticed and rotated. A
   deploy diagram does not.
3. **English, everywhere.** Every file in this repository — documentation, comments inside
   copied dotfiles, commit messages, all of it. The repository is public and its readers are
   not all Spanish speakers. `catalog.mjs` checks for Spanish and fails the gate; this rule
   was broken once, in the README, and caught by hand rather than by the tooling.
4. **A fact has one home.** If it is in a skill, it is not also in a playbook. Cross-reference
   by name. Two copies drift and a reader cannot tell which is current.
5. **Nothing is described in the present tense unless it exists.** No aspirational README.
6. **Generated files are generated.** `catalog.json` and `INDEX.md` come from
   `node scripts/catalog.mjs --write`. Never hand-edit either.
7. **Everything published here must be de-projectised.** A skill lifted from a project loses
   its prefix, its domain examples and its private references.
8. **Every rule carries its cost.** Where a rule exists because something broke, say what
   broke. A rule with no reason gets argued with on every review until it is dropped.
9. **Commits: Conventional Commits plus gitmoji, subject as a declarative sentence, no AI
   trailers.** See [`playbooks/git-and-commits.md`](playbooks/git-and-commits.md). Never
   commit without being asked. Never push.

## Layout

```
claude/        the Claude Code bank        skills · agents · commands · hooks · settings · memory
playbooks/     the practices, in prose
architecture/  guides with copyable files  monorepo · boundaries · ci-cd · containers
ui/            atomic design · tokens · patterns · accessibility
dotfiles/      the machine layer
scripts/       install · new-project · doctor · sync-skill · catalog · scan-secrets
```

## The gate

```bash
./scripts/scan-secrets.sh          # must exit 0
node scripts/catalog.mjs           # must exit 0 — verifies and lints
./scripts/doctor.sh                # reports; warnings are acceptable
```

`catalog.mjs` is the linter for the authoring standard. It fails on a skill whose frontmatter
`name` differs from its directory (that skill silently never loads), a description over 35
words, a `SKILL.md` over 350 lines, a skill with no "When NOT to use this skill" section, an
agent with no MUST NOT section, and a stale `catalog.json` or `INDEX.md`.

## Adding to the bank

Read the standard first. It is not optional and the linter enforces most of it:

| Adding | Read |
| --- | --- |
| A skill | [`claude/skills/meta/skill-authoring`](claude/skills/meta/skill-authoring/SKILL.md) |
| An agent | [`claude/skills/meta/agent-authoring`](claude/skills/meta/agent-authoring/SKILL.md) |
| Anything with a size limit | [`claude/skills/meta/doc-budgets`](claude/skills/meta/doc-budgets/SKILL.md) |

Then regenerate:

```bash
node scripts/catalog.mjs --write
```

## Definition of Done

- `scan-secrets.sh` clean and `catalog.mjs` clean.
- `catalog.json` and `INDEX.md` regenerated in the same commit as whatever changed.
- Any shell script passes `bash -n`; any JSON parses; any `.mjs` passes `node --check`.
- A new skill or agent is referenced from the README of its directory — an entry reachable
  only through the catalog is an entry nobody finds by browsing.
- Nothing describes something that does not exist.

## Why there is no `.claude/skills` here

The bank is installed at **user level** by `scripts/install.sh`, so it is already loaded when
working in this repository. Symlinking it into `.claude/` as well would register every skill
twice under the same name, which is worse than not dogfooding. See `DECISIONS.md`, ADR-004.
