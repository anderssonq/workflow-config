# Security baseline

The posture that applies to every project here, and the checklists for the three moments that
actually introduce risk.

## Posture

- **Default deny.** Every route requires authentication unless explicitly marked public. The
  inverse — public by default, guards added per route — ships an open endpoint the first time
  someone forgets, and nothing fails loudly.
- **Authorization is an explicit parameter.** The owner id travels on the function signature,
  not in ambient request-scoped state. A background job has no request; a query that reads
  the owner from context returns everyone's data when called from one.
- **Fail loudly over degrading quietly.** A service that refuses to boot when misconfigured
  is a page. A service that quietly runs unauthenticated is a breach nobody notices.

## Data egress

Nothing leaves for a third party without the owner saying so, for that specific thing. This
covers the obvious cases and the non-obvious ones: telemetry in a dependency, an error
reporter that captures request bodies, a model provider in a code path that handles user
records, a CDN that sees full URLs.

**Sending content to an external service publishes it.** It may be cached or indexed even if
deleted afterwards.

## Secrets

- Never in the repository, a log, an error message, or a client bundle.
- A build-time variable is **not** a secret. If it reaches the bundle, it is published — the
  prefix that makes it available to the client is the prefix that makes it public.
- `.env.example` carries names and comments. Never values, not even placeholder-looking ones.
- The right shape for handing a secret to a tool is a placeholder the runner substitutes and
  the report redacts:

  ```yaml
  type: { into: password, text: "{{secret:APP_PASSWORD}}" }
  ```

  The file is committable, the run works, and the transcript carries nothing.
- A secret that has sat in a plaintext-equivalent file is **already exposed**. Rotate it;
  removing the file is not the fix.

## Checklist — exposing an endpoint

- [ ] Is it authenticated? If public, is that written down and justified?
- [ ] Is authorization checked at this layer, for this caller, for this resource?
- [ ] Is every input validated by the shared schema before it reaches logic?
- [ ] Can any input reach a query, a shell, a path or a template unescaped?
- [ ] Is it rate-limited, or is there a reason it does not need to be?
- [ ] Does the error path leak anything — a stack trace, an internal id, a username?
- [ ] Is it in the end-to-end tests, including its refusal cases?

## Checklist — adding a dependency

- [ ] Who maintains it, and when did it last release?
- [ ] What does it pull in transitively? Look, do not assume.
- [ ] Does it run a postinstall script? Should it be allowed to?
- [ ] Does it phone home? Check, do not trust the README.
- [ ] Is there a standard-library or already-present answer that is 80% as good?
- [ ] Does it reach production, or is it dev-only? Those are different risks.

## Checklist — handling a secret

- [ ] Is it in the validated config schema, with its name in the example file?
- [ ] Is it absent from every log line, including error paths and request dumps?
- [ ] Is it absent from the client bundle? Verify by grepping the built output.
- [ ] Which services genuinely need it? Every other service should refuse to accept it.
- [ ] Is there a rotation path, and has it been exercised?

## A note on public repositories

A configuration repository is a disclosure surface. The things that leak from one are rarely
credentials — they are **topology**: hostnames, repository names, deploy mechanisms,
credential *names*, server aliases, employer names, absolute home paths carrying a username.

None of those are secrets. Together they are a map. Keep them out, and run a scanner in a
pre-commit hook rather than relying on remembering — see `scripts/scan-secrets.sh`.
