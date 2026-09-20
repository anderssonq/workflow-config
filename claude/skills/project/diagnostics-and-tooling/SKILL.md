---
name: diagnostics-and-tooling
description: The runnable measurement scripts this project ships and what each one proves. Load when a claim needs a number instead of an impression.
---

# Diagnostics and tooling

**Audience:** about to make a claim that deserves a measurement.

"Measure instead of eyeball" only works if the measurement is one command away. This skill
exists to keep those commands findable and honest.

## When NOT to use this skill

- The acceptance gate that must be green → [`validation-and-qa`](../validation-and-qa/SKILL.md).
- Triaging a break → [`debugging-playbook`](../debugging-playbook/SKILL.md).

## The scripts

| Script | Proves | Exits non-zero when |
| --- | --- | --- |
<!-- FILL: one row per script under this skill's scripts/ directory. The third column is
     what makes a script a gate rather than a report — say plainly which ones are gates
     and which are report-only, because a report-only script that everyone assumes is a
     gate is worse than no script. -->

## Writing a new one

1. **One question per script.** A script that answers three questions gets run for one and
   its other two outputs get ignored.
2. **Print what was checked, not just the verdict.** A green check with no visible input is
   a green check nobody trusts twice.
3. **Exit codes are the interface.** `0` pass, non-zero fail, and say in the header which.
4. **No network unless the question is about the network.** A diagnostic that needs the
   internet cannot be run while debugging the internet.
5. **Declare the globals it uses** rather than widening the project's lint config for a path
   that ships nothing.

## Provenance and maintenance

<!-- FILL: verified date. -->
