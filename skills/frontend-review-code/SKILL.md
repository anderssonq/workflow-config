---
name: frontend-code-reviewer
description: Senior-level code review for frontend stacks — JavaScript, TypeScript, HTML, CSS, and SCSS only. Use this skill whenever the user asks for a code review, PR review, MR review, diff review, "review this", "look at my code", "is this any good", or pastes/uploads JS/TS/JSX/TSX/HTML/CSS/SCSS files and wants feedback. Also trigger for refactor suggestions, code-quality audits, accessibility checks, frontend performance audits, frontend security reviews, and "what would a senior engineer say about this" type questions on frontend code. Covers React, Vue, Angular, vanilla JS, Node.js (TS/JS), and modern CSS/SCSS. Does NOT cover backend code in Python/Go/Rust/Java, mobile-native (Swift/Kotlin), database design, infra/Terraform, or shell scripts.
---

# Frontend Code Reviewer

Opinionated, senior-level code review for **JavaScript, TypeScript, HTML, CSS, and SCSS only**. Apply the standards a senior/staff engineer would apply in a real PR review at a serious shop.

---

## Workflow

1. **Identify what's in the diff.** Languages, frameworks, file types. If it's not JS/TS/HTML/CSS/SCSS, say the skill doesn't cover it and stop.
2. **Read the code carefully.** Whole files, not just the hunk — context outside the diff is where most real bugs hide.
3. **Apply the relevant checklists below.** Don't recite every item; only call out what actually applies.
4. **Write the report in the format described next.**

## Output format

Unless the user asks for something different, deliver the review as Markdown with this structure:

```
## Summary
One paragraph: what the change does, overall verdict
(ship / ship with changes / needs rework), and the single
biggest thing to address.

## Blocking issues
Bugs, security holes, broken types, missing error handling on critical paths.
Each item: file:line, what's wrong, why it matters, suggested fix.

## Should fix
Quality issues that aren't blockers but should not land as-is.

## Nits
Style, naming, micro-optimizations. Clearly labeled as optional.

## Praise
What's genuinely good. Skip if there's nothing — don't manufacture it.
```

Rules for the report:

- **Cite `file:line`.** Vague feedback is useless feedback.
- **Show the fix when it's short.** Five lines of corrected code beats a paragraph.
- **Distinguish opinion from fact.** "Throws on null input" is a bug. "I'd name this `userId`" is a preference — label it as one.
- **No padding.** If there are no blocking issues, say so. Don't invent problems to look thorough.
- **Match the user's tone.** Quick snippet → short review. Full PR → full report.

---

## JavaScript & TypeScript

### Type safety (TS)

- **No `any`** unless explicitly justified in a comment. `unknown` + a type guard is almost always better.
- **No `as` casts that bypass safety.** `as unknown as T` is a code smell — investigate.
- **Discriminated unions over flag booleans.** `{ kind: 'loading' } | { kind: 'ok'; data } | { kind: 'error'; err }` beats `{ loading, data, error }`.
- **`readonly` for immutable data**, especially props and API response types.
- **No `Function` or `object` types.** Use a specific signature or `Record<string, unknown>`.
- **`strict: true` in `tsconfig.json`.** If it's off, flag it first.
- **Exhaustiveness checks on unions:** `const _exhaustive: never = value;` in the default branch of a switch.
- **Explicit return types on exported APIs.** Inferred is fine internally.

### Async & error handling

- **Every `await` is in a `try/catch`** OR the caller handles it OR it's deliberately fire-and-forget (marked `void`).
- **No floating promises.** `someAsync()` without `await` or `.catch()` is a bug. Use `@typescript-eslint/no-floating-promises`.
- **No `async` inside `forEach`.** It doesn't await. Use `for...of` with `await` or `Promise.all(arr.map(...))`.
- **`Promise.all` for parallel, sequential `await` for dependent.** Don't serialize independent async work.
- **`Promise.allSettled` when you want all results even on partial failure.**
- **AbortController for cancellable fetches**, especially in React effects.
- **Don't swallow errors.** `catch (e) {}` is almost never correct. At minimum, log with context.
- **`Error` instances only.** `throw 'broke'` loses the stack trace.

### Null safety

