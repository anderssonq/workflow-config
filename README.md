# workflow-config

Dotfiles and AI development tools configuration. Includes Claude Code skills, agents, custom rules, and workflow automation for seamless development across multiple machines.

## 📁 Structure

```
.claude/
├── agents/                    # Specialized Claude agents
│   ├── spec-context-agent.md  # Spec-driven development orchestrator
│   └── pr-review-agent.md     # Code review + PR description generator
├── skills/                    # Reusable development skills
│   ├── spec-driven-development/
│   ├── frontend-review-code/
│   └── pr-description-generator/
.spec/                         # Generated spec artifacts (gitignored)
.tmp/                          # Generated output files (gitignored)
```

## 🚀 Quick Start

### Using Spec Context Agent

Transform Jira tasks into complete specifications before coding:

```
@spec-context-agent create spec for the following Jira task:

[Paste your Jira URL or task description]
```

**What you get:**
- `.spec/[task-id]-specification.md` — requirements & acceptance criteria
- `.spec/[task-id]-plan.md` — technical design & implementation approach
- `.spec/[task-id]-tasks.md` — ordered, implementable task list

Human approval is required at each step before proceeding.

### Using PR Review Agent

Generate PR descriptions after implementation:

```
@pr-review-agent review and write the PR
```

**What you get:**
- Full senior-level code review
- Structured PR/MR description saved to `.tmp/`

## 🎯 Workflow

```
1. Spec Phase
   @spec-context-agent [Jira URL or description]
   → Generates .spec/[task-id]-{specification,plan,tasks}.md
   → Human approves at each gate (Specify → Plan → Tasks)

2. Implementation Phase
   → Follow tasks from .spec/[task-id]-tasks.md

3. Review & PR Phase
   @pr-review-agent review and write the PR
   → Reviews changes, generates PR description in .tmp/
```

## 🛠️ Skills

### spec-driven-development
4-phase gated workflow (Specify → Plan → Tasks → Implement). Enforces human approval before any code is written.

### frontend-review-code
Senior-level code review for TypeScript, JavaScript, React, Vue, Angular, HTML, SCSS.

### pr-description-generator
Generates structured PR descriptions following Conventional Commits + Gitmoji.

## 🎓 Best Practices

### ✅ Do
- Use `spec-context-agent` before starting implementation
- Approve at each gate (Specify, Plan, Tasks)
- Commit `.spec/` files alongside implementation code
- Reference specs in PR descriptions

### ❌ Don't
- Skip spec generation for "simple" tasks
- Proceed without human approval at gates
- Delete spec files after implementation

## 📦 Installation

1. Clone this repository
2. Copy `.claude/` folder to your project root
3. Start using agents with `@agent-name` syntax

## 📄 License

MIT
