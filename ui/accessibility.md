# Accessibility

WCAG 2.2 AA is **the floor, not the goal**. Everything below is either the floor or a
correction to something that met the floor and was still unusable.

## Contrast

- Body text ≥ 4.5:1. Large text (18.66px bold, or 24px) ≥ 3:1.
- **Non-text** contrast ≥ 3:1: control borders, focus rings, icons that carry meaning, chart
  series against their background.
- One token is the readable floor; the dimmer token is for **disabled labels only**.
- **Check with a script, not by eye.** Nobody judges their own design's contrast correctly,
  and text over a gradient, a photograph or an animated field has no single value to judge —
  sample the worst case.

## Colour is never the only channel

Status, selection and validity carry **shape or text alongside colour**. A red border and a
green border are the same border to a significant fraction of users, and the same screenshot
to anyone reviewing in greyscale.

This extends past the product: terminal output, dashboards and status indicators get a symbol
as well as a colour.

## Focus

- **Visible focus on everything focusable.** One ring: one width, one offset, one colour.
- Never remove an outline without replacing it. `outline: none` with no substitute is the
  single most common accessibility regression there is.
- Focus order follows reading order. If a CSS reorder made them disagree, the DOM is wrong.
- **Focus moves to the problem.** On a failed submit, focus goes to the first failing field —
  not to the top of the form, and certainly nowhere.
- A skip link, and it is genuinely reachable. `:focus` rather than `:focus-visible` is the
  correct choice here: a keyboard user tabbing into the page must see it immediately.

## Targets and motion

- Interactive targets ≥ 24×24 CSS pixels, with ≥ 44×44 the real-world floor on touch.
- `prefers-reduced-motion` is honoured by **every** animation. The global guard usually only
  shortens durations; scroll-driven and timeline animations each need their own
  `@media (prefers-reduced-motion: reduce) { animation: none }`.
- No parallax, no auto-playing carousel, nothing that moves for longer than five seconds
  without a control to stop it.

## Semantics

- A real `<button>` for actions, a real `<a href>` for navigation. Cmd-click must work.
- One `<h1>`; headings descend without skipping.
- Every form control has a label. A placeholder is not a label — it disappears exactly when
  the user needs it.
- `aria-*` only where a native element cannot express it. A `div` with six ARIA attributes is
  usually one element away from needing none.
- `aria-current="true"` or omitted. Never `"false"`.

## Language and copy

- `<html lang>` is correct, and it changes when the content's language changes.
- **Translate `aria-label`s.** They are content, and they are the strings most often left in
  the source language.
- Names — brands, product names, people — are not translated. Mark them `translate="no"`.
- **One label per intent.** Every control leading to the same place reads the same. Three
  wordings for one destination reads as three destinations.

## The QA matrix

Behaviour that varies along more than one axis is tested along all of them:

```
theme (dark · light) × locale × reduced-motion (on · off) × viewport (mobile · desktop)
```

Sixteen combinations. Most are quick. The bugs live in the corners — light mode in the second
locale at mobile width is where the untested overflow is.

## What the floor does not cover

Meeting AA and still being unusable is common. Watch for:

- A control that is technically reachable but takes eleven tabs to get to.
- An error message that is announced but does not say which field.
- A live region that announces on every keystroke.
- A modal that traps focus correctly and has no visible way out.
- An action whose only affordance is a gesture — see
  [`component-patterns`](component-patterns.md).
