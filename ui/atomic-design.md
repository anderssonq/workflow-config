# Atomic design, as actually practised

Five tiers, one boundary rule that settles every argument, and a rule about where logic lives
that matters more than the tiers do.

```
src/components/
  atoms/        16-ish   a control, a label, a chip — no domain knowledge
  molecules/    40-ish   a composition of atoms, driven entirely by props
  organisms/    55-ish   reads its own data, owns a piece of the screen
  layout/        3-ish   boundaries and guards: error boundary, auth guard
  providers/     6-ish   context: theme, session, toasts, active selection
```

## The boundary rule

> **A component that reads its own data and takes no props is an organism, not a molecule.**

That is the whole test, and it resolves the argument that otherwise recurs in every review.
Not "how big is it", not "how many atoms does it use" — **does it fetch?** A 200-line form
driven entirely by props is a molecule. A 30-line component that calls a query hook is an
organism.

The reason the distinction is worth enforcing: molecules are trivially testable and reusable
because they are pure functions of their props. The moment one fetches, it is neither, and
pretending otherwise is how a "shared" component becomes untestable.

## No barrel files

Import directly:

```ts
import { Button } from '@/components/atoms/Button'      // yes
import { Button } from '@/components/atoms'             // no
```

A barrel makes every import of one component pull the module graph of all of them. Tree
shaking mitigates it in production and does nothing for dev-server cold start or for test
runs, which is where you actually feel it.

## Tests live beside the component

`Foo.tsx` and `Foo.test.tsx`, same directory. A test in a parallel `__tests__/` tree is a
test that gets left behind when the component moves.

## Providers mount where their lifetime ends

A provider that **calls a query**, or that **must die with the session**, mounts *inside* the
auth guard — not at the root. Mounted at the root it keeps a query alive after logout, and
the next user of that tab sees the previous one's cached data before the refetch lands.

Providers that are genuinely global — theme, locale — mount at the root.

## Rules live in `lib/`, components are wiring

This is the rule that matters more than the tier taxonomy.

> A rule living in a `.tsx` is a rule with no test, so moving it out is part of touching it.

- **`lib/`** — pure functions. Business rules, formatting, validation, planners. No React,
  no DOM.
- **`hooks/`** — the DOM half. Observers, input events, subscriptions. **No rules.**
- **Components** — wiring. They call a rule and render its result.

A gesture is therefore two files: a pure module that computes, and a hook that listens.
`sheetDismiss.ts` plus `useSheetDismiss`. The pure half is unit-tested without a DOM; the
hook is thin enough that its own bugs are visible.

## The variant for a single-page site

A marketing site or portfolio does not need five tiers, and forcing them produces a
`molecules/` directory with two things in it. The shape that works:

```
_components/
  ui/           atoms — Button, Chip, BrandMark, ThemeToggle
  Hero/         an organism as a PascalCase folder, with its own sub-parts
  About/        Hero/HeroPortrait.tsx, Hero/heroAnimation.ts
  Services/
  providers/
```

No molecules tier. Sections are folders named after the section, holding everything only that
section uses — components, styles, and non-visual modules as camelCase `.ts` files beside
them.

**Both shapes are correct for their situation.** What is not correct is having five tiers
where three have one file each, or having no tiers in an application with fifty screens.

## When one layer composes another

A public marketing page that **composes the product's real components** is a good pattern —
one design system, one set of tests, drift impossible. It comes with an obligation: a new
navigation slot or a changed component reaches that page whether or not anyone looked, so
**sweeping it is part of done**, not a separate task.
