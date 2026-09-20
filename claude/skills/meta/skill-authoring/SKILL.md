---
name: skill-authoring
description: How to write a SKILL.md that a model will actually load at the right moment and trust. Load before creating, splitting, renaming or retiring any skill.
---

# Writing a skill

**Audience:** whoever is about to add or change a `SKILL.md`, in this bank or in a project.

A skill is not documentation that happens to live near an agent. It is a file the model
decides to load, under budget, in the middle of doing something else. Everything below
follows from that.

## When NOT to use this skill

- Writing an agent definition instead → [`agent-authoring`](../agent-authoring/SKILL.md).
- Writing notes an agent accumulates over time → [`memory-system`](../memory-system/SKILL.md).
- Looking up the size limits alone → [`doc-budgets`](../doc-budgets/SKILL.md).
- Writing one of the four living documents of a project (`CLAUDE.md`, `ARCHITECTURE.md`,
  `DECISIONS.md`, `README.md`) → `playbooks/documentation-system.md`.

## The frontmatter is the whole trigger surface

```yaml
---
name: kebab-case-matching-the-directory
description: What it covers, in the words a user would use, ending in "Load when …".
paths: 'src/api/**, prisma/**'        # optional; only if it should auto-load
argument-hint: '[feature-description]' # optional; only for user-invocable skills
---
```

- `name` **must** equal the directory name. A mismatch means the skill silently never loads.
- `description` is the only thing the model reads when deciding. Write it as user-facing
  trigger conditions, not as internal documentation. Pack it with the words someone would
  actually type. End it with `Load when …` so the condition is explicit.
- `paths` makes the skill auto-load when a matching file is touched. Add it only for skills
  that are *law for a zone*. A skill that auto-loads everywhere is a skill that is never read.
- Keep `description` under the budget. A description that needs a paragraph is two skills.

## The body

1. **An audience line, first.** One sentence saying who is reading and what they are about
   to do. It stops the model from applying a frontend skill to a migration.
2. **A "When NOT to use this skill" section, naming the siblings.** Routing must be explicit
   in *both* directions: if `api-conventions` says "not for schema, see `db-conventions`",
   then `db-conventions` says the inverse. Ambiguous routing is how two agents end up on the
   same file.
3. **Rules with their reason attached.** "Use integer minor units" is a rule someone will
   argue with. "Use integer minor units — a float cent is a rounding bug that only appears
   in production" is a rule that survives. Where a rule exists because something broke,
   say what broke.
4. **Jargon defined once, at first use.** Never twice, never nowhere.
5. **One home per fact.** If a fact lives in another skill, reference it by name. Two copies
   drift, and the reader cannot tell which one is current.
6. **Commands verified, or labelled.** Every command in a skill was either run, or it carries
   `UNVERIFIED` where the reader can see it.
7. **Volatile facts date-stamped.** Versions, measurements, counts and external behaviour get
   a `YYYY-MM-DD`. A number with no date is a number nobody can audit.

## Provenance and maintenance

Every skill ends with a section by this name. It carries:

- where the content came from (a file, a commit, an external doc, an incident),
- the date it was last verified,
- one re-verification command per claim that drifts.

```markdown
## Provenance and maintenance

Verified 2026-09-20 against `apps/api/src`.

| Claim | Re-verify with |
| --- | --- |
| Every module has a `*.spec.ts` | `find apps/api/src -name '*.module.ts' \| …` |
```

Without this section a skill ages into confident fiction, and nobody can tell when.

## Splitting, renaming, retiring

- **Split** when the file crosses its line budget, not before. Name the split in both halves
  so a reader who lands on one knows the other exists.
- **Retire by deleting the directory.** A skill is a living file, not a log — never leave a
  "deprecated" tombstone.
- **Before deleting or renaming**, sweep every reference in the same commit:
  ```bash
  grep -rn '<skill-name>' CLAUDE.md .claude/ claude/ playbooks/
  ```

## The checklist

- [ ] `name` equals the directory name
- [ ] `description` reads as trigger conditions and ends in "Load when …"
- [ ] `paths` present only if it should auto-load
- [ ] audience line at the top
- [ ] "When NOT to use this skill", naming siblings in both directions
- [ ] every rule carries its reason
- [ ] jargon defined once
- [ ] no fact duplicated from another skill
- [ ] commands verified or labelled `UNVERIFIED`
- [ ] volatile facts date-stamped
- [ ] "Provenance and maintenance" present
- [ ] within the budgets

## Provenance and maintenance

Distilled 2026-09-20 from the authoring standard that four independent projects converged
on. The checklist is the union of the rules all four enforce.

| Claim | Re-verify with |
| --- | --- |
| Every skill here meets the checklist | `scripts/check-catalog.mjs --lint-skills` |
