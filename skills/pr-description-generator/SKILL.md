---
name: pr-description-generator
description: Generates a comprehensive Pull Request / Merge Request description for the current branch. Use this skill whenever the user asks to "generate a PR description", "write a PR", "describe this change for review", "create the MR description", "write the merge request", "PR write-up for this branch", "describe what I did", or anything similar — even casual phrasings ("write up the PR", "draft the PR body", "I need a PR description"). Also trigger when the user finishes a feature and asks "what should I put in the PR". Works in any Git repo, with any package manager (npm/yarn/pnpm), and any ticket tracker (Jira / Linear / GitHub Issues / none). Runs quality checks first, gathers Git + ticket context, optionally pulls in code-review findings, and outputs a structured Markdown file ready to paste into GitHub/GitLab/Bitbucket.
---

# PR Description Generator

Generates a polished, structured PR/MR description for the current branch. The output is a Markdown file the user can paste directly into the PR form.

## Operating modes

**Claude Code / any agent environment with bash + git** — execute the full workflow autonomously. Run commands, capture output, produce the file. This is the primary mode.

**claude.ai chat (no terminal)** — degrade to guided mode: print each command for the user to run locally, ask them to paste the output, continue from there. See "Degraded mode" at the bottom of this file.

If unsure which mode you're in, try `bash` once with a harmless command. If it fails, you're in chat mode.

---

## Configuration (first thing to nail down)

Before running any step, resolve these settings. Order of precedence: explicit user instruction in the current message > config file in the repo > sensible default. Ask the user only for what you can't resolve from the first two.

| Setting | Default | How to override |
|---|---|---|
| `base_branch` | auto-detect (see Step 0) | user message, or `--base <name>` |
| `ticket_prefix` | regex `[A-Z][A-Z0-9]+-\d+` | user message, e.g. "prefix is PROJ" |
| `ticket_tracker` | detect from MCPs / URLs in package.json / git remote | user message |
| `ticket_url_template` | filled in below per tracker | user message |
| `output_dir` | `.tmp/` if it exists, else create `.tmp/`; fallback `docs/pr/` | user message |
| `pkg_manager` | auto-detect from lockfile | usually unambiguous |
| `quality_checks` | auto-detect from `package.json` scripts | user message |
| `monorepo_subprojects` | detect nested `package.json` files at depth 1 | user message |

**Ticket URL templates** (fill `{KEY}`):
- Jira: `https://{ORG}.atlassian.net/browse/{KEY}` — `{ORG}` from `git remote -v` or user
- Linear: `https://linear.app/{ORG}/issue/{KEY}` 
- GitHub Issues: `https://github.com/{OWNER}/{REPO}/issues/{NUMBER}` — from `git remote get-url origin`

If a `.claude/pr-config.json` exists in the repo root, read it first and use its values. Schema:

```json
{
  "base_branch": "main",
  "ticket_prefix": "PROJ",
  "ticket_tracker": "jira",
  "ticket_url_template": "https://acme.atlassian.net/browse/{KEY}",
  "output_dir": ".tmp/",
  "quality_checks": ["test", "type-check", "build"],
  "monorepo_subprojects": ["packages/app", "packages/api"]
}
```

If config is partial, fill the rest from defaults / auto-detection.

If running for the first time in a new repo, **offer to save the resolved config** to `.claude/pr-config.json` once everything is determined. Don't write it without confirmation.

---

## Step 0 — Detect and confirm base branch

1. `git branch --show-current` → current branch (store as `CURRENT_BRANCH`).
2. For each candidate in `[main, master, develop, dev]`:
   - Run `git merge-base origin/<candidate> HEAD 2>/dev/null`.
   - If it succeeds, record the merge-base commit.
   - Count commits between merge-base and HEAD: `git rev-list --count <merge-base>..HEAD`.
3. Candidate with the **lowest** commit count is the most likely parent.
4. If none of the standard candidates exist, list release branches and try the most recent: `git branch -r --list "origin/release/*" --sort=-committerdate | head -1`.
5. If nothing works, fall back to `main`.

Print to the user:

```
Detected base branch: <detected>  (N commits ahead)
Other candidates: <list with their commit counts>

Confirm or override (just say "use <branch>"). Press enter / say "ok" to accept the default.
```

Wait for the user to confirm. Save as `TARGET_BRANCH`.

---

## Step 1 — Run quality checks

### Detect the package manager

| Lockfile present | Package manager |
|---|---|
| `pnpm-lock.yaml` | `pnpm` |
| `yarn.lock` | `yarn` |
| `package-lock.json` | `npm` |
| `bun.lockb` | `bun` |
| none, but `package.json` exists | default to `npm` and warn |

Store as `PKG`. Run commands via `<PKG> run <script>` (or `npm run <script>`, etc.).

### Detect scripts to run

Read `package.json`. Run any of the following scripts that exist, in this order:

1. `lint` (or `lint:check`, `eslint`)
2. `type-check` (or `typecheck`, `tsc`)
3. `test` (or `test:unit`, `test:ci`) — non-watch variant only
4. `build`