- **Optional chaining + nullish coalescing**: `user?.profile?.name ?? 'Anon'`.
- **Use `??`, not `||`, for defaults** when `0`, `''`, or `false` are valid values.
- **Narrow before use.** `if (!user) return; user.name` beats `user!.name`.
- **No non-null `!`** without a comment explaining why it's safe.

### React

- **Hooks rules**: top-level only — never inside conditions, loops, or after early returns.
- **Exhaustive dependency arrays.** Missing deps = stale closures = subtle bugs. Trust `react-hooks/exhaustive-deps`.
- **`useMemo` / `useCallback` are not free.** Use only when there's a measured render-perf problem or a referential-equality contract. Not by default.
- **Stable, unique keys.** Never array index when items can reorder/insert.
- **Don't mutate state.** `arr.push(x); setArr(arr)` won't re-render — use `setArr([...arr, x])`.
- **`useEffect` is for syncing with external systems**, not for derived state. Derived state belongs in render.
- **Avoid `useEffect` for fetching.** Prefer React Query / SWR / Suspense. Effect-based fetching has races, leaks, and stale-data issues.
- **`useState` lazy init for expensive defaults**: `useState(() => expensive())`.
- **Components stay small.** Over ~200 lines, look for split points (custom hooks for logic, subcomponents for layout).
- **Context for cross-cutting state only.** Overuse kills performance and modularity.
- **Server vs client components** (Next.js App Router): `"use client"` only when needed.

### Vue

- **`ref` for primitives, `reactive` only for objects you want to mutate.** Mixing causes confusion.
- **`computed` for derived state.** Never recompute in template.
- **`watch` vs `watchEffect`**: explicit deps with `watch`; `watchEffect` can over-trigger.
- **Composition API + `<script setup>`** for new code (Vue 3).
- **Don't mutate props.** Emit an event.

### Modules & imports

- **No circular imports.** Cause undefined exports and load-order bugs.
- **Named exports over default.** Default exports break refactors, autocomplete, re-exports. Default is fine where the framework requires it (React pages/routes).
- **Path aliases (`@/foo`) over deep relatives.**
- **Side-effect-free modules.** Top-level code runs on import — keep it to declarations.

### Naming

- **Booleans start with `is/has/should/can`**: `isLoading`, `hasPermission`.
- **Async functions are verbs**: `fetchUser`, not `userFetch`.
- **No abbreviations** except universal ones (`id`, `url`, `http`). `usr`, `btn`, `cfg` are noise.
- **Files match their default export**: `UserCard.tsx` exports `UserCard`.

### Bugs to scan for

- `==` instead of `===` (except `== null`, which catches both null and undefined and is fine).
- `for (let i in arr)` — `in` iterates keys including inherited; use `for...of` or `forEach`.
- `parseInt(x)` without radix.
- Date math without timezone awareness (`new Date('2024-01-01')` is UTC, not local).
- `JSON.parse` without try/catch on untrusted input.
- Mutating function arguments.
- `setInterval` / `setTimeout` / event listeners without cleanup in components.
- `localStorage` reads without try/catch (throws in private mode, quota exceeded, SSR).

### Testing

- **One concept per test**, not one assertion per test.
- **Test behavior, not implementation.** Don't assert on internal state when an output check would do.
- **Arrange / Act / Assert structure**, blank lines between.
- **No shared mutable state between tests.**
- **Mock boundaries** (HTTP, DB, time), not your own modules.

### Tooling red flags

- `// @ts-ignore` without a `// @ts-expect-error` + comment.
- `eslint-disable` without justification.
- Build artifacts or `.env` with real secrets in git (the latter is a security incident, not a nit).
- Lockfile missing from VCS.
- Wildcard semver ranges (`^` is fine, `*` is not).

---

## HTML & Accessibility

### Semantic HTML

- **Right element for the job.** `<button>` for actions, `<a href>` for navigation. Never `<div onClick>`.
- **One `<h1>` per page.** Headings in order, no skipping levels for styling.
- **Landmarks**: `<header>`, `<nav>`, `<main>`, `<footer>`, `<aside>`. One `<main>` per page.
- **`<section>` requires a heading.** Otherwise use `<div>`.
- **Lists for groups of related items.** `<ul>` / `<ol>` / `<li>`.
- **`<table>` only for tabular data**, with `<thead>`, `<tbody>`, `<th scope>`, `<caption>`.

