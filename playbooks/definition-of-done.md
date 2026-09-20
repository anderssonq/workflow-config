# Definition of Done

What "finished" means, and why each clause is in it. A project's `CLAUDE.md` holds its own
version; this is the shape to write it from, and it wins on conflict where a project has
said something different.

## The gate

```
lint  &&  build  &&  test      all green, in this invocation
```

Three things about it:

- **It is the same gate CI runs.** If the two lists differ, one of them is wrong, and it is
  usually CI — because the local list gets extended and the workflow does not.
- **Order can matter.** A shared package consumed as built output must build before anything
  tests against it. Write the ordering constraint down; do not leave it to be rediscovered.
- **A cached result from earlier in the session is not a run.** "All green" means it ran now.

## Behaviour is proved, not asserted

- New behaviour has a test. Minimum a unit test; a new external surface gets an end-to-end
  test as well.
- **Revert the change and watch the test fail, once.** A test that passes either way covers
  nothing, and it will be trusted anyway.
- A fixture retuned to make a test pass is not a fix. Either the code is wrong or the
  assertion is wrong; changing the input until they agree is neither.

## Documents move in the same commit

- An architecture or data-model change updates `ARCHITECTURE.md` **and** adds a
  `DECISIONS.md` entry, in the commit that makes the change.
- Not the next commit. Not a docs pass later. Documentation that trails by even one commit
  is documentation that describes a repository that does not exist.

## Team upkeep is part of done

- A convention that changed updates the `SKILL.md` that states it, same commit.
- A delegation that misfired is fixed at the source: the agent's `description` for routing,
  its body for context. Not as prose in a third place.

This clause is what keeps a skill set from decaying into a description of a codebase from
six months ago.

## Budgets

Within the limits in [`doc-budgets`](../claude/skills/meta/doc-budgets/SKILL.md). Checked,
not estimated.

## No out-of-scope scaffolding

- No `TODO` without a matching line in the "Planned, not yet built" section.
- No abstraction introduced for a second caller that does not exist yet.
- No configuration option added "in case". An option with one value is a constant with extra
  steps and a second place to be wrong.

## What done does **not** include

- Committing. That is the owner's call, every time.
- Pushing. Never, and especially not where push is deploy.
- Cleaning up unrelated things you noticed. Report them; the request is consent for what it
  plainly asks.