Skip any that don't exist. **Run the test script in non-watch mode**: if you see `--watch` in the package.json definition, look for an alternate like `test:run`, `test:ci`, or run with `--run` / `--watchAll=false` depending on the framework.

### Monorepo handling

If sibling `package.json` files exist at depth 1 (e.g. `packages/web/package.json`, `apps/api/package.json`, or like the user's `kds-migration/package.json`):

- Run the scripts in each subproject too.
- Detect each subproject's package manager independently.
- Report results separately per subproject.

If `pnpm-workspace.yaml`, `turbo.json`, or a root `workspaces` field exists, prefer the workspace-level command (`pnpm -r test`, `turbo test`, `npm run test --workspaces`) if available; otherwise loop manually.

### Gating

Capture exit code, stdout tail (last ~50 lines), and a summary (test counts if parseable).

**If any check fails:**

1. Print which checks failed, with the relevant error excerpt.
2. Ask the user: "Quality checks failed. Options:
   - `fix` — stop here so you can fix and re-run
   - `proceed` — generate the PR description anyway, with a ⚠️ warning section listing failures
   - `skip <check>` — re-run skipping the listed check"
3. **Default is to stop.** Do not proceed silently.

If all pass, print a one-line summary per check (e.g. `✅ test — 142 passed`) and move on.

---

## Step 2 — Gather context

```bash
git fetch --all --prune
git diff --name-only origin/<TARGET_BRANCH>..HEAD   # NOTE: two dots, not three
git diff --stat   origin/<TARGET_BRANCH>..HEAD
git log --pretty=format:'%h %s' origin/<TARGET_BRANCH>..HEAD
```

Two dots, not three. Three-dot syntax (`...`) computes a symmetric diff and returns empty on some branch topologies.

### Extract ticket key

Apply the `ticket_prefix` regex to:
1. `CURRENT_BRANCH` (branch names like `feat/PROJ-1234-add-login`)
2. Each commit subject (first line of `git log` output)
3. Each commit body (in case it's in the trailer)

First match wins. Store as `TICKET_KEY`. If nothing matches, set `TICKET_KEY = null` and note "no ticket detected" in the output.

### Look up the ticket

Check which trackers are available in the environment:

- **Jira MCP** — if connected, fetch the issue with `TICKET_KEY`.
- **Linear MCP** — same.
- **GitHub MCP / `gh` CLI** — for issue numbers: `gh issue view <NUMBER> --json title,body,state,labels,assignees`.
- **Nothing** — note "ticket tracker unavailable" and use whatever's in the branch/commit text.

Capture: `title`, `description`, `status`, `priority`, `assignee`, `acceptance_criteria` (if present), `linked_issues` (blockers).

If the fetch fails, don't block — proceed with `TICKET_KEY` but no description.

### Look for specs / design docs

Scan these common locations for files referencing `TICKET_KEY` or `CURRENT_BRANCH`:

- `.kiro/specs/`
- `docs/specs/`, `docs/rfcs/`, `docs/adr/`
- `specs/`
- `.cursor/specs/`

If found, include the file path(s) and a 2–3 sentence summary in the PR description.

---

## Step 3 — Code review findings (optional but recommended)

### Try to find an existing review

Search for an existing code review file before running a new one. Look in `<output_dir>` and `.tmp/` for files matching:

1. `{TICKET_KEY}-CODE-REVIEW.md`
2. `{TICKET_KEY}-CODE-REVIEW-v*.md` (versioned)
3. `*CODE-REVIEW*.md` where the file references `TICKET_KEY` or `CURRENT_BRANCH` in its content

If found, read it. Use the most recent version if multiple exist. Note the source filename in the PR output.

### If no review exists

Three options, in preference order:

1. **If the `frontend-code-reviewer` skill is also installed and the diff is JS/TS/HTML/CSS/SCSS** — delegate to it. Save its output to `<output_dir>/{TICKET_KEY}-CODE-REVIEW.md` for reuse.
2. **Inline review** — read `git diff origin/<TARGET_BRANCH>..HEAD` and produce a brief review (Summary / Blocking / Should fix / Praise). Save to the same location.
3. **Skip** — only if the user says "no review" or the diff is trivial (< 20 lines, only changes formatting / docs / version bumps).

Always state in the final output which path was taken.

---

## Step 4 — Generate the PR description

### Filename

```
<output_dir>/<TICKET_KEY>-PR-DESCRIPTION.md
```

If no ticket: use a sanitized branch name (`feature-add-login-PR-DESCRIPTION.md`).

If the file already exists, append `-v2`, `-v3`, etc.

### Template

```markdown
# [TICKET_KEY] Title

**Ticket:** [<TICKET_KEY>](<filled ticket_url_template>)
**Branch:** `<CURRENT_BRANCH>` → `<TARGET_BRANCH>`
**Author:** <git config user.name>

## Problem

<What issue this PR solves. Use the Jira/Linear description + acceptance criteria if available.
If unavailable, infer from commit messages and diff. 2–4 sentences.>

## Root cause

<Technical explanation of WHY the problem existed. Only include when meaningful —
omit this section for greenfield features.>

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

<Group by area, not by alphabet. Examples:
- **Frontend** — `src/components/Login.tsx`, `src/hooks/useAuth.ts` (new auth flow)
- **API** — `api/auth.controller.ts` (token refresh)
- **Tests** — `tests/auth.spec.ts` (covers new flow)
- **Config** — `.env.example` (new keys)
For PRs with >15 files, group only; don't list every one.>

## Testing

**Project: <name from package.json>**
- ✅ Lint: <pass/fail>
- ✅ Type-check: <pass/fail>
- ✅ Unit tests: <N passed, N failed, N skipped>
- ✅ Build: <pass/fail>

<Per subproject in a monorepo>

### Manual testing

<List manual test steps the reviewer should run, or "N/A — covered by automated tests"
if applicable.>

## Code review summary

<Source: <existing file path / "inline review" / "frontend-code-reviewer skill">

Cap this section at ~4000 characters. If the review is longer, include only:
- All BLOCKERS
- All HIGH-severity issues
- Up to 3 most important "should fix" items
- Note: "See <path> for full review">

## Ticket context

<If ticket fetched:
- **Goal:** <from ticket description>
- **Acceptance criteria:**
  - [x] criterion 1 (addressed by <file:line>)
  - [ ] criterion 2 (NOT in this PR — see follow-up)
- **Linked:** <blockers, follow-ups>

If unavailable: "Ticket tracker was unavailable" or "No ticket detected".>

## Notes for reviewers

<Anything specific: areas you want focused review, known follow-ups, things
deliberately out of scope, why a particular tradeoff was chosen.>

## Checklist

- [ ] Tests added / updated
- [ ] Documentation updated (if user-facing)
- [ ] Breaking changes communicated
- [ ] Feature flags configured (if applicable)
- [ ] Migration steps documented (if applicable)
```

### Rules for writing the description

- **First sentence carries the most weight.** A reviewer who reads only that line should know what changed and why.
- **No fluff.** "This PR aims to provide a robust solution that…" → cut. Start with what changed.
- **Cite `file:line` for technical claims**, the same way a good code review does.
- **Don't reproduce the diff.** Summarize it. Reviewers can read code.
- **Distinguish what's in this PR from what's deferred.** Reviewers should never wonder "did they forget X or is it intentional?"
- **Skip sections that have nothing useful.** An empty "Root cause" is worse than no section.
- **Match repo tone.** If existing PRs are casual, match it. If formal, match that.

---

## Step 5 — Report

Print a final summary to the user:

```
📄 PR description: <path>

Quality checks:
  ✅ <project A>: lint, type-check, tests (142), build
  ✅ <project B>: tests (87)

Code review: <source> — verdict: <ship / ship with changes / needs rework>

Ticket: <TICKET_KEY> — <title> (status: <status>)

Next steps:
  - Review the generated file and edit anything that's off
  - Copy into your PR / MR body
  - Address blocking items from the code review before merging
```

If quality checks failed and the user said `proceed`, lead the summary with a ⚠️ banner.

---

## Behavioral rules

- **Don't fabricate.** If a Jira ticket couldn't be fetched, say so — don't invent acceptance criteria.
- **Don't proceed past failing quality checks without explicit user permission.**
- **NEVER create commits.** Don't run `git add`, `git commit`, or any command that modifies the git history. This skill only reads git state and produces a Markdown file.
- **Don't `git push`, don't create the PR via API, don't merge anything.** This skill only produces a Markdown file. If the user wants `gh pr create` or similar, they ask separately and confirm.
- **Don't run `git fetch` without `--prune` and `--all`.** A stale local view of the base branch ruins the diff.
- **Two dots in `git diff`, never three.**
- **If the diff is empty** (`git diff origin/<base>..HEAD` returns nothing), stop and tell the user the branch has no commits ahead of the target. Don't generate an empty PR.
- **Respect the user's repo conventions.** If their existing PR descriptions use different section names or order, adapt.

---

## Degraded mode (claude.ai chat, no bash)

When bash isn't available, run the same workflow as guided steps. For each command the skill would normally run, print it and ask the user to paste the output:

```
Please run this and paste the result:

    git branch --show-current
    git diff --name-only origin/main..HEAD
    git diff --stat origin/main..HEAD
    git log --pretty=format:'%h %s' origin/main..HEAD

(if `main` isn't your base branch, swap it in)
```

Batch related commands into one block so the user pastes one output. Don't ask for 10 things sequentially.

For quality checks, ask the user to run them locally and paste a summary ("all passed" or the failure output).

For ticket context, if no Jira/Linear MCP is connected, ask the user to paste the ticket text directly.

Produce the final PR description as a Markdown code block in the chat reply rather than a file (the user can copy-paste it).

Everything else — template, rules, sections — stays the same.
