# Git and commits

The policy. The vocabulary — types, gitmoji, breaking changes, ticket extraction — lives in
[`claude/skills/core/git-conventions`](../claude/skills/core/git-conventions/SKILL.md).

## One commit per session or plan

Not one per logical change. A session that touched four files in service of one outcome is
one commit.

This deliberately rejects hunk-level staging. `git add -p` on an agent-assisted session costs
more attention than the tidier history is worth, and the history it produces is fictional
anyway — those four "logical changes" were never separately true.

**Stage explicitly.** Name the paths, or run `git add -A` only after reading `git status`.
Then verify before committing:

```bash
git diff --cached --stat
```

A commit whose contents surprised you is a commit that should not have happened.

## Never commit without being asked

The commit is the owner's decision, every time, not a default at the end of a task. This is
not a formality: a commit is the first irreversible-ish step, and the owner may be mid-way
through something the agent cannot see.

**Never push.** Local history stays surgery-friendly — `--amend` and `reset --soft` are safe
precisely because nothing has left the machine.

## Never rewrite the working tree

No `stash`, no `checkout <path>`, no `restore`, no `reset --hard`.

The reason is specific and not obvious: **parallel sessions share the working tree.** Another
agent, or the owner in another window, may be holding uncommitted work. A stash that "cleans
up" before a build destroys it silently and leaves no trace at the point of loss.

To read a previous version, read it:

```bash
git show HEAD:path/to/file
git show <sha>:path/to/file
```

## Subjects say what is now true

Conventional Commits plus gitmoji, lower case, no trailing period. The subject is a
**declarative sentence describing the new behaviour**:

```
feat: :lipstick: amount fields group their own digits, and the preview line goes
fix: :wheelchair: the control layer speaks the page's language, and a mark is not a button
perf: :zap: a fallback that costs nothing until it wins, and the app chunk arrives early
fix: :lipstick: the sheet handle stops wearing the focus ring
```

Not `fix: fix focus ring on sheet handle`. The difference is that the first reads as a
changelog line — because it becomes one — and the second reads as a ticket title.

Two clauses joined by "and" is a normal shape here. It describes a change that had two
visible effects, which is what most changes have.

## No AI trailers

No `Co-Authored-By`, no `Generated with`, no model attribution of any kind, in commit
messages or PR descriptions.

**This overrides tool and harness defaults, deliberately.** Several harnesses append these
automatically; the setting that disables it is
`"attribution": { "commit": "", "pr": "", "sessionUrl": false }` in `.claude/settings.json`.

Verify after committing, because a default that reappears after an update is exactly the kind
of thing nobody notices for twenty commits:

```bash
git log -1 --format=%B
```

## Branches

```
<type>/<short-kebab-description>
```

`hotfix/` exists for branches and not for commits: a hotfix is a *process* — cut from the
release tag rather than from the default branch — while the commit on it is still a `fix`.

## When push is deploy

On a repository whose default branch auto-deploys, every rule above tightens:

- A push is a production change. It needs its own yes, in the moment, for that push.
- A dependency-bot PR is **a proposal to ship**, not a chore. Read it as one.
- The release agent verifies the live surface after pushing, by checking the deployed
  version rather than the status code. A 200 from the previous build looks identical to a
  successful deploy.
