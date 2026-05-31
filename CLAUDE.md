# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo is a personal Claude Code configuration store — dotfiles and AI workflow tooling synced across machines. It contains custom skills (reusable prompt workflows) and serves as the source of truth for Claude Code setup.

## Repository structure

```
.claude/
  skills/
    <skill-name>/
      SKILL.md   # The skill definition — frontmatter + full prompt
  agents/
    <agent-name>.md   # Subagent definition — frontmatter + workflow prompt
.tmp/            # Generated output files (gitignored); skills write here by default
```

## Skills

Skills live in `.claude/skills/<name>/SKILL.md`. Each file has YAML frontmatter followed by the skill prompt:

```markdown
---
name: <kebab-case>
description: <one-liner used by Claude to decide when to trigger the skill>
---

# Skill title
...prompt body...
```

The `description` field is the trigger surface — it's what Claude reads to decide whether to invoke the skill. Keep it precise and example-rich.

### Current skills

- **`pr-description-generator`** — PR/MR description workflow: base-branch detection → git diff/log → ticket lookup → structured Markdown output to `.tmp/` (no code review — that's a separate skill)
- **`frontend-review-code`** — opinionated senior-level review for JS/TS/HTML/CSS/SCSS; covers React, Vue, Angular, vanilla JS, Node.js, and modern CSS/SCSS; explicitly excludes backend, mobile-native, DB, infra, and shell
- **`knowledge-graph`** — Claude-native replica of "graphify": maps a project (code, docs, configs, media) into a queryable knowledge graph using only native tools (Glob/Grep/Read) — no external package. Emits `graphify-out/{graph.json, GRAPH_REPORT.md, graph.html}` with god nodes, communities, surprising connections, the "why", and confidence-tagged edges; supports query/path/explain and incremental `--update`

### Adding a new skill

1. Create `.claude/skills/<skill-name>/SKILL.md`.
2. Write the frontmatter (`name`, `description`) and the full prompt body.
3. The description field determines when Claude auto-triggers the skill — write it as the user-facing trigger conditions, not as internal documentation.

## Agents

Agents live in `.claude/agents/<name>.md` — YAML frontmatter (`name`, `description`, `model`, optional `color`, `permissions`) followed by a workflow prompt. The `description` is the trigger surface Claude uses to decide when to delegate to the agent. Agents typically bootstrap by reading one or more skills, then drive a multi-step workflow.

### Current agents

- **`pr-description-agent`** — PR/MR description **only** (no code review). Reads `pr-description-generator/SKILL.md` and produces a Markdown PR description for the current branch.
- **`pr-review-agent`** — code review **+** PR description. Reads `code-reviewer` then `pr-description-generator`, using the review as context for the write-up.
- **`spec-context-agent`** — spec-driven development. Reads `spec-driven-development` and generates specification/plan/tasks artifacts in `.spec/`.
- **`knowledge-graph-agent`** — builds and queries a project knowledge graph natively (no external tool). Reads `knowledge-graph` then routes between build, query (`what connects X to Y`, `explain`, `path`), and incremental update.

### Adding a new agent

1. Create `.claude/agents/<agent-name>.md` with frontmatter and a workflow prompt.
2. Have the agent read the relevant skill(s) first, then carry out the workflow.
3. Write `description` as the user-facing trigger conditions, and steer overlapping triggers toward the right agent (e.g. PR-only vs. review+PR).

## Output conventions

Skills that generate files default to `.tmp/` (gitignored). Naming pattern: `<TICKET_KEY>-<ARTIFACT>.md` (e.g. `APP-123-PR-DESCRIPTION.md`, `APP-123-CODE-REVIEW.md`). If no ticket, use a sanitized branch name. Versioned with `-v2`, `-v3` suffixes if the file already exists.
