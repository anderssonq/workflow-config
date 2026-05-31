---
name: pr-description-generator
description: Generates a comprehensive Pull Request / Merge Request description for the current branch. Use this skill whenever the user asks to "generate a PR description", "write a PR", "describe this change for review", "create the MR description", "write the merge request", "PR write-up for this branch", "describe what I did", or anything similar — even casual phrasings ("write up the PR", "draft the PR body", "I need a PR description"). Also trigger when the user finishes a feature and asks "what should I put in the PR". Works in any Git repo and any ticket tracker (Jira / Linear / GitHub Issues / none).
model: sonnet
---

# PR Description Generator

Generates a polished, structured PR/MR description for the current branch. The output is a Markdown file the user can paste directly into the PR form.

## Operating modes

**Claude Code / any agent environment with bash + git** — execute the full workflow autonomously. Run commands, capture output, produce the file. This is the primary mode.

**claude.ai chat (no terminal)** — degrade to guided mode: print each command for the user to run locally, ask them to paste the output, continue from there. See "Degraded mode" at the bottom of this file.

If unsure which mode you're in, try `bash` once with a harmless command. If it fails, you're in chat mode.

---

## Configuration

Before running any step, resolve these settings. Order of precedence: explicit user instruction > config file in the repo > sensible default.

| Setting | Default | How to override |
|---|---|---|
| `base_branch` | auto-detect (see Step 0) | user message, or `--base <name>` |
| `ticket_prefix` | regex `[A-Z][A-Z0-9]+-\d+` | user message, e.g. "prefix is PROJ" |
| `ticket_tracker` | detect from MCPs / URLs in git remote | user message |
| `output_dir` | `.tmp/` (create if missing) | user message |

**Ticket URL templates** (fill `{KEY}`):
- Jira: `https://{ORG}.atlassian.net/browse/{KEY}` — `{ORG}` from `git remote -v` or user
- Linear: `https://linear.app/{ORG}/issue/{KEY}`
- GitHub Issues: `https://github.com/{OWNER}/{REPO}/issues/{NUMBER}` — from `git remote get-url origin`

If a `.claude/pr-config.json` exists in the repo root, read it first. Schema:

```json
{
  "base_branch": "main",
  "ticket_prefix": "PROJ",
  "ticket_tracker": "jira",
  "ticket_url_template": "https://acme.atlassian.net/browse/{KEY}",
  "output_dir": ".tmp/"
}
```

If config is partial, fill the rest from defaults / auto-detection. On first run in a new repo, **offer to save the resolved config** to `.claude/pr-config.json` — don't write it without confirmation.

---

## Step 0 — Detect and confirm base branch

1. `git branch --show-current` → store as `CURRENT_BRANCH`.
2. For each candidate in `[main, master, develop, dev]`:
   - Run `git merge-base origin/<candidate> HEAD 2>/dev/null`.
   - Count commits between merge-base and HEAD: `git rev-list --count <merge-base>..HEAD`.
3. Candidate with the **lowest** commit count is the most likely parent.
4. If none exist, try the most recent release branch: `git branch -r --list "origin/release/*" --sort=-committerdate | head -1`. Fall back to `main`.

Print to the user:

```
Detected base branch: <detected>  (N commits ahead)
Other candidates: <list with their commit counts>

Confirm or override (just say "use <branch>"). Press enter / say "ok" to accept.
```

Wait for confirmation. Save as `TARGET_BRANCH`.

---

## Step 1 — Gather context

```bash
git fetch --all --prune
git diff --name-only origin/<TARGET_BRANCH>..HEAD
git diff --stat   origin/<TARGET_BRANCH>..HEAD
git log --pretty=format:'%h %s' origin/<TARGET_BRANCH>..HEAD
git diff origin/<TARGET_BRANCH>..HEAD
```

Use two dots (`..`), never three. Three-dot syntax computes a symmetric diff and returns empty on some branch topologies.

If `git diff origin/<TARGET_BRANCH>..HEAD` returns nothing, stop and tell the user — don't generate an empty PR.

### Extract ticket key

Apply the `ticket_prefix` regex to:
1. `CURRENT_BRANCH` (e.g. `feat/PROJ-1234-add-login`)
2. Each commit subject
3. Each commit body (trailers)

First match wins. Store as `TICKET_KEY`. If nothing matches, set `TICKET_KEY = null`.

### Look up the ticket

Check which trackers are available:

- **Jira MCP** — fetch the issue with `TICKET_KEY`.
- **Linear MCP** — same.
- **GitHub MCP / `gh` CLI** — `gh issue view <NUMBER> --json title,body,state,labels,assignees`.
- **Nothing** — use whatever's in the branch/commit text.

Capture: `title`, `description`, `status`, `priority`, `assignee`, `acceptance_criteria`, `linked_issues`.

If the fetch fails, proceed with `TICKET_KEY` but no description.

### Look for specs / design docs

Scan for files referencing `TICKET_KEY` or `CURRENT_BRANCH` in:

- `.kiro/specs/`, `docs/specs/`, `docs/rfcs/`, `docs/adr/`, `specs/`, `.cursor/specs/`

