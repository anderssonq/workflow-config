---
description: Run this project's acceptance gate and report what actually happened
allowed-tools: Read, Bash, Grep, Glob
---

# Acceptance gate

Run the project's Definition of Done gate, in order, and stop at the first failure.

1. Find the commands. In order of authority: `CLAUDE.md`'s Definition of Done, then the
   `validation-and-qa` skill, then the manifest's scripts. If the first two disagree with
   the third, **say so** — that disagreement is itself a finding.
2. Run each step. Respect the ordering constraints the project declares (a build that must
   precede tests because a package is consumed as built output, for example).
3. Report:

```
lint   ✓ / ✗   <the last meaningful line of output>
build  ✓ / ✗
test   ✓ / ✗   <counts>
```

Rules for the report:

- **If a step fails, paste the failure.** Do not summarise it and do not proceed.
- **If a step was skipped, say it was skipped**, and why.
- Do not say "all green" unless every step ran in this invocation. A cached result from
  earlier in the session is not a run.
