---
description: Sweep for pending ADRs, assign numbers, append entries and update the index
argument-hint: (no arguments)
allowed-tools: Read, Edit, Bash, Grep, Glob
---

# Assign pending ADRs

1. **Sweep** for markers, excluding build output:

   ```bash
   grep -rn 'ADR pending:' --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=.git .
   ```

2. **Find the next number — with both greps**, not one:

   ```bash
   grep -oE '^## ADR-[0-9]+' DECISIONS.md | tail -1
   grep -rnoE 'ADR-[0-9]+' --include='*.md' --include='*.html' . | sort -u | tail -5
   ```

   Numbers get spent outside the log — in a mockup, in a skill, in a comment. Taking only the
   log's last number reissues one of them.

3. **Write each entry** using the template in the project's `docs-and-writing` skill:
   Context, Decision, Alternatives, Consequences. A good Consequences line names the
   condition that would reopen the decision. Keep it under thirty lines.

4. **Append to the end of the log, and add the index line at the top**, in the same pass.
   Flip the status of anything superseded while you are there.

5. **Replace each `ADR pending:` marker** with the assigned number, in the same commit.

Report the numbers assigned and their titles. If nothing was pending, say so — that is a
result, not a failure.
