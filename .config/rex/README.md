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
  init.lua       # bindings, modes, custom actions
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

### 3. Key bindings (`init.lua`)

Rex's default `cmd` keys already cover the Zellij pane/tab modes, so most
needed no config (full list: Mac Actions reference, "Default Shortcut"):

| Zellij | Rex default |
|---|---|
| pane: split right/down | `cmd+d` / `shift+cmd+d`, `cmd+enter` best fit |
| pane: focus | `alt+cmd+arrows`, `cmd+]` / `cmd+[` |
| pane: fullscreen / close | `shift+cmd+enter` zoom / `cmd+w` |
| pane: float | `alt+cmd+enter` |
| tab: goto / next / prev / new | `cmd+1-9` / `shift+cmd+]` / `shift+cmd+[` / `cmd+t` |
| session | `cmd+k` switcher, `shift+cmd+n` new |
| scroll/search | `shift+cmd+c` copy mode (vim keys, `/` search) |

- [x] Dropped the phase 1 test binding: it duplicated the default zoom key.
- [x] Added the only gap, resize mode: `shift+cmd+r`, then arrows or `hjkl`
      (shift = 15% steps), `esc` leaves. Exclusive, so stray keys don't type.
- [ ] Try it for a week; add `hjkl` focus only if arrows chafe (`alt+cmd+h`
      is macOS "Hide Others", so pick keys carefully).

### 4. Custom actions (`init.lua`)

Only ones actually used weekly:

- [x] `dev` (`shift+cmd+e`): nvim left, shell right, both in the focused
      pane's directory; tab named after it.
- [x] OSC 7 hook in `zsh/functions.zsh`: zsh reports its cwd on every `cd`.
      Without it Rex's `pwd` is empty and `dev` falls back to `$HOME`.
- [x] `talos` (`shift+cmd+k`): tab with `k9s --context admin@talos-cluster`
      beside `talosctl dashboard`, for periodic cluster checks. Node comes from
      talosconfig (`talosctl config node …`), keeping the LAN IP out of git.
- [x] Skipped `agent_layout`: Rex's agent integration already covers Claude
      Code; add only if a fixed agent + diff layout gets opened by hand often.
- [x] Skipped a cwd-tab-rename hook: revisit only if Rex tab titles don't
      track cwd/program well enough.

### 5. Hosts (optional)

A Rex host is a machine running a Rex server (`rex.host{label, endpoint}`).

- [x] **Talos cluster: not a host for now.** Talos nodes have no shell, SSH, or
      package manager, so a Rex server can't be installed on them. The only
      route is a Rex server in a pod, reached over Tailscale (built-in or
      Serve). Rex's only no-Tailscale listener has no caller authentication
      (`--allow-anonymous`), which would hand an in-cluster shell to anyone on
      the LAN. Worth it only if long jobs must keep running in-cluster while
      the Mac sleeps; until then the `talos` action covers checking in.
- [x] Ollama: not a separate box. It runs inside the Talos cluster (LoadBalancer
      service), so the Talos reasoning above applies. No hosts added.

### 6. Retire overlap (deferred — review 2026-12-11)

Decision 2026-11-20: keep Alacritty + Zellij alongside Rex.

- [x] No nesting: Zellij autostart is gated on `START_ZELLIJ=1`, set only in
      `alacritty.toml`, so Rex shells never start Zellij.
- [ ] Review 2026-12-11. If Rex sticks: drop Alacritty + Zellij configs, their
      `CONFLICTS` entries (install.sh + ci.yml), `_zellij_tab_cwd` in
      `zsh/functions.zsh`, `START_ZELLIJ`, Brewfile casks.

## Decisions

1. Run Rex alongside Alacritty + Zellij; phase 6 review on 2026-12-11.
2. Key style: macOS-native `cmd` keys, not Zellij-style `ctrl` modes.
3. Theme: Catppuccin Mocha, matching the rest of the repo.

## Verify loop

```sh
rex config check            # parse + count bindings/modes/actions
rex config reload           # apply (local machine only)
rex keymap                  # merged view; flags unknown actions
rex -C <client> actions     # source of truth for action names/args
```
