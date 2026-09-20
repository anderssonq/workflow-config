---
name: nestjs-prisma
description: NestJS module layout, one validation source, one error shape, and the Prisma schema-change workflow including destructive migrations and index policy. Load before touching API or schema code.
---

# NestJS + Prisma conventions

**Audience:** writing or reviewing a backend feature or a schema change.

## When NOT to use this skill

- Frontend of any kind → [`nextjs-app-router`](../nextjs-app-router/SKILL.md) and `ui/`.
- Workspace layout, shared packages, dependency boundaries →
  [`pnpm-monorepo`](../pnpm-monorepo/SKILL.md).
- Containers and deployment → [`container-deploy`](../container-deploy/SKILL.md).

## Module layout

```
src/<feature>/
  <feature>.module.ts
  <feature>.controller.ts     thin: parse, delegate, return
  <feature>.service.ts        the logic
  dto/                        request and response schemas
  <feature>.service.spec.ts   beside the code it tests
test/                         end-to-end, one file per surface
```

**Controllers stay thin.** A controller that branches on business rules is a service that
happens to have decorators, and it is untestable without HTTP.

## One validation source

Schemas live in the shared package and become DTOs through a single adapter
(`createZodDto` or equivalent). The API does not restate a shape the client already has.

Two rules that cost real debugging time:

- **A create schema and a response schema are different schemas, and aligning them is a bug.**
  Creation takes what the caller may supply; the response returns what the system produced.
  Merging them leaks generated fields into the input surface and makes required fields
  optional.
- **`.partial()` does not strip `.default()`.** A partial update schema built from a create
  schema will happily fill in defaults for fields the caller never sent, overwriting stored
  values with the schema's opinion.

## One error shape

Every failure leaves through one global filter with one body:

```json
{ "statusCode": 400, "message": "…", "error": "Bad Request", "timestamp": "…", "path": "/…" }
```

Carve-outs exist only where an external specification demands a different shape (an OAuth
endpoint owes RFC 6749's `{error, error_description}`). When you have one, **assert it in a
test in both directions** — the carve-out returns the foreign shape, and everything else does
not. Otherwise the exception spreads.

## Default deny

Every route requires a token unless it is explicitly marked public. The inverse — public by
default with guards added per route — ships an unauthenticated endpoint the first time
someone forgets, and nothing fails loudly.

Never log a token, a hash, or the header that carried either.

## Ownership is an explicit parameter

Every query that touches user-owned data takes the owner id as an argument. Not from a
request-scoped provider, not from async-local storage, not from an ambient context — an
argument, on the function signature, where it is visible at the call site and impossible to
forget in a background job.

## Schema changes

```
1. Edit the schema.
2. Mirror any enum into the shared package — same commit, no exceptions.
3. Migrate.
4. Regenerate the client.
5. Build.
6. Prove the seed still works.
```

**Destructive changes are hand-written SQL, not generated.** Dropping a column, changing a
unique key, or adding a required column to a populated table: write the `migration.sql`
yourself, including the data step. The generator's answer to "this would lose data" is to
reset the database, which is correct locally and catastrophic anywhere else.

**Proving the seed** means seed → delete a row → seed. A plain re-run passes with an
upsert-based seed that also silently restores rows a human deleted.

## Index policy

Every index carries a justification comment naming the query it serves. An index with no
named query is a write cost with no reader, and nobody will ever dare delete it because
nobody knows what it was for.

## Provenance and maintenance

Extracted 2026-09-20 from a NestJS 11 + Prisma 7 codebase in production. The `.partial()` and
create-versus-response rules are bugs that shipped; the seed proof is an incident in which an
"idempotent" seed restored an account that had been deliberately deleted.
