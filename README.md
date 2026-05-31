# workflow-config

Dotfiles and AI development tools configuration. Includes Claude Code skills, agents, custom rules, and workflow automation for seamless development across multiple machines.

## 📁 Structure

```
.claude/
├── agents/                         # Specialized Claude agents
│   ├── spec-context-agent.md       # Spec-driven development orchestrator
│   ├── pr-review-agent.md          # Code review + PR description generator
│   ├── pr-description-agent.md     # PR description only (no review)
│   └── knowledge-graph-agent.md    # Builds/queries a project knowledge graph
├── skills/                         # Reusable development skills
│   ├── spec-driven-development/
│   ├── code-reviewer/
│   ├── pr-description-generator/
│   ├── prompt-context-library/
│   └── knowledge-graph/
.spec/                              # Generated spec artifacts (gitignored)
.tmp/                               # Generated output files (gitignored)
graphify-out/                       # Knowledge-graph output (graph.json, report, html)
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

For a PR description **without** a review, use `@pr-description-agent` instead.

### Using Knowledge Graph Agent

Map a project into a queryable knowledge graph — then ask questions instead of grepping:

```
@knowledge-graph-agent map this project
@knowledge-graph-agent what connects pr-review-agent to code-reviewer?
@knowledge-graph-agent explain code-reviewer
```

**What you get** (under `graphify-out/`):
- `graph.json` — nodes, edges, communities, god nodes (confidence-tagged: EXTRACTED / INFERRED / AMBIGUOUS)
- `GRAPH_REPORT.md` — most-connected concepts, surprising cross-module links, the "why", suggested questions
- `graph.html` — self-contained interactive viz (click, search, filter by community)

Fully native — no external package or API key. Re-run with `--update` after changes to refresh only what moved.

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

### code-reviewer
Comprehensive code review for TypeScript, JavaScript, Python, Swift, Kotlin, Go. Includes analysis scripts, best-practice checks, security scanning, and review-checklist generation.

### pr-description-generator
Generates structured PR descriptions following Conventional Commits + Gitmoji.

### prompt-context-library
Save and retrieve reusable prompts and project context as markdown, so you don't rewrite the same instructions for recurring agent tasks.

### knowledge-graph
Maps a project (code, docs, configs, media) into a queryable knowledge graph using only native tools — a Claude-native replica of graphify with no external package. Produces `graph.json` + `GRAPH_REPORT.md` + `graph.html`; supports query / path / explain and incremental `--update`.

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