### Forms

- **Every input has a `<label>`** with `for` matching `id`, or wraps it.
- **`placeholder` is not a label.** It disappears on input and fails contrast.
- **Correct `type`**: `email`, `tel`, `number`, `url`, `date`. Mobile keyboards depend on it.
- **`autocomplete` attributes** on personal-info fields. Big UX win, small effort.
- **`required`, `minlength`, `maxlength`, `pattern`** on the element — not only in JS.
- **Errors tied to input via `aria-describedby`**, with `aria-invalid="true"` on the field.
- **`<form>` element wraps the inputs.** Without it, Enter-to-submit and browser autofill break.

### ARIA

- **First rule: don't use ARIA.** Use the native element if one exists.
- **No redundant roles** (`<button role="button">`).
- **`aria-label` on icon-only buttons.**
- **`aria-hidden="true"` on decorative icons** inside buttons that already have accessible text.
- **Custom widgets need full keyboard support** (Tab, Arrow keys, Enter, Space, Escape per WAI-ARIA Authoring Practices) plus `role` plus state attributes (`aria-expanded`, `aria-selected`, `aria-checked`). If you can't commit to all of it, use a native element or a tested library.

### Images & media

- **`alt` on every `<img>`.** Empty `alt=""` for decorative (still required).
- **Don't put information only in images.** Charts need text alternatives.
- **Captions for video**, transcripts for audio.
- **`loading="lazy"`, `decoding="async"`** below-the-fold.
- **`width` and `height` attributes** to prevent layout shift.

### Keyboard & focus

- **Logical tab order**, following visual order. Don't use `tabindex > 0`.
- **Visible focus indicator on everything focusable.** Don't `outline: none` without a replacement.
- **Skip-to-content link** at top of page.
- **Focus returns somewhere sensible** after modal close, route change, async action.
- **Focus trap in modals**, Escape closes them.

### Color & contrast

- **4.5:1 for normal text, 3:1 for large text** (WCAG AA).
- **3:1 for UI components and graphics** (borders, icons, focus rings).
- **Don't use color alone to convey meaning.** Error states need an icon or label too.

### Document

- **`<html lang>` set correctly.**
- **Unique, descriptive `<title>` per page.**
- **`<meta name="viewport" content="width=device-width, initial-scale=1">`** on every page.
- **`<meta charset="UTF-8">`** as first thing in `<head>`.

### HTML/JSX bugs to scan for

