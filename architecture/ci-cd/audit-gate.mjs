/* global console, process */
// Dependency advisory gate.
//
// The bar is not "clean". It is "clean, or EXACTLY the advisories named in the
// allowlist below" — and it fails in BOTH directions:
//
//   * a new advisory fails, and
//   * an allowlisted advisory that is no longer reported ALSO fails.
//
// The second is the point. A stale exception is how an allowlist rots into a
// blindfold: the entry outlives the problem, nobody notices, and the next real
// advisory in that module is silently permitted.
//
// Usage:
//   node audit-gate.mjs                 run `pnpm audit --json` and gate on it
//   node audit-gate.mjs saved.json      gate on a saved report (re-check a CI run)
//
// Globals are declared above rather than widening the shared lint config for a
// path that ships nothing.

import { execFileSync } from 'node:child_process'
import { readFileSync } from 'node:fs'

// Every entry needs an identifier, a module, and a reason a human wrote.
// Adding a SECOND entry needs an ADR: the first exception is a judgement call,
// the second is a policy.
const ALLOWED = [
  // {
  //   id: 'GHSA-xxxx-xxxx-xxxx',
  //   module: 'some-package',
  //   reason: 'dev-only, reachable solely from the test runner; upstream fix is in 5.x, which requires Node 24',
  // },
]

function report() {
  const file = process.argv[2]
  if (file) return JSON.parse(readFileSync(file, 'utf8'))
  try {
    // pnpm audit exits non-zero when it finds anything; that is not an error here.
    return JSON.parse(execFileSync('pnpm', ['audit', '--json'], { encoding: 'utf8' }))
  } catch (err) {
    if (err.stdout) return JSON.parse(err.stdout)
    throw err
  }
}

const data = report()
const found = Object.values(data.advisories ?? {}).map((a) => ({
  id: a.github_advisory_id ?? String(a.id),
  module: a.module_name,
  severity: a.severity,
  title: a.title,
}))

const allowedIds = new Set(ALLOWED.map((a) => a.id))
const foundIds = new Set(found.map((a) => a.id))

const unexpected = found.filter((a) => !allowedIds.has(a.id))
const stale = ALLOWED.filter((a) => !foundIds.has(a.id))

if (unexpected.length) {
  console.error(`\n${unexpected.length} advisory(ies) not in the allowlist:\n`)
  for (const a of unexpected) {
    console.error(`  ${a.severity.padEnd(8)} ${a.id}  ${a.module}`)
    console.error(`           ${a.title}`)
  }
  console.error('\nFix it, or add it to ALLOWED with a reason a human wrote.\n')
}

if (stale.length) {
  console.error(`\n${stale.length} allowlist entry(ies) no longer reported:\n`)
  for (const a of stale) console.error(`  ${a.id}  ${a.module}  — ${a.reason}`)
  console.error('\nRemove them. A stale exception is how an allowlist becomes a blindfold.\n')
}

if (unexpected.length || stale.length) process.exit(1)

console.log(
  `audit-gate: clean (${found.length} advisory(ies), all ${ALLOWED.length} allowlisted and still present).`,
)
