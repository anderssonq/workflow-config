---
name: knowledge-graph
description: Maps an entire project — code, docs, PDFs, images, configs — into a queryable knowledge graph you can interrogate instead of grepping files. Use when the user says "build a knowledge graph", "map this project", "graph this codebase", "show me how X connects to Y", "what are the most connected concepts", "explain this module's relationships", "trace the path from A to B", or asks architecture/dependency questions better answered from a graph than from raw files. Produces graph.json + GRAPH_REPORT.md + graph.html under graphify-out/. Pure Claude-native — no external package or install required.
---

# Knowledge Graph Builder

Turns any folder into a knowledge graph using **only native tools** (Glob, Grep, Read, Write/Bash) — no external CLI, no PyPI package, no API keys. Code structure is extracted by reading files and parsing symbols/imports/references; docs and images are understood semantically by you, the model. Output mirrors the familiar `graphify-out/` layout so it's easy to consume and commit.

## What you produce

```
graphify-out/
├── graph.json        the full graph — nodes, edges, communities, metadata
├── GRAPH_REPORT.md   the highlights: god nodes, surprising connections, the "why", suggested questions
└── graph.html        self-contained interactive viz (open in any browser — click, filter, search)
```

## Operating modes

- **Agent environment (bash + file tools)** — run the full workflow autonomously. This is the primary mode.
- **Chat (no tools)** — degrade: explain the steps, ask the user to paste directory listings / file contents, and emit `graph.json` + report as code blocks.

---

## Configuration

Resolve before running. Precedence: explicit user instruction > defaults.

| Setting | Default | Override |
|---|---|---|
| `target_dir` | `.` (repo root) | user message, e.g. "graph ./src" |
| `output_dir` | `graphify-out/` | user message |
| `mode` | `normal` | `--deep` for more aggressive relationship inference |
| `directed` | `false` | `--directed` to preserve edge direction |
| `viz` | `true` | `--no-viz` to skip `graph.html` |

**Ignore rules.** Read `.graphifyignore` if present, else fall back to `.gitignore`. Same syntax as gitignore, including `!` negation. **Always** skip: `.git/`, `node_modules/`, `dist/`, `build/`, `.venv/`, `venv/`, `target/`, `__pycache__/`, lockfiles, minified assets, and binaries you can't read. Never read files > ~1 MB of code wholesale — sample them.

---

## Step 0 — Inventory

1. `git rev-parse --show-toplevel` (or use `target_dir`) to anchor the root.
2. Enumerate candidate files with Glob, then filter through the ignore rules.
3. Bucket files by type:
   - **Code** (`.py .ts .js .jsx .tsx .mjs .go .rs .java .c .cpp .h .rb .cs .kt .swift .php .lua .sql .vue .svelte .sh .scala .dart` …) — parsed **locally** by reading + symbol extraction.
   - **Docs** (`.md .mdx .rst .txt .html .yaml .yml`) — semantic extraction by you.
   - **Configs** (`package.json`, `pyproject.toml`, `*.mcp.json`, CI yaml) — extract declared deps, scripts, services.
   - **Binary/media** (`.pdf .png .jpg .mp4` …) — read with the Read tool where supported (PDF/images); otherwise record as a leaf node by filename only.
4. Print a one-line plan: file counts per bucket, what you'll skip, estimated graph size. For very large repos (>300 files), tell the user and offer to scope to a subdir.

---

## Step 1 — Extract nodes & edges

Work file-by-file. Build an in-memory list of **nodes** and **edges**, deduping by stable `id`.

### Node types
`file`, `module`/`package`, `class`, `function`/`method`, `interface`/`type`, `variable`/`constant`, `endpoint`/`route`, `table`/`schema`, `service` (from MCP/CI configs), `concept` (a doc heading or domain term), `doc`, `note` (a rationale extracted from a comment/docstring), `external` (third-party dep).

### Node id convention
`<relpath>::<symbol>` for code symbols (e.g. `src/auth/login.ts::login`), `<relpath>` for files/docs, `concept:<slug>` for concepts, `ext:<name>` for externals. Keep ids stable across runs so `--update` can diff.

### Edge types
`imports`, `calls`, `inherits`/`implements`, `references`, `defines`, `exposes` (route→handler), `reads`/`writes` (code→table), `depends_on` (→external), `documents` (doc→code), `explains` (note→code), `related_to` (semantic, doc/concept links).

### Code extraction (local, no LLM-of-files needed — you read them)
For each code file:
- Record a `file` node and a `module` node.
- Parse top-level + nested **definitions** (classes, functions, methods, exported consts) → nodes with `file` + `line`.
- Parse **imports/requires** → `imports` edges (to local files or `external` nodes).
- Detect **call sites** and **references** to known symbols → `calls`/`references` edges. Be conservative: only link when the target resolves to a node you extracted.
- Capture **inheritance/implements** relationships.