- `onclick="..."` inline handlers in HTML.
- Inline styles in HTML.
- `<button>` inside `<a>` or vice versa (invalid).
- `<a href="javascript:void(0)">` or `<a href="#">` for non-navigation — use `<button>`.
- `<input>` without a `name` (won't submit with the form).
- Duplicate `id`s on a page. Always invalid, often breaks `<label for>`.

---

## CSS & SCSS

### Architecture

- **Pick one model and stick to it**: BEM, CSS Modules, utility-first (Tailwind), CSS-in-JS. Mixing models in the same project leaks specificity bugs.
- **Components own their styles.** No file reaches into another component's classes.
- **Global CSS is rare**: resets, design tokens, typography base, utility primitives. Everything else is scoped.
- **Design tokens as CSS custom properties** at `:root`, not hard-coded values everywhere.

### Selectors & specificity

- **Keep specificity low and flat.** A single class is the sweet spot.
- **No IDs in selectors** for styling.
- **No `!important`** except as documented escape hatches. Every `!important` needs a comment.
- **Avoid deep nesting in SCSS.** Max 2–3 levels. Deep nesting compiles to high-specificity selectors that fight each other.
- **`&__element` BEM-style nesting is fine.** Distinguish `&-foo` (name concat) from `&--foo` (BEM modifier).

### Modern layout

- **Flexbox for 1D, Grid for 2D.**
- **Don't `float`** for layout in 2026.
- **`gap` over margins** for spacing between flex/grid items.
- **`min-width: 0` on flex items containing text** to fix long-content overflow.
- **`aspect-ratio`** to lock dimensions instead of padding hacks.
- **Container queries (`@container`)** when the layout depends on the parent, not the viewport.

### Units

- **`rem` for font-size and most spacing.** Respects user font-size preference.
- **`em` only when something should scale with its own font-size** (e.g. padding inside a button).
- **`px` for borders, hairlines, small UI details.**
- **`clamp(min, pref, max)`, `ch`, `min-content`, `max-content`** are great — use them.
- **`100vh` on mobile is broken.** Use `dvh` / `svh` / `lvh` for viewport-relative heights.

### Responsive

- **Mobile-first**: base styles for mobile, `@media (min-width: ...)` to enhance.
- **Breakpoints based on content, not devices.**
- **Use `min` / `max` / `clamp` to reduce breakpoint count.**

### Typography

- **Define a type scale.** Don't sprinkle `font-size: 14.5px`.
- **`line-height` is unitless** so it scales: `line-height: 1.5`, not `24px`.
- **`text-wrap: balance` for headings**, `pretty` for body.
- **`font-display: swap`** on `@font-face`.

### SCSS-specific

- **`@use` over `@import`** — `@import` is deprecated in Dart Sass.
- **Mixins for behavior, functions for values.**
- **No mixins for what custom properties can do.** `--space-md` beats `@include space(md)`.
- **Never `@extend` across files** — produces unpredictable output. Inside a single file is acceptable; mixins are safer.
- **Avoid `lighten` / `darken`** — they don't work in perceptual color spaces. Use `color.adjust` with OKLCH or explicit shades.

### Tailwind / utility-first

- **`@apply` only inside component CSS for repeated patterns.**
- **Group classes logically** in markup (layout → spacing → typography → colors).
- **Use `tailwind-merge`** when composing classes via props.
- **Don't reinvent design tokens** — extend `theme` in config.
- **Arbitrary values (`w-[357px]`) are a smell** if they repeat. Add a token.

### Performance

- **Animate only `transform` and `opacity`** for 60fps. Other properties trigger layout.
- **`will-change` sparingly**, removed after animation.
- **`content-visibility: auto`** on long off-screen sections.

### CSS bugs to scan for

- `box-sizing: border-box` not set globally.
- `position: relative` added without intent (changes stacking context).
- `z-index` arms race (`z-index: 9999`). Define a z-index scale.
- `overflow: hidden` cutting off focus rings or tooltips.
- Sticky positioning broken by an `overflow` ancestor.
- `transition: all` — name the properties.
- Removed `:focus` outline without `:focus-visible` replacement.
- Animations without `prefers-reduced-motion` opt-out.

---

## Frontend Security

### XSS

- **Never `innerHTML` with anything that touched user input.** Use `textContent` or `createElement`.
- **`dangerouslySetInnerHTML` (React), `v-html` (Vue), `[innerHTML]` (Angular)** — every use needs a comment. If input is user data, sanitize with DOMPurify or similar. From a CMS/Markdown — sanitize anyway.
- **`eval`, `new Function`, `setTimeout(string, ...)`** — banned. There's always a better way.
- **`document.write`** — banned.
- **URL schemes**: when building `<a href={url}>` from user input, validate the scheme. `javascript:`, `data:`, `vbscript:` are XSS.
- **JSX renders text safely by default.** Risk appears only when you bypass it (`dangerouslySetInnerHTML`, refs, raw HTML).

### Tokens & secrets

- **No secrets in client bundles.** Anything in `src/` ships to the browser.
- **Public env vars (`VITE_*`, `NEXT_PUBLIC_*`) are public.** Treat them like page source.
- **JWT in localStorage is a tradeoff.** XSS exfiltrates it; `httpOnly` cookies + CSRF protection is the safer default.
- **Never log tokens** (console, error reporters, analytics).
- **No tokens in URLs.** They leak via Referer, history, server logs.

### CSRF

- **`SameSite=Lax` (default) or `Strict` on auth cookies.**
- **CSRF tokens on state-changing endpoints** if cookies are the auth mechanism.
- **Don't accept auth from both cookies and `Authorization` header** for the same endpoint — pick one.

### CSP

- **A CSP header is part of every serious deploy.** Even basic (`default-src 'self'; script-src 'self'`) blocks most XSS.
- **No `'unsafe-inline'` or `'unsafe-eval'` for scripts.** Use nonces or hashes if you must.
- **`frame-ancestors 'none'`** if you don't want to be iframed (clickjacking).

### Input handling

- **Validate client-side for UX, server-side for security.** Client validation is bypassable.
- **Schema validation at trust boundaries** (Zod, Yup, Valibot, io-ts) — form submit, API response, URL params.
- **File uploads**: check MIME + extension + magic bytes, generate new filenames, store outside webroot.

### Network

- **HTTPS only in production.**
- **`fetch` doesn't throw on HTTP errors.** Check `response.ok` explicitly.
- **CORS**: don't `Access-Control-Allow-Origin: *` on credentialed endpoints.
- **Don't follow user-controlled redirects.**

### Third-party scripts

- **Every external `<script src>` is a trust delegation.** Audit them.
- **Subresource Integrity (SRI)** on external scripts.
- **`<iframe sandbox>`** for embedded third-party content. Whitelist only needed capabilities.

### Security bugs to scan for

- `target="_blank"` without `rel="noopener noreferrer"` (tabnabbing).
- `postMessage` listeners without origin checks.
- `Math.random()` for anything security-sensitive — use `crypto.getRandomValues` / `crypto.randomUUID()`.
- Source maps deployed to production (unminified source exposed).
- `.env` / `.env.local` committed to git.
- Debug routes/endpoints reachable in production.
- Hard-coded test users or API keys.

---

## Frontend Performance

### Bundle size

- **Every dep is a tax.** Check bundle cost before adding.
- **Tree-shake-friendly imports**: `import { debounce } from 'lodash-es'`, not `import _ from 'lodash'`.
- **Avoid `moment.js`.** Use `date-fns`, `dayjs`, or `Intl.DateTimeFormat` / `Temporal`.
- **Don't pull a full UI lib for one component.**
- **Code-split by route.** Heavy features (charts, rich editors, video players) → dynamic import on demand.
- **Watch out for accidental imports through barrel files** (`index.ts` re-exporting everything defeats tree-shaking).
- **Audit with `vite-bundle-visualizer`, `webpack-bundle-analyzer`, `source-map-explorer`.**

### Rendering (React)

- **Don't optimize until you measure.** React DevTools Profiler shows what's actually slow.
- **Virtualize lists > ~100 items** (`@tanstack/react-virtual`, `react-window`).
- **State colocation**: as close to the consumers as possible. Hoisting state to the top causes whole-tree re-renders.
- **Context is a broadcast**: every consumer re-renders when value changes. Split by update frequency or use a selector library.
- **Don't pass new object/array/function literals as props to memoized children** — breaks memo.
- **`startTransition`** for non-urgent updates. **`useDeferredValue`** for derived values that can lag.

### Rendering (general)

- **Batch DOM reads and writes.** Mixing causes layout thrashing.
- **`requestAnimationFrame` for animations**, not `setInterval`.
- **`IntersectionObserver` for "is this visible"** — don't poll scroll listeners.
- **`ResizeObserver` for size changes.**
- **Debounce inputs, throttle scrolls.** Cancel on unmount.
- **Passive event listeners** for scroll/touch: `{ passive: true }`.

### Images

- **`loading="lazy"`, `decoding="async"`** below-the-fold.
- **`width` + `height` attributes** to reserve space (prevents CLS).
- **Responsive**: `srcset` + `sizes`, or `<picture>`.
- **Modern formats**: AVIF > WebP > JPEG. Fallbacks via `<picture>`.
- **LCP image preloaded**: `<link rel="preload" as="image" fetchpriority="high">`.

### Fonts

- **`font-display: swap`** to show fallback immediately.
- **Self-host when possible.**
- **Subset fonts** to characters you actually use.
- **WOFF2 only.**
- **Preload critical fonts**: `<link rel="preload" as="font" crossorigin>`.

### Core Web Vitals

- **LCP < 2.5s**. Usually the hero image or above-the-fold text. Preload it.
- **CLS < 0.1**. Set image/video dimensions. Reserve ad/embed space. Don't insert content above existing content.
- **INP < 200ms**. Long tasks kill it — break them up with `scheduler.yield()` / `setTimeout(0)` / `requestIdleCallback`.

### React Native (TS/JS)

- **`FlatList` over `ScrollView.map`** for lists. Set `keyExtractor`, `getItemLayout` when items are fixed-height.
- **`InteractionManager.runAfterInteractions`** for expensive work after navigation.
- **Hermes engine on** (default for new RN).
- **Avoid inline functions in `renderItem`** — breaks `FlatList` optimizations.
- **`useNativeDriver: true`** for `Animated` whenever supported.

### Performance bugs to scan for

- Loading all data, then filtering on the client when the server could.
- N+1 fetch in a `.map`.
- Regex re-created inside a hot function.
- Memory leak: subscription/listener/interval added in mount, not removed in unmount.
- Storing huge derived state instead of computing it.
- Polyfilling features for browsers that already support them.

---

## Common Antipatterns (high-yield)

Skim every review. These are the bugs that show up over and over.

### `any` as a band-aid

```ts
// 🚩
const data: any = await fetchSomething();
data.user.name; // no protection

// ✅
const data: unknown = await fetchSomething();
const parsed = ResponseSchema.parse(data); // Zod, Yup, etc.
parsed.user.name;
```

### `useEffect` for derived state

```tsx
// 🚩 — extra render, can desync
const [count, setCount] = useState(0);
const [doubled, setDoubled] = useState(0);
useEffect(() => { setDoubled(count * 2); }, [count]);

// ✅
const [count, setCount] = useState(0);
const doubled = count * 2;
```

### Fire-and-forget async

```ts
// 🚩 — error vanishes, race conditions possible
function handleClick() {
  saveToServer(); // promise never awaited
}

// ✅
async function handleClick() {
  try { await saveToServer(); }
  catch (e) { showError(e); }
}
```

### Mutating state directly

```tsx
// 🚩 — won't re-render
items.push(newItem);
setItems(items);

// ✅
setItems([...items, newItem]);
```

### `||` vs `??` for defaults

```ts
// 🚩 — returns 10 when count is 0
const limit = config.count || 10;

// ✅
const limit = config.count ?? 10;
```

### Index as React key when items reorder

```tsx
// 🚩
{items.map((item, i) => <Row key={i} {...item} />)}

// ✅
{items.map(item => <Row key={item.id} {...item} />)}
```

### Swallowing errors

```ts
// 🚩
try { risky(); } catch (e) {}

// ✅ — at minimum, log with context
try { risky(); } catch (e) {
  logger.error('risky() failed', { error: e });
  throw e;
}
```

### `<div onClick>` instead of `<button>`

```html
<!-- 🚩 — not focusable, no Enter/Space -->
<div class="btn" onclick="...">Click</div>

<!-- ✅ -->
<button type="button" onclick="...">Click</button>
```

### Specificity wars

```scss
// 🚩 — escalating specificity to override
.card .button { background: blue; }
.page .card .button { background: red; }
.page .card .button.active { background: green !important; }

// ✅ — single class + modifier
.button { background: blue; }
.button--danger { background: red; }
.button--active { background: green; }
```

### Animating layout properties

```css
/* 🚩 — width triggers layout every frame */
.box { transition: width 0.3s; }
.box:hover { width: 200px; }

/* ✅ — transform on the compositor */
.box { transition: transform 0.3s; }
.box:hover { transform: scaleX(2); }
```

### Removing focus outline without replacement

```css
/* 🚩 — keyboard users can't see where they are */
button:focus { outline: none; }

/* ✅ */
button:focus-visible {
  outline: 2px solid var(--color-focus);
  outline-offset: 2px;
}
```

### `100vh` on mobile

```css
/* 🚩 — wrong height on iOS Safari */
.hero { height: 100vh; }

/* ✅ */
.hero { height: 100dvh; }
```

### Commented-out code

Just delete it. Git remembers.

### TODO without context

```ts
// 🚩
// TODO: fix this

// ✅
// TODO(ander, 2026-05): rate-limit retries — see APP-1234
```

### Premature abstraction

A `BaseFormFieldWrapperFactoryProvider<T>` written for one form, one field. Wait for the third use case before extracting.

---

## Out of scope

This skill does NOT cover:

- Backend code in Python, Go, Rust, Java, C#, PHP, etc.
- Mobile-native code (Swift, Kotlin, Objective-C). React Native in TS/JS is fine.
- Database schema design, SQL review, ORM modeling.
- Infrastructure: Terraform, Kubernetes manifests, Docker, CI/CD pipelines.
- Shell scripts.

If the user asks for something out of scope, say so directly and offer to help with what's in scope.
