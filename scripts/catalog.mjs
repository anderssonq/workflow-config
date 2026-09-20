/* global console, process */
// Generates and verifies catalog.json — the machine-readable index of the bank.
//
//   node scripts/catalog.mjs --write    regenerate catalog.json and INDEX.md
//   node scripts/catalog.mjs            verify both match, and lint the skills
//
// The catalog is generated rather than hand-maintained because a hand-maintained
// index of 40 entries is an index that is wrong within a month, and a wrong index
// is worse than none: an agent trusts it.

import { readFileSync, writeFileSync, readdirSync, existsSync, statSync } from 'node:fs'
import { execSync } from 'node:child_process'
import { join, relative } from 'node:path'

const ROOT = new URL('..', import.meta.url).pathname.replace(/\/$/, '')
const CATALOG = join(ROOT, 'catalog.json')
const INDEX = join(ROOT, 'INDEX.md')

const BUDGETS = { skillLines: 350, descriptionWords: 35 }

const dirs = (p) =>
  existsSync(p) ? readdirSync(p).filter((d) => statSync(join(p, d)).isDirectory()) : []
const files = (p, ext) =>
  existsSync(p) ? readdirSync(p).filter((f) => f.endsWith(ext)) : []

function frontmatter(file) {
  const text = readFileSync(file, 'utf8')
  const m = text.match(/^---\n([\s\S]*?)\n---/)
  if (!m) return { _lines: text.split('\n').length }
  const out = { _lines: text.split('\n').length, _body: text.slice(m[0].length) }
  // Minimal parse: `key: value`, with YAML folded blocks joined.
  let key = null
  for (const line of m[1].split('\n')) {
    const kv = line.match(/^([a-zA-Z-]+):\s*(.*)$/)
    if (kv) {
      key = kv[1]
      out[key] = kv[2] === '>' || kv[2] === '|' ? '' : kv[2]
    } else if (key && line.trim()) {
      out[key] = `${out[key]} ${line.trim()}`.trim()
    }
  }
  return out
}

const entries = []
const problems = []

// ── house rule: English everywhere ───────────────────────────────────────
// The repository is public and its readers are not all Spanish speakers, so
// the rule is enforced rather than remembered. It was broken once — in the
// README, and in comments inside two dotfiles copied verbatim from a machine —
// and caught by hand, which is what this exists to stop.
//
// High-precision markers only: each is a space-delimited Spanish function word
// that does not occur in English prose or in the code samples here.
// "todo" is excluded deliberately: it collides with TODO in English comments.
// "del" is excluded: it is a Python keyword and this repo ships Python.
const SPANISH = /(^| )(que|para|una|los|las|por|con|está|también|donde|cuando|porque|desde|sobre|entre|cada|nada|más|sólo|aquí|esto|esta|este)( |,|\.|:|;|$)/i

function checkLanguage(relPath, text) {
  const hits = text
    .split('\n')
    .map((line, i) => [i + 1, line])
    .filter(([, line]) => SPANISH.test(line) && !/allow-spanish/.test(line))
  if (hits.length) {
    const [lineno, line] = hits[0]
    problems.push(
      `${relPath}:${lineno}: looks like Spanish (${hits.length} line(s)) — this repository is English only` +
        `\n      ${line.trim().slice(0, 90)}`,
    )
  }
}

// ── skills ───────────────────────────────────────────────────────────────
// vendored/ is skipped on both counts: the bodies are gitignored, so including
// them would make the catalog depend on whether you have synced; and they are
// third-party work, which this standard has no business linting.
for (const shelf of dirs(join(ROOT, 'claude/skills')).filter((s) => s !== 'vendored')) {
  for (const name of dirs(join(ROOT, 'claude/skills', shelf))) {
    const path = join(ROOT, 'claude/skills', shelf, name, 'SKILL.md')
    if (!existsSync(path)) continue
    const fm = frontmatter(path)
    const rel = relative(ROOT, path)

    if (fm.name !== name) {
      problems.push(`${rel}: frontmatter name "${fm.name}" != directory "${name}" (it will never load)`)
    }
    const words = (fm.description ?? '').split(/\s+/).filter(Boolean).length
    if (words > BUDGETS.descriptionWords) {
      problems.push(`${rel}: description is ${words} words (budget ${BUDGETS.descriptionWords})`)
    }
    if (fm._lines > BUDGETS.skillLines) {
      problems.push(`${rel}: ${fm._lines} lines (budget ${BUDGETS.skillLines}) — split it`)
    }
    if (shelf !== 'project' && !/When NOT to use this skill/.test(fm._body ?? '')) {
      problems.push(`${rel}: no "When NOT to use this skill" section`)
    }

    entries.push({
      id: name,
      kind: 'skill',
      shelf,
      path: rel,
      description: fm.description ?? '',
      lines: fm._lines,
      autoLoads: Boolean(fm.paths),
    })
  }
}

