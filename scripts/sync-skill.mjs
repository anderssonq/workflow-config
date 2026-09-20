/* global console, process, fetch */
// Fetch vendored skills from the sources recorded in skills-lock.json.
//
//   node scripts/sync-skill.mjs                      fetch all, verify
//   node scripts/sync-skill.mjs web-design-guidelines
//   node scripts/sync-skill.mjs --check              verify without writing
//   node scripts/sync-skill.mjs --relock             re-pin to current HEAD and rehash
//
// Fetches the WHOLE skill directory, not just SKILL.md. That distinction is the
// entire point for these sources: vercel-react-best-practices' SKILL.md is a
// 149-line index, and its actual content is 72 files under rules/. A sync that
// stops at SKILL.md leaves an index pointing at nothing.
//
// Bodies are gitignored. They are someone else's work under their own licence,
// and a committed copy drifts from upstream with nothing to signal that it has.

import { createHash } from 'node:crypto'
import { mkdirSync, writeFileSync, readFileSync, rmSync, chmodSync } from 'node:fs'
import { dirname, join } from 'node:path'

const ROOT = new URL('..', import.meta.url).pathname.replace(/\/$/, '')
const LOCK = join(ROOT, 'claude/skills/vendored/skills-lock.json')
const OUT = join(ROOT, 'claude/skills/vendored')

const args = process.argv.slice(2)
const CHECK = args.includes('--check')
const RELOCK = args.includes('--relock')
const WANT = args.find((a) => !a.startsWith('--'))

const sha256 = (buf) => createHash('sha256').update(buf).digest('hex')

// Unauthenticated GitHub API is 60 requests/hour. GITHUB_TOKEN raises it, and
// is read from the environment only — never from the lockfile.
const headers = { 'user-agent': 'workflow-config-sync' }
if (process.env.GITHUB_TOKEN) headers.authorization = `Bearer ${process.env.GITHUB_TOKEN}`

async function json(url) {
  const res = await fetch(url, { headers })
  if (!res.ok) throw new Error(`${res.status} ${res.statusText} — ${url}`)
  return res.json()
}
async function raw(url) {
  const res = await fetch(url, { headers })
  if (!res.ok) throw new Error(`${res.status} ${res.statusText} — ${url}`)
  return Buffer.from(await res.arrayBuffer())
}

const lock = JSON.parse(readFileSync(LOCK, 'utf8'))
let failed = 0
let changed = false

for (const [name, entry] of Object.entries(lock.skills)) {
  if (WANT && WANT !== name) continue

  const { source, skillPath } = entry
  const dir = dirname(skillPath) // the skill's directory upstream
  let ref = entry.ref

  try {
    if (RELOCK || !ref) {
      const [head] = await json(`https://api.github.com/repos/${source}/commits?per_page=1`)
      ref = head.sha
    }

    // List the whole tree once, then take everything under the skill's directory.
    const tree = await json(`https://api.github.com/repos/${source}/git/trees/${ref}?recursive=1`)
    const files = tree.tree
      .filter((n) => n.type === 'blob' && (n.path === skillPath || n.path.startsWith(`${dir}/`)))
      .sort((a, b) => a.path.localeCompare(b.path))

    if (!files.length) throw new Error(`no files under ${dir} at ${ref.slice(0, 12)}`)

    // A manifest hash over every path and blob sha covers the whole skill, not
    // just its entry file. Reproducible from the same API response.
    const treeHash = sha256(files.map((f) => `${f.sha} ${f.path}`).join('\n'))

    const bodies = new Map()
    const modes = new Map()
    for (const f of files) {
      bodies.set(f.path, await raw(`https://raw.githubusercontent.com/${source}/${ref}/${f.path}`))
      modes.set(f.path, f.mode)
    }
    const entryHash = sha256(bodies.get(skillPath))

    // Apache-2.0 section 4(d) requires the NOTICE to travel with the work.
    // `legalFiles` names anything at the repository root that must come along.
    const legal = new Map()
    for (const file of entry.legalFiles ?? []) {
      legal.set(file, await raw(`https://raw.githubusercontent.com/${source}/${ref}/${file}`))
    }

    const drift = []
    if (!RELOCK && entry.computedHash && entry.computedHash !== entryHash) drift.push('SKILL.md')
    if (!RELOCK && entry.treeHash && entry.treeHash !== treeHash) drift.push('tree')

    if (drift.length) {
      console.error(`  DRIFT        ${name.padEnd(30)} ${drift.join(' + ')} changed at the pinned ref`)
      console.error(`               locked ${entry.computedHash?.slice(0, 16)} / ${entry.treeHash?.slice(0, 16)}`)
      console.error(`               got    ${entryHash.slice(0, 16)} / ${treeHash.slice(0, 16)}`)
      failed++
      continue
    }

    if (RELOCK) {
      if (entry.ref !== ref || entry.computedHash !== entryHash || entry.treeHash !== treeHash) changed = true
      entry.ref = ref
      entry.computedHash = entryHash
      entry.treeHash = treeHash
      entry.files = files.length
    }

    if (CHECK) {
      console.log(`  ok           ${name.padEnd(30)} ${ref.slice(0, 12)}  ${files.length} file(s)`)
      continue
    }

    // Replace wholesale: a partial old tree beside a new one is worse than either.
    const dest = join(OUT, name)
    rmSync(dest, { recursive: true, force: true })
    for (const [path, body] of bodies) {
      const local = join(dest, path.slice(dir.length + 1) || 'SKILL.md')
      mkdirSync(dirname(local), { recursive: true })
      writeFileSync(local, body)
      // A launcher that arrives without its executable bit fails in a way that
      // looks like a missing file.
      if (modes.get(path) === '100755') chmodSync(local, 0o755)
    }
    for (const [file, body] of legal) writeFileSync(join(dest, file.replace(/\//g, '_')), body)
    // Attribution travels with the copy, because the copy is not ours.
    writeFileSync(
      join(dest, 'UPSTREAM.md'),
      `# ${name}\n\n` +
        `Vendored from https://github.com/${source}\n\n` +
        `| | |\n| --- | --- |\n` +
        `| Ref | \`${ref}\` |\n| Path | \`${dir}\` |\n| Files | ${files.length} |\n` +
        `| Licence | ${entry.license ?? 'UNKNOWN — do not redistribute'} |\n` +
        (legal.size ? `| Legal files | ${[...legal.keys()].join(', ')} (copied beside this file) |\n` : '') +
        (entry.caution ? `\n> **Caution:** ${entry.caution}\n` : '') +
        `\nFetched by \`scripts/sync-skill.mjs\`. Do not edit — edits are lost on the next sync.\n` +
        `These skills are **advisory, not law**; see ../README.md.\n`,
    )
    console.log(
      `  fetched      ${name.padEnd(30)} ${ref.slice(0, 12)}  ${files.length} file(s)` +
        (entry.caution ? '  ⚠ see UPSTREAM.md' : ''),
    )
  } catch (err) {
    console.error(`  FAILED       ${name.padEnd(30)} ${err.message}`)
    failed++
  }
}

if (RELOCK && changed) {
  writeFileSync(LOCK, `${JSON.stringify(lock, null, 2)}\n`)
  console.log('\nskills-lock.json updated. Review the diff before committing.')
}

if (failed) {
  console.error(`\n${failed} skill(s) did not verify. Nothing partial was left behind.\n`)
  process.exit(1)
}
console.log(CHECK ? '\nAll locked skills verify.' : '\nFetched into claude/skills/vendored/ (bodies are gitignored).')
