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

### Adding a new skill

1. Create `.claude/skills/<skill-name>/SKILL.md`.
2. Write the frontmatter (`name`, `description`) and the full prompt body.
3. The description field determines when Claude auto-triggers the skill — write it as the user-facing trigger conditions, not as internal documentation.

## Output conventions

Skills that generate files default to `.tmp/` (gitignored). Naming pattern: `<TICKET_KEY>-<ARTIFACT>.md` (e.g. `APP-123-PR-DESCRIPTION.md`, `APP-123-CODE-REVIEW.md`). If no ticket, use a sanitized branch name. Versioned with `-v2`, `-v3` suffixes if the file already exists.
