# Design tokens

Three layers, one capping rule, and the discipline that keeps a scale from becoming a
suggestion.

## The three layers

```css
/* 1. PRIMITIVES — an un-themed :root. No component ever reads these. */
:root {
  --n-0:  #08090e;  --n-1:  #0b0c12;  --n-2:  #12141c;
  --n-8:  #c8ccd6;  --n-9:  #e4e7ee;  --n-10: #f4f5f7;
  --steel-700: #3d5680;  --steel-300: #8fa3c4;
}

/* 2. SEMANTIC, DARK — the source of truth. */
:root,
:root[data-theme='dark'] {
  --bg-base:      var(--n-1);
  --bg-raised:    var(--n-2);
  --text-primary: var(--n-10);
  --text-muted:   var(--n-8);
  --accent:       var(--n-10);
  --secondary:    var(--steel-300);
}

/* 3. SEMANTIC, LIGHT — the same names, re-pointed. Never new names. */
:root[data-theme='light'] {
  --bg-base:      var(--n-10);
  --bg-raised:    #ffffff;
  --text-primary: #14161a;
  --text-muted:   #4a4f5a;
  --accent:       #14161a;
  --secondary:    var(--steel-700);
}
```

## The capping rule

> **A component reads a semantic name. Never a primitive, never a literal.**

Everything else follows. A component that reads `--n-8` breaks in light mode and nothing will
tell you; a component that reads `--text-muted` is correct in both by construction.

Light mode re-points the *same names*. The moment light mode introduces a name dark mode does
not have, you have two design systems and a component that has to know which one it is in.

## Scales are steps, not suggestions

Every `font-size` reads a `--text-*` token. Every structural `padding`, `margin` and `gap`
reads a `--space-*` one.

> **New components pick a step. They do not pick a number.**

**Measured exceptions keep their literal — and their comment.** A value that came from
measurement is not a step, and dressing it as one hides that it was measured:

```css
/* 34px: the header's optical centre with this cap height. Measured, not chosen. */
padding-top: 34px;
```

`var(--space-6)` there would make a measurement look like a choice from a menu, and the next
person would "improve" it to `--space-7`.

## Contrast floor

One token is the floor for anything a visitor reads — typically `--text-muted`. A separate,
dimmer token exists for disabled labels **only**, and using it for readable text is how a
palette silently ships at 2.7:1.

Name the floor in the design document, and check it with a script rather than by eye:
contrast is not something anyone judges reliably, least of all on their own design.

## Ration the expensive things

- **One gradient** in the whole product. Usually the primary button face.
- **One focus ring**: one width, one offset, one colour, everywhere.
- **One accent hue**, spent as *light* rather than as ground. A coloured background reads as
  a different site; a coloured light reads as weather.
- **Glass only over content that is actually visible behind it.** A frosted panel over a flat
  background is an expensive way to draw a rectangle.
- **Grain, shadows, blurs: cap the count.** Two sections, not seven. These are the effects
  whose cost is invisible until a mid-range phone renders them.

## Theming mechanics

- The attribute goes on `:root`, and a **pre-hydration inline script** sets it from storage
  before first paint. Without it, every reload flashes the default theme.
- `<meta name="theme-color">` tracks `--bg-base` and is updated after hydration.
- Respect `prefers-color-scheme` on first visit, then honour the explicit choice.

## Governance

A new token needs a reason the existing ones do not cover, written down. Tokens are cheap to
add and impossible to remove: once a component reads one, it is permanent. A palette with
forty semantic colours is a palette nobody can hold in their head, which is the same as not
having one.
