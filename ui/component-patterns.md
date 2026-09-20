# Component patterns

Named patterns, each paid for by something that shipped wrong. They are here so the next
implementation starts from the corrected version.

## The destructive confirm

The form **raises intent** and never runs the mutation:

```tsx
<EntityForm onRequestDelete={(entity) => setPendingDelete(entity)} />
```

The **host** owns the dialog and the mutation. The copy lives in a pure planner in `lib/`:

```ts
planDeletion(entity) → { title, body, confirmLabel, pendingLabel, destructive }
```

so it can be tested without rendering anything, and so the wording of a destructive action is
reviewable as text rather than buried in JSX.

**Reserve the danger style for irreversible outcomes.** If archiving and deleting look alike,
the alarm stops meaning anything, and the one that matters gets clicked as fast as the one
that does not.

## No `<form>` inside a `<form>`

A `<dialog>` does not lift this rule — the DOM does not care where the nesting came from.
A hosted form renders `role="form"` on a `div` and uses `type="button"` on every control.

The symptom when you get it wrong is not an error. It is the outer form submitting when the
inner one does, intermittently, on Enter.

## A form dialog resets in its own `close()`

One `seed()` function feeds both the initial state and the reset:

```ts
const seed = () => ({ name: entity?.name ?? '', amount: entity?.amount ?? 0 })
const [values, setValues] = useState(seed)
const close = () => { setValues(seed()); onClose() }
```

A `key` on the host remounts on *reopen*, which never covers Cancel — the user cancels, opens
again, and their abandoned edits are still there.

A new form dialog adds **a row to a shared test table**, not a new test file. The table is
what makes the twelfth dialog cost the same as the second.

## A refusal names its field

One hook owns the id base, so the input, its error and its `aria-describedby` agree by
construction rather than by convention:

```ts
const { id, describedBy, fail } = useFormError<'email' | 'amount'>()
```

**Append the error id to `aria-describedby`; never substitute it.** Substituting drops the
hint text that was already there, and the field loses its description at the exact moment the
user most needs it.

Focus moves to the first failing field on submit. A refusal the user has to hunt for is a
refusal that reads as a broken button.

## Selection ARIA is decided by the row, not the list

- A homogeneous group of options → `role="radio"` with roving `tabIndex`.
- A row that carries a **second control** (a menu, a delete button) cannot be a radio —
  it takes `aria-current="true"`.

Write it as `current ? 'true' : undefined`, never `"false"`. `aria-current="false"` is a
string that some screen readers announce.

## The pointer-only affordance is never the only route

Swipe to delete, pull to refresh, a pencil that appears on hover, infinite scroll on an
intersection observer — every one of these sits **on top of a real, focusable button**.

Each is an enhancement. None is an interface. A keyboard user, a screen-reader user, and
anyone on a device where the gesture does not fire must be able to reach the action.

## Dates render in the user's timezone, not the browser's

Every date helper takes an explicit `timeZone`. The browser's zone is a fact about the
machine, not about the user — and it changes when they travel, silently reassigning
transactions to different days.

The corollary: period boundaries are computed in the user's timezone **at query time**, not
stored.

## Navigation is a link

A navigation control is an `<a>`, never a `<button>` that calls a router push. Cmd-click,
middle-click and "open in new tab" must work, and nothing in the framework gives you those
back once you have chosen a button.

Programmatic navigation is for navigation that **follows an action** — a redirect after a
successful save. That is a different thing, and it is fine.

## Undo a transform through the animation library, not the DOM

If a library wrote `style.transform`, clearing it by hand leaves the library's internal state
believing the value is still there; the next animation starts from a position that does not
exist. Animate back to the neutral value instead.

Relatedly: **two things must never write the same property.** A tilt wrapper around a card
that already animates its own transform produces whichever one wrote last, which varies by
frame.