### The "why" extraction (high value — don't skip)
Scan comments and docstrings for rationale markers: `NOTE:`, `WHY:`, `HACK:`, `TODO:`, `FIXME:`, `WARNING:`, plus module/class/function docstrings that explain *intent*. Emit each as a `note` node linked with an `explains` edge to the code it annotates. This is what makes the graph more than a call map.

### Docs / configs / media (semantic — you interpret)
- Docs: headings → `concept` nodes; cross-references and described components → `related_to`/`documents` edges to code nodes when names match.
- Configs: declared dependencies → `external` nodes + `depends_on`; scripts/services/MCP servers → `service` nodes with env-var requirements.
- PDFs/images: read them; emit a `doc` node + `concept` nodes for the key ideas, linked `related_to`.

### Confidence tags (required on every edge)
- `EXTRACTED` — directly observed in source (an explicit import, a literal call, a declared dependency).
- `INFERRED` — deduced with high confidence but not literal (a call through an alias, a doc clearly describing a module).
- `AMBIGUOUS` — a plausible link you're guessing at (name collision, fuzzy semantic match).

Never silently upgrade `AMBIGUOUS` to `EXTRACTED`. The honesty of these tags is the point.

`--deep` mode: spend more effort on cross-module `references`, semantic `related_to`, and `INFERRED` links. Normal mode: favor `EXTRACTED` edges and obvious structure.

---

## Step 2 — Clustering & god nodes

