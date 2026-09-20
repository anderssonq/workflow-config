---
name: debugging-playbook
description: Symptom-first triage for this project — the two-minute discriminator, per-area symptom tables, and how to read its logs. Load when something is broken and the cause is not obvious.
---

# Debugging playbook

**Audience:** something is broken right now and you are deciding where to look.

Triage, not history. Read top to bottom the first time; after that, jump to the table.

## When NOT to use this skill

- "Has this happened before, and what was tried?" →
  [`failure-archaeology`](../failure-archaeology/SKILL.md).
- "Is this even supposed to work?" →
  [`architecture-contract`](../architecture-contract/SKILL.md).
- "How do I start it at all?" →
  [`build-run-and-operate`](../build-run-and-operate/SKILL.md).

## The two-minute discriminator

Before opening any source file, answer: **environment, configuration, or code?**

| Ask | If yes |
| --- | --- |
| Does it fail on a clean checkout of a known-good commit? | **Environment.** Toolchain, versions, ports, a stale cache, a process still holding a port. |
| Does the same commit behave differently in two places? | **Configuration.** An env var, a build-time inline, a flag, a `.env` that is not the one you think. |
| Does it fail identically everywhere, from a clean state? | **Code.** Now read the diff. |

Most time lost in debugging is spent reading code for an environment problem. Two minutes
here saves an afternoon.

## Symptom tables

<!-- FILL: one table per area. Keep them symptom-first — the reader knows the symptom, not
     the subsystem. Replace the example rows entirely. -->

### A. It will not start

| Symptom | Most likely | First check |
| --- | --- | --- |
| Port already in use | A previous run did not exit | `lsof -i :PORT -sTCP:LISTEN` |
| Missing env var at boot | The validated env schema is doing its job | Diff `.env` against `.env.example` |

### B. It starts, then misbehaves

| Symptom | Most likely | First check |
| --- | --- | --- |

### C. Tests or builds fail

| Symptom | Most likely | First check |
| --- | --- | --- |

### D. Dependencies and toolchain

| Symptom | Most likely | First check |
| --- | --- | --- |

## Reading the logs

<!-- FILL: the log format, where they are, and three or four recipes that actually get used.
     e.g. for structured JSON logs:
       tail -f app.log | jq -r 'select(.level>=50) | "\(.time) \(.msg)"'
     Name the fields that matter and the ones that are noise. -->

## Deep triage

When the tables do not cover it, go layer by layer and **prove each layer before moving on**:

1. Is the process running, and is it the one you think? (`ps`, the PID, the start time.)
2. Is it listening where you think? (`lsof`, `curl` the health endpoint.)
3. Does the dependency answer? (Hit it directly, not through the app.)
4. Does the app's own view agree? (Its logs at boot, its config dump.)
5. Only now, the code.

**Prove the root cause before fixing it.** A fix applied to a guess produces two problems:
the original one, still there, and a change nobody can justify.

## Provenance and maintenance

<!-- FILL: verified date. -->
