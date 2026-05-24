---
name: prompt-context-library
description: >
  Save and retrieve reusable project context, agent instructions, and recurring prompts
  as markdown files in ./tmp/contexts/. Use this skill whenever the user says "save this
  context", "save this as reusable context", "load context for X", "use my saved context",
  "what contexts do I have", or anything that implies capturing or reusing a prompt/context
  they've written before. Also trigger when the user is about to repeat themselves for an
  agent task and wants to avoid rewriting the same instructions. Always prefer this skill
  over asking the user to retype context manually.
---

# Prompt Context Library

A skill for saving and retrieving reusable project context and agent instructions.
Contexts are stored as markdown files in `./tmp/contexts/`.

---

## Storage Location

```
./tmp/contexts/
└── <slug>.md   # one file per saved context
```

Always create `./tmp/contexts/` if it doesn't exist before reading or writing.

---

## Operations

### 1. SAVE

**Triggers:** "save this context", "save this as reusable context", "save this for later"

**Steps:**
1. Extract the context to save — either from the current conversation or from what the user explicitly provides.
2. Ask the user for a short name/slug if not already given. Use kebab-case (e.g. `company-x-backend`, `sabre-flight-search`).
3. Build the markdown file with this structure:

```markdown
# <Human-readable title>

**Saved:** <YYYY-MM-DD>
**Tags:** <optional comma-separated tags>

## Context

<The full context, instructions, or prompt block>

## Notes

<Any extra notes the user mentioned, or leave empty>
```

4. Write to `./tmp/contexts/<slug>.md`.
5. Confirm to the user: the file name, a one-line summary of what was saved.

---

### 2. LOAD / RETRIEVE

**Triggers:** "load context for X", "use my saved context", "inject context for X", "what context do I have for X"

**Steps:**
1. List all files in `./tmp/contexts/`.
2. Match the user's request to the most relevant file by name or content scan.
3. Read the file and inject the full **Context** section into the conversation.
4. Tell the user which context was loaded and offer to modify it if needed.

---

### 3. LIST

**Triggers:** "what contexts do I have", "list my saved contexts", "show my context library"

**Steps:**
1. List all `.md` files in `./tmp/contexts/`.
2. For each file, extract the title (first `#` heading) and `**Saved:**` date.
3. Present as a clean table:

| Slug | Title | Saved |
|------|-------|-------|
| company-x-backend | Company X Backend Context | 2025-01-10 |

---

### 4. UPDATE

**Triggers:** "update context for X", "edit my X context", "add this to my X context"

**Steps:**
1. Load the existing file.
2. Apply the user's changes (append, replace section, or full rewrite depending on request).
3. Update the `**Saved:**` date to today.
4. Write back to the same file.
5. Confirm the change with a one-line diff summary.

---

### 5. DELETE

**Triggers:** "delete context for X", "remove my X context"

**Steps:**
1. Confirm with the user before deleting: *"Are you sure you want to delete `<slug>.md`?"*
2. Only delete after explicit confirmation.
3. Confirm deletion.

---

## Guidelines

- **Never overwrite** an existing context silently — always confirm if the slug already exists.
- **Keep slugs consistent** with the project name or task they relate to.
- If the user provides a long block of text with no clear structure, extract a clean title and organize it into the template before saving.
- When loading context, always read the **full file** and inject the Context section verbatim — don't summarize it.
- If `./tmp/contexts/` is empty, tell the user and offer to save the current conversation context.