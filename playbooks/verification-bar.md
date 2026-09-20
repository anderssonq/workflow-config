# The verification bar

What counts as knowing something works.

## Measure instead of eyeballing

An impression is not evidence. A number with the command that produced it beside it is.

```
"the bundle got smaller"                    → not evidence
"main chunk 412 KB → 287 KB (pnpm build)"   → evidence
```

This applies to performance, to contrast ratios, to memory limits, to "it feels faster".
Every one of those has a command.

## Never report something as working without running it

- Not "the image should build" — build it, and paste the last lines.
- Not "this endpoint returns 200" — curl it, and paste the code.
- Not "the tests pass" — run them, in this invocation, and paste the counts.

The failure mode this prevents is specific: a change that is obviously correct, is not, and
is reported as verified. The cost lands on whoever trusts the report.

## Prove the root cause before fixing it

A fix applied to a guess produces two problems: the original one, still present, and a
change nobody can justify or safely revert.

When the cause is not obvious, go layer by layer and **prove each layer before moving on** —
is the process running, is it the one you think, is it listening where you think, does the
dependency answer, does the application's own view agree. Only then, the code.

## Never retune a fixture to make a test pass

Either the code is wrong or the assertion is wrong. Adjusting the input until they agree is
neither, and it removes the only signal that something was wrong.

The corollary: **revert the change and watch the test fail, once.** A test that passes either
way covers nothing, and nobody will ever find that out on purpose.

## Seed and migration proofs are not re-runs

Running a seed twice proves nothing if it upserts. The proof is:

```
seed  →  delete a row  →  seed
```

If the row comes back, the seed is not idempotent, it is *convergent* — and in production
that means it restores data a human deliberately removed. The same shape applies to any
"safe to re-run" claim: find the state the re-run is supposed to preserve, break it, re-run.

## Absences are proved, not assumed

When a component is designed **not** to have something — no database access, no credential,
no network call — that absence needs a test. Absences decay silently: someone adds an import
for a good reason and nothing fails.

```
a test that greps the built output for the forbidden dependency
a service that refuses to start if the credential it should not hold is present
```

Fail loudly over degrading quietly. A service that refuses to boot when misconfigured is a
page; a service that quietly runs unauthenticated is a breach.

## Say when you did not verify

"I did not run this" is a complete, acceptable sentence. "Skipped the e2e suite, it needs a
database" is useful. Silence about what was not checked is the only unacceptable option,
because it reads identically to having checked.
