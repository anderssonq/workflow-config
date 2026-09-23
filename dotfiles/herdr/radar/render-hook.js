'use strict';

// herdr-radar render hook: prefix every agent row with `N ~`, where N is the
// row's position in the Agents panel — the index prefix+alt+N (focus_agent)
// jumps to. Workspace names get `[N]`, the prefix+shift+N index; Radar shows
// that name both in the Spaces list and as the Agents panel's group header.
//
// The panel order is Radar's own view (lib/view.js SORTS), so it is reproduced
// here from the same tokens Radar writes: grouped = ws_key, tab_key, sort_key
// (all desc); recent = sort_key desc; off = Herdr's order (workspace, then pane).
// Nothing is renamed: the prefixes exist only in what Radar publishes.

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const TTL_MS = 1500;
const MODE_FLAG = path.join(os.homedir(), '.local/state/herdr/plugins/hhdebb.herdr-radar/agent-view.on');
let cache = { at: 0, byPane: new Map(), bySpace: new Map() };

function herdr(...args) {
  const r = spawnSync(process.env.HERDR_BIN_PATH ?? 'herdr', args, {
    encoding: 'utf8',
    timeout: 2000,
    windowsHide: true,
  });
  return r.status === 0 ? JSON.parse(r.stdout).result : null;
}

// Same reading as Radar's view.mode(): a missing flag means the default, grouped.
function mode() {
  try {
    const value = fs.readFileSync(MODE_FLAG, 'utf8').trim();
    return value === 'off' || value === 'recent' ? value : 'grouped';
  } catch {
    return 'grouped';
  }
}

const desc = (a, b) => (a < b ? 1 : a > b ? -1 : 0);

function order(agents, spaces) {
  const tok = (a, k) => a.tokens?.[k] ?? '';
  const m = mode();
  if (m === 'recent') return agents.sort((a, b) => desc(tok(a, 'sort_key'), tok(b, 'sort_key')));
  if (m === 'grouped') {
    return agents.sort(
      (a, b) =>
        desc(tok(a, 'ws_key'), tok(b, 'ws_key')) ||
        desc(tok(a, 'tab_key'), tok(b, 'tab_key')) ||
        desc(tok(a, 'sort_key'), tok(b, 'sort_key')),
    );
  }
  const num = new Map(spaces.map((w) => [w.workspace_id, w.number]));
  return agents.sort((a, b) => (num.get(a.workspace_id) ?? 99) - (num.get(b.workspace_id) ?? 99));
}

function index() {
  const now = Date.now();
  if (now - cache.at < TTL_MS) return cache;
  const agents = herdr('agent', 'list')?.agents;
  const spaces = herdr('workspace', 'list')?.workspaces;
  if (!agents || !spaces) return cache;
  const byPane = new Map();
  order(agents, spaces).forEach((a, i) => byPane.set(a.pane_id, i + 1));
  const bySpace = new Map(spaces.map((w) => [w.workspace_id, w.number]));
  cache = { at: now, byPane, bySpace };
  return cache;
}

function title(text, paneId) {
  const n = index().byPane.get(paneId);
  return n ? `${n} ~ ${text}` : text;
}

// The workspace number prefix+shift+N reaches, in brackets so it does not read
// as an agent number where it doubles as the Agents panel's group header.
function workspace(label, workspaceId) {
  const n = index().bySpace?.get(workspaceId);
  return n ? `[${n}] ${label}` : label;
}

module.exports = { title, workspace };