1. **Degree** — compute degree (in+out) for every node; store as `degree`.
2. **God nodes** — the top ~10 highest-degree nodes. Everything flows through these. Offer `--exclude-hubs <pctl>` to drop utility super-hubs (e.g. a logger imported everywhere) from the ranking so they don't drown out meaningful hubs.
3. **Communities** — partition the graph into clusters by connectivity (group nodes that link to each other far more than to the rest; a greedy modularity grouping is fine — you're approximating Leiden/Louvain by reasoning, not running a library). Higher `--resolution` ⇒ more, smaller communities.
4. **Name each community** yourself from its members (e.g. "Authentication", "Data layer", "CLI commands") and write a 1–2 sentence summary. Store `community` on each node and a `communities` array on the graph.
5. **Surprising connections** — find edges that bridge *different* communities or distant files/modules. Rank by how unexpected they are (cross-community + low-degree endpoints = more surprising). Keep the top ~8 for the report.

---

## Step 3 — Write graph.json

```json
{
  "meta": {
    "generated_at": "<ISO timestamp>",
    "root": "<target_dir>",
    "mode": "normal|deep",
    "directed": false,
    "node_count": 0,
    "edge_count": 0,
    "generator": "knowledge-graph skill (Claude-native)"
  },
  "nodes": [
    { "id": "src/auth/login.ts::login", "label": "login", "type": "function",
      "file": "src/auth/login.ts", "line": 12, "community": "Authentication",
      "degree": 7, "summary": "Validates credentials and issues a session token." }
  ],
  "edges": [
    { "source": "src/auth/login.ts::login", "target": "src/db/pool.ts::query",
      "type": "calls", "confidence": "EXTRACTED" }
  ],
  "communities": [
    { "id": "c1", "name": "Authentication", "summary": "Login, sessions, token issuance.",
      "members": ["src/auth/login.ts::login", "..."] }
  ],
  "god_nodes": [ { "id": "...", "degree": 23 } ],
  "surprising_connections": [
    { "source": "...", "target": "...", "type": "references",
      "why": "Links the billing module to the auth layer, which otherwise never interact.",
      "confidence": "INFERRED" }
  ]
}
```

Write it with the Write tool (pretty-printed). Update `meta.node_count` / `edge_count`.

---

## Step 4 — Write GRAPH_REPORT.md

```markdown
# Knowledge Graph Report — <project name>

Generated <date> · <N> nodes · <M> edges · <K> communities

## God nodes
The most-connected concepts — everything flows through these.
1. **`<label>`** (`<file>`) — degree <n> — <one line on its role>
   ...

## Communities
- **<Name>** (<count> nodes) — <1–2 sentence summary>
  ...

## Surprising connections
Links that cross module/community boundaries — ranked by how unexpected.
1. `<A>` → `<B>` (<type>, <confidence>) — <why it's surprising>
   ...

## The "why"
Design rationale extracted from comments & docstrings.
- **<note>** — explains `<code>` (`<file>:<line>`)
  ...

## Suggested questions
Questions this graph is uniquely positioned to answer:
- <question 1>
- <question 2>
  ... (4–5 total)

## Confidence summary
EXTRACTED: <n> · INFERRED: <n> · AMBIGUOUS: <n>
```

Keep it skimmable. Lead each section with its single most useful item.

---

## Step 5 — Write graph.html (skip if `--no-viz`)

Emit a **self-contained** HTML file: the graph data is embedded inline as a `<script>` JSON blob, and rendering uses a single CDN force-graph library with a graceful fallback message if offline. Requirements:
- Force-directed layout; nodes colored by `community`; node size scaled by `degree`.
- Click a node → highlight neighbors + show its `summary`/`file:line`.
- A text search box and a community filter dropdown.
- Edge styling hints confidence (e.g. solid = EXTRACTED, dashed = INFERRED, dotted = AMBIGUOUS).

Use this skeleton (inline the JSON where marked):

```html
<!doctype html><html><head><meta charset="utf-8"><title>Knowledge Graph</title>
<style>body{margin:0;font:14px system-ui;background:#0b0e14;color:#cdd6f4}
#hud{position:fixed;top:8px;left:8px;z-index:10;background:#1e2230cc;padding:8px;border-radius:8px}
#hud input,#hud select{margin:2px;padding:4px}</style>
<script src="https://unpkg.com/force-graph"></script></head>
<body><div id="hud"><input id="q" placeholder="search…"><select id="c"></select>
<div id="info"></div></div><div id="g"></div>
<script>const DATA=/*__GRAPH_JSON__*/{};</script>
<script>
if(!window.ForceGraph){document.getElementById('info').textContent='Offline: force-graph CDN unavailable. graph.json still has the full data.';}
else{const g=DATA, pal={}, colors=['#89b4fa','#f38ba8','#a6e3a1','#f9e2af','#cba6f7','#fab387','#94e2d5','#eba0ac'];
(g.communities||[]).forEach((c,i)=>pal[c.name]=colors[i%colors.length]);
const sel=document.getElementById('c');sel.innerHTML='<option value="">all communities</option>'+(g.communities||[]).map(c=>`<option>${c.name}</option>`).join('');
const links=g.edges.map(e=>({source:e.source,target:e.target,conf:e.confidence}));
const G=ForceGraph()(document.getElementById('g')).graphData({nodes:g.nodes,links})
.nodeLabel(n=>`${n.label} — ${n.file||''}${n.line?':'+n.line:''}`).nodeAutoColorBy('community')
.nodeColor(n=>pal[n.community]||'#89b4fa').nodeVal(n=>1+(n.degree||0))
.linkColor(l=>l.conf==='EXTRACTED'?'#6c7086':l.conf==='INFERRED'?'#585b70':'#45475a')
.onNodeClick(n=>{document.getElementById('info').innerHTML=`<b>${n.label}</b><br>${n.summary||''}<br><small>${n.file||''}${n.line?':'+n.line:''}</small>`;});
document.getElementById('q').oninput=e=>{const t=e.target.value.toLowerCase();
G.nodeVisibility(n=>!t||n.label.toLowerCase().includes(t)||(n.file||'').toLowerCase().includes(t));};
sel.onchange=e=>{const c=e.target.value;G.nodeVisibility(n=>!c||n.community===c);};}
</script></body></html>
```

Replace `/*__GRAPH_JSON__*/{}` with the actual graph.json contents.

---

## Step 6 — Report to the user

```
Knowledge graph built → graphify-out/

  graph.json       <N> nodes · <M> edges · <K> communities
  GRAPH_REPORT.md  god nodes, surprising connections, the "why"
  graph.html       open in a browser to explore

Top god nodes: <a>, <b>, <c>
Try: ask me "what connects <X> to <Y>?" or "explain <Z>"
```

---

## Query operations (run against an existing graph.json)

When the user asks a question instead of a build, load `graphify-out/graph.json` and answer from it — don't re-grep the repo.

- **query "<question>"** — find the relevant nodes, walk their edges (BFS by default; `--dfs` for deep chains, `--budget N` to cap hops), and answer in prose, citing `node (file:line)` and the confidence of the edges you traversed.
- **path "<A>" "<B>"** — shortest path between two nodes; print each hop with its edge type + confidence. Say so plainly if no path exists.
- **explain "<node>"** — summarize a node: its community, neighbors grouped by edge type, the `note`/`why` nodes attached to it, and what would break if it changed.

If `graph.json` is missing or stale (repo changed a lot since `meta.generated_at`), say so and offer to rebuild.

---

## Incremental update (`--update`)

1. Load existing `graph.json`.
2. Determine changed files (`git diff --name-only`, or mtime vs `meta.generated_at`).
3. Re-extract only those files; remove their old nodes/edges by `id` prefix and re-add.
4. Recompute degree, communities, god nodes, surprising connections.
5. Rewrite all three outputs.

`--cluster-only` reruns Step 2 + outputs without re-extracting. If a rebuild ends up with **fewer** nodes than before (e.g. files deleted), keep the new graph but note the drop; only overwrite-with-fewer when the user passes `--force`.

---

## Behavioral rules

- **No external tools.** Never install or invoke `graphify`/`graphifyy` or any package — this skill replicates it natively. Use only Glob, Grep, Read, Write, and read-only Bash/git.
- **Never fabricate edges.** If you can't resolve a target node, don't invent it. Prefer omitting a link over guessing — or mark it `AMBIGUOUS`.
- **Confidence tags are mandatory and honest.**
- **Read-only on the repo.** Never modify source files; only write under `output_dir`.
- **Don't commit, push, or run network calls.** Output files only.
- **Stay within budget.** On huge repos, scope down and tell the user rather than reading everything.
- **Stable ids** so updates diff cleanly.
```