If found, include the file path(s) and a 2–3 sentence summary in the PR description.

---

## Step 2 — Generate the PR description

### Filename

Pattern: `<output_dir>/<MM-DD-YY>_<INDEX>_<TICKET_KEY>-PR-DESCRIPTION.md`

- `MM-DD-YY` — today's date with dashes (e.g. `05-30-26`). No slashes; filenames don't allow them.
- `INDEX` — zero-padded 2-digit counter scoped to today. Scan `<output_dir>` for files matching `<MM-DD-YY>_*` and set INDEX to the next available number (01, 02, 03…).
- `TICKET_KEY` — the detected ticket key. If no ticket: use a sanitized branch name (e.g. `feature-add-login`).

Examples:
```
.tmp/05-30-26_01_APP-123-PR-DESCRIPTION.md
.tmp/05-30-26_02_APP-456-PR-DESCRIPTION.md
.tmp/05-31-26_01_feature-add-login-PR-DESCRIPTION.md
```

Never use `-v2` / `-v3` suffixes — the date + index already disambiguates.

### Template

```markdown
# [TICKET_KEY] Title

**Ticket:** [<TICKET_KEY>](<ticket_url>)
**Branch:** `<CURRENT_BRANCH>` → `<TARGET_BRANCH>`
**Author:** <git config user.name>
**Date:** <today's date in MM/DD/YY format — e.g. 05/30/26>

## Problem

<What issue this PR solves. Use the ticket description + acceptance criteria if available;
otherwise infer from commit messages and diff. 2–4 sentences.>

## Root cause

<Technical explanation of WHY the problem existed. Omit for greenfield features.>

## Solution

<High-level overview of the approach. 2–5 sentences. Reference the diff and any
architectural decisions. Don't list every file — that's the next section.>

## Technical details

<Implementation specifics worth highlighting:
- Architecture / pattern decisions
- New dependencies (with justification)
- Migrations / breaking changes
- Feature flags
- Performance or security considerations
Use bullets here; prose elsewhere.>

## Files changed

<Group by area, not alphabet. Example:
- **Frontend** — `src/components/Login.tsx`, `src/hooks/useAuth.ts`
- **API** — `api/auth.controller.ts`
- **Tests** — `tests/auth.spec.ts`
- **Config** — `.env.example`
For PRs with >15 files, group only — don't list every one.>

## Ticket context

<If ticket fetched:
- **Goal:** <from ticket description>
- **Acceptance criteria:**
  - [x] criterion 1 (addressed by <file:line>)
  - [ ] criterion 2 (NOT in this PR — follow-up)
- **Linked:** <blockers, follow-ups>

If unavailable: "Ticket tracker was unavailable" or "No ticket detected".>

## Notes for reviewers

<Areas you want focused review, known follow-ups, things deliberately out of scope,
or why a particular tradeoff was chosen. Omit if nothing notable.>

## Checklist

- [ ] Tests added / updated
- [ ] Documentation updated (if user-facing)
- [ ] Breaking changes communicated
- [ ] Feature flags configured (if applicable)
- [ ] Migration steps documented (if applicable)
```

### Rules for writing the description

- **First sentence carries the most weight.** A reviewer who reads only that line should know what changed and why.
- **No fluff.** Start with what changed, not "This PR aims to…"
- **Cite `file:line` for technical claims.**
- **Don't reproduce the diff.** Summarize it.
- **Distinguish what's in this PR from what's deferred.**
- **Skip sections that have nothing useful.** An empty "Root cause" is worse than no section.
- **Match repo tone.** If existing PRs are casual, match it.

---

## Step 3 — Report

Print a final summary:

```
📄 PR description: <path>

Branch: <CURRENT_BRANCH> → <TARGET_BRANCH>  (<N> commits, <N> files changed)
Ticket: <TICKET_KEY> — <title>  (status: <status>)

Next steps:
  - Review the generated file and edit anything that's off
  - Copy into your PR / MR body
```

---

## Behavioral rules

- **Don't fabricate.** If a ticket couldn't be fetched, say so — don't invent acceptance criteria.
- **NEVER create commits.** Don't run `git add`, `git commit`, or any command that modifies git history.
- **Don't `git push`, don't create the PR via API, don't merge anything.** This skill only produces a Markdown file.
- **Don't run `git fetch` without `--prune` and `--all`.**
- **Two dots in `git diff`, never three.**
- **Respect the user's repo conventions.** If existing PR descriptions use different section names or order, adapt.

---

## Degraded mode (claude.ai chat, no bash)

Print commands for the user to run locally and ask them to paste output. Batch related commands into one block:

```
Please run this and paste the result:

    git branch --show-current
    git diff --name-only origin/main..HEAD
    git diff --stat origin/main..HEAD
    git log --pretty=format:'%h %s' origin/main..HEAD
    git diff origin/main..HEAD

(swap `main` for your base branch if different)
```

For ticket context, ask the user to paste the ticket text directly if no MCP is connected.

Produce the final PR description as a Markdown code block in the chat reply rather than a file.