// ── agents ───────────────────────────────────────────────────────────────
for (const family of dirs(join(ROOT, 'claude/agents'))) {
  for (const f of files(join(ROOT, 'claude/agents', family), '.md')) {
    const path = join(ROOT, 'claude/agents', family, f)
    const fm = frontmatter(path)
    const rel = relative(ROOT, path)
    if (fm.name && fm.name !== f.replace(/\.md$/, '')) {
      problems.push(`${rel}: frontmatter name "${fm.name}" != file name`)
    }
    if (!/MUST NOT/.test(fm._body ?? '')) {
      problems.push(`${rel}: no MUST NOT section — an agent with no boundary will use every capability it has`)
    }
    entries.push({
      id: f.replace(/\.md$/, ''),
      kind: 'agent',
      shelf: family,
      path: rel,
      description: fm.description ?? '',
      lines: fm._lines,
    })
  }
}

// ── commands ─────────────────────────────────────────────────────────────
for (const f of files(join(ROOT, 'claude/commands'), '.md')) {
  if (f === 'README.md') continue
  const path = join(ROOT, 'claude/commands', f)
  const fm = frontmatter(path)
  entries.push({
    id: `/${f.replace(/\.md$/, '')}`,
    kind: 'command',
    shelf: 'commands',
    path: relative(ROOT, path),
    description: fm.description ?? '',
    lines: fm._lines,
  })
}

// ── prose: playbooks, architecture, ui ───────────────────────────────────
for (const area of ['playbooks', 'ui']) {
  for (const f of files(join(ROOT, area), '.md')) {
    if (f === 'README.md') continue
    const path = join(ROOT, area, f)
    const text = readFileSync(path, 'utf8')
    entries.push({
      id: f.replace(/\.md$/, ''),
      kind: 'guide',
      shelf: area,
      path: relative(ROOT, path),
      description: (text.split('\n').find((l) => l && !l.startsWith('#')) ?? '').trim(),
      lines: text.split('\n').length,
    })
  }
}
for (const d of dirs(join(ROOT, 'architecture'))) {
  const path = join(ROOT, 'architecture', d, 'README.md')
  if (!existsSync(path)) continue
  const text = readFileSync(path, 'utf8')
  entries.push({
    id: d,
    kind: 'guide',
    shelf: 'architecture',
    path: relative(ROOT, path),
    description: (text.split('\n').find((l) => l && !l.startsWith('#')) ?? '').trim(),
    lines: text.split('\n').length,
  })
}

// ── dotfiles ─────────────────────────────────────────────────────────────
for (const d of dirs(join(ROOT, 'dotfiles'))) {
  const path = join(ROOT, 'dotfiles', d, 'README.md')
  if (!existsSync(path)) continue
  const text = readFileSync(path, 'utf8')
  entries.push({
    id: d,
    kind: 'dotfiles',
    shelf: 'dotfiles',
    path: relative(ROOT, path),
    description: (text.split('\n').find((l) => l && !l.startsWith('#')) ?? '').trim(),
    lines: text.split('\n').length,
  })
}

