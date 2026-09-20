---
name: nextjs-app-router
description: App Router conventions that hold up in production — private colocation, the server/client page pair, metadata as code, i18n routing, and the image-cache trap. Load before touching an App Router tree.
---

# Next.js App Router conventions

**Audience:** writing or reviewing routes in a Next.js App Router project.

**A warning worth keeping at the top:** recent Next majors changed APIs, conventions and file
structure. Before writing code against a version you have not used this week, read the
version's own docs in `node_modules/next/dist/docs/` — they are shipped with the package and
they are current, which your recollection is not.

## When NOT to use this skill

- Component tiers, tokens and styling → `ui/atomic-design.md` and `ui/design-tokens.md`.
- Backend service layout → [`nestjs-prisma`](../nestjs-prisma/SKILL.md).
- Workspace layout and dependency boundaries →
  [`pnpm-monorepo`](../pnpm-monorepo/SKILL.md).
- Re-render cost, bundle size, composition APIs, View Transitions → the vendored Vercel
  skills. They are **advisory, not law**, and whole rule families do not apply to a
  client-only app. Fetch and route them through
  [`../../vendored/README.md`](../../vendored/README.md), which carries the override table.

## Private colocation

Folders prefixed with `_` are excluded from routing, which makes them the right home for
everything a route needs and nothing else does:

```
app/
  _components/    ui/ (atoms), providers/, and one folder per section
  _data/          typed static data modules
  _hooks/         DOM-facing hooks: observers, input events — no rules
  _utils/         pure helpers
```

Route-level private folders work too (`app/templates/_components/`) and are better than
hoisting a component that only one route uses.

## The server/client pair

Every content route is two files:

```
page.tsx          server component — exports `metadata`, does no interactivity
XxxClient.tsx     client component — "use client", holds the interactivity
```

`"use client"` goes on the smallest component that needs it, never on the page. A page that
is a client component cannot export `metadata`, and the fix people reach for — moving
metadata to a layout — makes every sibling route share it.

## Metadata is code, and it does not go through i18n

- `app/robots.ts`, `app/sitemap.ts`, `app/manifest.ts` are metadata *files*, typed and
  generated. File conventions (`favicon.ico`, `icon.svg`, `apple-icon.png`) sit beside them.
- **Never import a translation dictionary or a locale hook into metadata code.** Metadata is
  rendered outside the request's language context; the value you read there is the default,
  and the bug is silent.
- **A new route means a manual entry in `sitemap.ts`** unless it is generated from a data
  file. Dynamic routes are automatic; static ones are not, and nobody notices for weeks.
- Canonical URLs come from one committed constant, never from
  `process.env.X ?? 'fallback'` re-derived inline. See the env-var doctrine in
  `claude/skills/project/config-and-env/SKILL.md`.

## Two ways to do locales, and when each is right

| Approach | Use when |
| --- | --- |
| A `[locale]` segment | Three or more locales, or locales added over time |
| **Twin routes** (`/es/page.tsx` importing the English page and wrapping it in a provider) | Exactly two, where the second is a translation of the first and not a separate site |

The twin approach keeps one component tree and one set of tests, at the cost of a hardcoded
metadata block per twin (with `title.absolute`, to escape the root template). It is two
routes, not a third locale — say so in the project's docs so nobody "completes" it.

## The image cache trap

Next's image optimizer keys on the source URL. Re-baking an asset **in place** produces a
byte-identical URL, so warm browser caches keep serving the old bytes for the full
`minimumCacheTTL` — a month, at common settings, with no way to bust it.

Fix: **import the image** so the bundler fingerprints the filename.

```tsx
import portrait from '@/public/images/portrait.jpg'   // fingerprinted
<Image src={portrait} … />                             // not "/images/portrait.jpg"
```

## Dev-time cross-origin

Recent versions reject cross-origin `/_next/*` dev requests with a 403 rather than warning,
which breaks testing on a real device over the LAN or a tunnel. Allow the origins explicitly:

```ts
allowedDevOrigins: ['192.168.*.*', '10.*.*.*', '*.trycloudflare.com'],
```

A tunnel is often required regardless, because sensor APIs (`deviceorientation`, camera,
geolocation) need a secure context.

## Provenance and maintenance

Extracted 2026-09-20 from a production Next 16 App Router codebase. The image-cache and
cross-origin entries are incidents, not documentation: the first served a stale portrait for
a month, the second broke device testing outright.
