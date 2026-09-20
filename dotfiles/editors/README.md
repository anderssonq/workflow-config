# Editors

| Copy | To |
| --- | --- |
| `vscode/settings.json` | `~/Library/Application Support/Code/User/settings.json` |
| `cursor/settings.json` | `~/Library/Application Support/Cursor/User/settings.json` |
| `zed/settings.json` | `~/.config/zed/settings.json` |

```bash
xargs -n1 code --install-extension < dotfiles/editors/extensions.txt
```

## The same four preferences, everywhere

Across all three — and Neovim — the settings are the same four:

- **vim mode**, with the **system clipboard** wired in
- **relative line numbers**
- **sidebar or panel on the right**
- no blinking cursor, no scrollbar, no scroll past the last line

They are here mostly so that a new machine gets them without a week of noticing what is
missing one setting at a time.

## ⚠️ Read before copying your own VS Code settings into a repository like this

The published file above is **not** a copy of the live one. Two keys were removed:

- an extension's API token, stored base64-encoded in plain settings, and
- the organisation name that went with it.

Neither belongs in a public repository, and the token had to be rotated regardless — a
credential that has sat in a settings file is already exposed, and deleting the file is not
the fix.

Editor settings files are a genuinely under-watched credential store. Extensions write tokens
into them silently, there is no prompt, and nothing ever tells you. Before publishing one:

```bash
grep -inE 'token|apikey|api_key|secret|password|organization' settings.json
```