// Sweep every tracked text file, not only the ones the catalog indexes: the
// last two offenders were a README and two shell dotfiles.
try {
  const tracked = execSync('git ls-files', { cwd: ROOT, encoding: 'utf8' }).split('\n').filter(Boolean)
  for (const rel of tracked) {
    if (/\.(png|jpg|jpeg|webp|gif|ico|pdf|zip|woff2?|ttf|json)$/.test(rel)) continue
    if (rel === 'scripts/catalog.mjs' || rel === '.scan-denylist.example') continue
    checkLanguage(rel, readFileSync(join(ROOT, rel), 'utf8'))
  }
} catch {
  // Not a git checkout, or git is unavailable. Not a reason to fail the catalog.
}

entries.sort((a, b) => `${a.kind}/${a.shelf}/${a.id}`.localeCompare(`${b.kind}/${b.shelf}/${b.id}`))

const catalog = {
  $comment:
    'Generated by scripts/catalog.mjs. Do not edit by hand — run `node scripts/catalog.mjs --write`.',
  generated: new Date().toISOString().slice(0, 10),
  counts: entries.reduce((acc, e) => ({ ...acc, [e.kind]: (acc[e.kind] ?? 0) + 1 }), {}),
  entries,
}

const json = `${JSON.stringify(catalog, null, 2)}\n`

// INDEX.md is generated from the same pass, so the human index and the machine
// index can never disagree — which is the only way either stays true.
const GROUPS = [
  ['skill', 'meta', 'Meta skills — how this system writes itself'],
  ['skill', 'project', 'Project skill library — installed per repository'],
  ['skill', 'core', 'Core skills — travel to any repository'],
  ['skill', 'stack', 'Stack skills — true only for a given stack'],
  ['agent', 'zone', 'Zone agents — ownership by surface'],
  ['agent', 'role', 'Role agents — ownership by task'],
  ['command', 'commands', 'Slash commands'],
  ['guide', 'playbooks', 'Playbooks — the practices, in prose'],
  ['guide', 'architecture', 'Architecture — guides with copyable files'],
  ['guide', 'ui', 'UI'],
  ['dotfiles', 'dotfiles', 'Dotfiles — the machine layer'],
]

function renderIndex() {
  const out = [
    '# Index',
    '',
    '<!-- Generated by scripts/catalog.mjs. Do not edit by hand. -->',
    '',
    `Every artifact in the bank, one line each. ${entries.length} entries, generated ${catalog.generated}.`,
    '',
    'Machine-readable equivalent: [`catalog.json`](catalog.json).',
    '',
  ]
  for (const [kind, shelf, title] of GROUPS) {
    const rows = entries.filter((e) => e.kind === kind && e.shelf === shelf)
    if (!rows.length) continue
    out.push(`## ${title}`, '')
    for (const e of rows) {
      const desc = e.description.replace(/\s+/g, ' ').trim()
      const short = desc.length > 150 ? `${desc.slice(0, 147)}…` : desc
      out.push(`- [\`${e.id}\`](${e.path}) — ${short}`)
    }
    out.push('')
  }
  return out.join('\n')
}

const index = renderIndex()

if (process.argv.includes('--write')) {
  writeFileSync(CATALOG, json)
  writeFileSync(INDEX, index)
  console.log(`catalog: wrote ${entries.length} entries to catalog.json and INDEX.md`)
} else {
  if (existsSync(CATALOG)) {
    const current = JSON.parse(readFileSync(CATALOG, 'utf8'))
    if (JSON.stringify(current.entries) !== JSON.stringify(entries)) {
      problems.push('catalog.json is out of date — run `node scripts/catalog.mjs --write`')
    }
  } else {
    problems.push('catalog.json is missing — run `node scripts/catalog.mjs --write`')
  }
  if (!existsSync(INDEX)) {
    problems.push('INDEX.md is missing — run `node scripts/catalog.mjs --write`')
  } else if (readFileSync(INDEX, 'utf8') !== index) {
    problems.push('INDEX.md is out of date — run `node scripts/catalog.mjs --write`')
  }
}

if (problems.length) {
  console.error(`\ncatalog: ${problems.length} problem(s)\n`)
  for (const p of problems) console.error(`  ${p}`)
  console.error('')
  process.exit(1)
}

console.log(`catalog: clean (${entries.length} entries, ${Object.entries(catalog.counts).map(([k, v]) => `${v} ${k}`).join(', ')})`)
