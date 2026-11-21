# Rex customization plan

Rex (superlogical.com/rex) — terminal app + multiplexer. Version at time of
writing: `rex 0.1.0-preview.21`, API rev 18. Beta: names below may drift;
re-check with `rex -C <client> actions` before writing code.

Docs: https://www.superlogical.com/rex/docs (append `.md` to any page; index at
`/rex/docs/llms.txt`).

## How Rex config works

Two layers, configured differently:

| Layer | Holds | Lives in | Reproducible how |
|---|---|---|---|
| Server config | key bindings, key modes, custom actions, hosts, event hooks | `~/.config/rex/init.lua` (Lua 5.1, `require` siblings) | stow this folder |
| Mac app settings | font, theme, glass, padding, pane fade, toolbar, notifications | `defaults` domain `com.superlogical.rex` (mixed with app state) | `client.setting.*` actions, applied by a `rex do` script |

Notes:

- No file watching. After edits: `rex config check` then `rex config reload`.
- A bad `rex.bind` call is skipped, rest loads; a Lua syntax error keeps the
  last good config.
- Client actions (`pane.*`, `client.*`) come from the app; `rex keymap` reports
  bindings that name actions the app doesn't have.
- `rex.client.queue` needs a connected client, so app settings can't be applied
  from `init.lua` at server start — hence the separate script.
- Don't stow or `defaults export` the plist: it carries session IDs, activity
  history, and sync blobs.

## Target layout

```
.config/rex/
  README.md      # this plan (stow-ignored via README.*)
  catppuccin-mocha  # Ghostty-format theme, imported by settings.lua
  init.lua       # entry: require("keys"), require("actions")
  keys.lua       # bindings + modes
  actions.lua    # custom actions / layouts
  settings.lua   # app look & feel, run with `rex do`
```

Start with `init.lua` alone; split only once it passes ~100 lines.

## Phases

### 1. Wire into stow

- [x] Create `init.lua` with one harmless binding to prove the path
      (`cmd+shift+enter` → `pane.zoom`).
- [x] Add `$HOME/.config/rex/init.lua` (and later siblings) to `CONFLICTS` in
      `install.sh` and the matching array in `.github/workflows/ci.yml`.
- [x] `stow --no-folding -R .` → confirm `~/.config/rex` is a real dir with
      symlinks; `rex config check` reports `exists: yes`.
- [x] Mention Rex in `Readme.md` directory tree.

### 2. Look & feel (`settings.lua`)

Match the rest of the repo (Alacritty, fzf, zsh: Catppuccin Mocha,
FiraCode Nerd Font Mono 14).

- [x] `settings.lua` sets font `FiraCode Nerd Font Mono`, size `14`, scheme
      `dark` (Mocha has no light pair; `auto` would flip to Merino light).
- [x] Theme: Rex ships no Catppuccin. `catppuccin-mocha` here is a Ghostty-format
      theme (import accepts Ghostty or iTerm files), palette copied from the
      Alacritty Mocha file; `settings.lua` imports it, then selects it.
- [x] Applied with `rex do ~/.config/rex/settings.lua` (Remote Control on).
      Safe to rerun: import replaces the same-named theme, no duplicates.
- [ ] Later, only if wanted: interface style, inactive pane fade, active
      border, pane padding.

### 3. Key bindings (`keys.lua`)

Port Zellij muscle memory (`.config/zellij/config.kdl`) into Rex key modes:

| Zellij | Rex |
|---|---|
| `Ctrl p` pane mode: `h/j/k/l` focus, `r`/`d` split right/down, `f` fullscreen, `x` close | mode `pane`: `pane.focus`, `pane.split {direction}`, `pane.zoom` |
| `Ctrl t` tab mode: `1-9` goto, `h/l` prev/next, `n` new | mode `tab`: `client.tab.goto {index}`, `client.tab.new` |
| `Ctrl n` resize mode | mode `resize`, `exclusive = true`, arrows/hjkl → `pane.resize` |
| `Ctrl o` session mode | `session.switch` palette is likely enough |

- [ ] Decide prefix style: Zellij-style `ctrl+p` modes vs `cmd+…` direct keys.
      `ctrl+p/t/n` collide with shell/nvim — Zellij already ate them, so
      parity is fine, but `cmd+` keeps them free.
- [ ] Use `once = true` on modes for single-shot actions (split/new tab);
      leave `resize` sticky.
- [ ] Verify with `rex keymap` (shows SOURCE per key + unknown actions).

### 4. Custom actions (`actions.lua`)

Only ones actually used weekly:

- [ ] `dev_layout`: nvim left, shell right (`rex.layout.horizontal`), cwd =
      current pane's pwd.
- [ ] `agent_layout`: Claude Code + shell + `git diff` watcher, fits the
      offload loop (plan → `/offload` → review diff).
- [ ] Skip a cwd-tab-rename hook (Zellij needed `_zellij_tab_cwd` in
      `zsh/functions.zsh`) unless Rex tabs don't already show cwd/program.

### 5. Hosts (optional)

- [ ] `rex.host{…}` for homelab boxes (Ollama GPU node) once a Rex server runs
      there. Lets `rex -S <host> run …` drive remote jobs from here.

### 6. Retire overlap (decide after 2–3 weeks)

- [ ] Zellij autostart is gated on `START_ZELLIJ=1`, set only in
      `alacritty.toml`, so Rex shells don't nest Zellij. No change needed now.
- [ ] If Rex sticks: drop Alacritty + Zellij configs, `CONFLICTS` entries,
      `_zellij_tab_cwd`, Brewfile casks.

## Decisions

1. Run Rex alongside Alacritty + Zellij for now; phase 6 decides later.
2. Key style: macOS-native `cmd` keys, not Zellij-style `ctrl` modes.
3. Theme: Catppuccin Mocha, matching the rest of the repo.

## Verify loop

```sh
rex config check            # parse + count bindings/modes/actions
rex config reload           # apply (local machine only)
rex keymap                  # merged view; flags unknown actions
rex -C <client> actions     # source of truth for action names/args
```
