---
name: git-conventions
description: Conventional Commits plus Gitmoji as used here — type selection, breaking changes, ticket extraction, branch names, and the house subject style. Load before writing a commit, branch or tag message.
---

# Git conventions

**Audience:** about to write a commit subject, a branch name, or a tag.

This is the *theory* pack — how to decide which type is right, not how to run git. Load it
before judging whether a generated message is correct.

## When NOT to use this skill

- *Whether* to commit at all, how much goes in one commit, staging discipline →
  `playbooks/git-and-commits.md`. That is policy; this is vocabulary.
- Writing the PR body → [`pr-description-generator`](../pr-description-generator/SKILL.md).

## The shape

```
<type>(<scope>)<!>: <gitmoji> <subject>

<body>

<footer>
```

`scope`, `!` and the body are optional. The gitmoji is not optional here.

## Choosing the type

The type describes **what the change does to the product**, not what it does to the files.
Moving a function is `refactor`; moving it because it was in the wrong layer and that was a
bug is `fix`.

| Type | Use when | Gitmoji |
| --- | --- | --- |
| `feat` | Users can do something they could not do before | `:sparkles:` ✨ · `:lipstick:` 💄 when it is purely visual |
| `fix` | Behaviour that was wrong is now right | `:bug:` 🐛 · `:lock:` 🔒 security · `:wheelchair:` ♿ accessibility |
| `perf` | Same behaviour, measurably less cost | `:zap:` ⚡ |
| `refactor` | Same behaviour, no measurable cost change | `:recycle:` ♻️ |
| `docs` | Only documentation moved | `:memo:` 📝 |
| `style` | Formatting only, no code meaning changed | `:art:` 🎨 |
| `test` | Tests only | `:white_check_mark:` ✅ |
| `build` | Build system, dependencies, packaging | `:arrow_up:` ⬆️ · `:wrench:` 🔧 |
| `ci` | Pipeline configuration | `:construction_worker:` 👷 |
| `chore` | Everything else with no product effect | `:bookmark:` 🔖 releases · `:fire:` 🔥 deletions |
| `revert` | Undoing a previous commit | `:rewind:` ⏪ |

**`perf` requires a number.** If you cannot say what got faster and by how much, it is
`refactor`.

## Breaking changes

A `!` after the scope **and** a `BREAKING CHANGE:` footer. Both, not either.

```
feat(api)!: the transactions endpoint returns minor units

BREAKING CHANGE: amounts are integers in minor units, not decimal strings.
Clients parsing `amount` as a float must divide by the currency exponent.
```

The bar is *a consumer must change something*. A new optional field is not breaking. A
renamed field is, even if nothing you own reads it.

## The house subject style

Subjects are lower-case, in the imperative or — the style used across these repos — as a
**declarative sentence describing the new behaviour**:

```
feat: :lipstick: amount fields group their own digits, and the preview line goes
fix: :wheelchair: the control layer speaks the page's language, and a mark is not a button
perf: :zap: a fallback that costs nothing until it wins, and the app chunk arrives early
```

Not `fix: fix focus ring on sheet handle` but `fix: the sheet handle stops wearing the focus
ring`. The subject says what is now true. It reads as a changelog line because it becomes one.

No trailing period. No ticket ID in the subject — it goes in the footer.

## Tickets

Extracted from the branch name first, then the body:

- Jira-style: `([A-Z][A-Z0-9]+-[0-9]+)` → `ABC-123`
- GitHub-style: `#[0-9]+` → `#123`

Footer: `Refs: ABC-123`, or `Closes: #123` when the merge closes it. A project that uses a
different pattern overrides it with an environment variable rather than a code change, so the
convention travels between teams.

## Branches

```
<type>/<short-kebab-description>
```

`feat/`, `fix/`, `chore/`, `docs/`, `refactor/` — plus **`hotfix/`**, which exists for
branches and not for commits. A hotfix branch is a *process* (cut from the release tag, not
from main); the commit on it is still a `fix`.

## Tags

`vX.Y.Z`, annotated, never lightweight — a lightweight tag carries no date, no author and no
message, and a release with no record of who cut it is a release nobody can audit.

## Provenance and maintenance

Generalised 2026-09-20 from a commit-message tool's own convention reference and from the
commit history of four repositories. The type table's gitmoji column is the mapping those
repositories actually use, read from `git log`, not the full Gitmoji set.
