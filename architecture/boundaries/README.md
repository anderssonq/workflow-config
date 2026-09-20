# Import boundaries

Three layers over one kernel, enforced by the linter, in both directions.

```
src/
  site/       the public surface — must render with the API unreachable
  auth/       the entry corridor
  app/        the authenticated product

  components/ ┐
  hooks/      ├ the kernel: shared by all three, aware of none
  lib/        ┘
```

## The rules

1. **No layer imports another layer.** `site` does not import `app`, and so on.
2. **The kernel imports no layer.** Not one, not "just this once".
3. **Tests are exempt.** A test may reach across to build a fixture.

## Both directions, for different reasons — and write them down

This is the part that decides whether the rule survives its first serious inconvenience. A
rule enforced "for symmetry" gets deleted by the first person it blocks.

**Kernel → layer** is forbidden because it drags the whole product into the public page's
bundle. One shared component reaching into `app/` for a type pulls in the screen it lives in,
and the screen's router, and everything the router touches. The public page ends up shipping
the authenticated product to people who are not logged in.

**Layer → layer** is forbidden because the layers have different failure contracts. `site`
must render when the API is down. A single import from `app` puts a query behind it, and the
public page starts failing for the reason the public page exists to survive.

Two different consequences, two different rules that happen to look alike.

## The generator

[`eslint.config.mjs`](eslint.config.mjs) generates both directions from one list of layer
names, so adding a layer is a one-word change rather than a matrix of blocks nobody maintains.

## When a layer genuinely needs something from another

It does not. One of three things is true, and the third is rare:

1. **The thing belongs in the kernel.** Move it. This is the answer most of the time.
2. **The dependency points the wrong way.** Invert it — the layer that owns the data exposes
   it, the other consumes through the kernel.
3. **The layers are wrong.** Then it is an architecture change with an ADR, not an exception
   comment.

An `eslint-disable` on one of these rules is a finding in review, not a workaround.
