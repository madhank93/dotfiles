# macOS Setup

## Prerequisites

```sh
xcode-select --install
```

## Install

```sh
./install.sh
```

Or manually:

```sh
brew bundle install --file=mac/Brewfile
ansible-playbook mac/setup.yml -i mac/inventory.ini
stow --target=$HOME --restow .
```

## Package management

Packages are defined in `mac/Brewfile` with pinned versions.

```sh
# Install all packages
brew bundle install --file=mac/Brewfile

# Check if any packages are missing or out of date
brew bundle check --file=mac/Brewfile

# Commit the lockfile after first install
git add mac/Brewfile.lock.json && git commit -m "chore: lock brew package versions"
```

After first `brew bundle install`, a `Brewfile.lock.json` is generated. Commit it to lock exact versions.

## Runtime versions (mise)

Node, Python, and Go are managed by mise. Versions pinned in `.config/mise/config.toml`.

brew keeps `node`, `python@3.13`, `go` installed as deps for other brew tools (`cdk8s`, `awscli`, `yt-dlp` etc). Do NOT `brew uninstall` them. mise shims shadow them on PATH automatically via `mise activate zsh`.

### First-time setup

```sh
# 1. Install mise
brew install mise

# 2. Install all pinned runtimes
mise install

# 3. Verify mise controls PATH (should show ~/.local/share/mise/...)
which node && which python3 && which go

# 4. Reinstall global npm packages (lost when switching from nvm)
npm install -g cdk8s-cli ts-node

# 5. Reinstall Go tools
go install golang.org/x/tools/gopls@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install honnef.co/go/tools/cmd/staticcheck@latest
```

### Day-to-day

```sh
# See installed runtimes
mise ls

# Install pinned versions from config
mise install

# Upgrade a runtime globally
mise use --global node@22.16.0

# Per-project override (creates .mise.toml in cwd)
mise use node@20.0.0

# List available versions
mise ls-remote node
```

### OrbStack (Docker)

OrbStack is already active and managing Docker. `docker-desktop` cask can safely be removed:

```sh
# Quit Docker Desktop first (if running), then:
brew uninstall --cask docker-desktop
```

Containers and images managed by OrbStack are unaffected.

## Tools reference

### Shell

| Tool | Version | Usage |
|------|---------|-------|
| [zinit](https://github.com/zdharma-continuum/zinit) | 3.14.0 | plugin manager — replaces oh-my-zsh; loads plugins in parallel |
| [starship](https://starship.rs) | 1.25.1 | prompt — shows git, k8s, language versions |
| [atuin](https://atuin.sh) | 18.16.1 | `ctrl+r` — fuzzy history search across sessions |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | 0.9.9 | `z <partial-path>` — jump to frecent dirs |
| [direnv](https://direnv.net) | 2.37.1 | auto-loads `.envrc` on `cd` |

**zinit plugin management:**

```sh
# Update all plugins
zinit update --all

# List loaded plugins
zinit list

# Add a new plugin (then persist in .zshrc)
zinit light username/plugin-name

# Load an OMZ snippet
zinit snippet OMZP::plugin-name
```

### Git

| Tool | Version | Usage |
|------|---------|-------|
| [lazygit](https://github.com/jesseduffield/lazygit) | 0.62.1 | `lg` — full TUI: stage hunks, rebase, log |
| [git-delta](https://github.com/dandavison/delta) | 0.19.2 | auto-applied as git pager — side-by-side diffs |
| [gh](https://cli.github.com) | 2.93.0 | `gh pr create`, `gh issue list` |

### Search / Navigation

| Tool | Version | Usage |
|------|---------|-------|
| [fzf](https://github.com/junegunn/fzf) | 0.73.1 | `ctrl+t` files, `ctrl+r` history, `alt+c` dirs |
| [fd](https://github.com/sharkdp/fd) | 10.4.2 | `fd pattern` — replaces `find` |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | 15.1.0 | `rg pattern` — replaces `grep` |
| [navi](https://github.com/denisidoro/navi) | 2.24.0 | `navi` — interactive command cheatsheets |

### File / Disk

| Tool | Version | Usage |
|------|---------|-------|
| [bat](https://github.com/sharkdp/bat) | 0.26.1 | `cat file` (aliased) — syntax highlighted output |
| [eza](https://github.com/eza-community/eza) | 0.23.4 | `ls` / `ll` / `lt` (aliased) — icons + git status |
| [dust](https://github.com/bootandy/dust) | 1.2.4 | `du` (aliased) — visual disk usage tree |
| [duf](https://github.com/muesli/duf) | 0.9.1 | `df` (aliased) — disk free with pretty output |

### System

| Tool | Version | Usage |
|------|---------|-------|
| [bottom](https://github.com/ClementTsang/bottom) | 0.12.3 | `top` (aliased) — CPU/mem/disk/net TUI |
| [procs](https://github.com/dalance/procs) | 0.14.11 | `ps` (aliased) — searchable process list |

### Kubernetes

| Tool | Version | Usage |
|------|---------|-------|
| [k9s](https://k9scli.io) | 0.50.18 | `k9s` — full TUI: browse pods, exec, logs |
| [kubectx](https://github.com/ahmetb/kubectx) | 0.11.0 | `kctx` — switch context, `kns` — switch namespace |
| [stern](https://github.com/stern/stern) | 1.34.0 | `stern pod-name` — multi-pod log tail |

### macOS Apps

| App | Purpose |
|-----|---------|
| [Raycast](https://www.raycast.com) | Replace Spotlight — cmd+space, extensions, clipboard history |
| [Aerospace](https://github.com/nikitabobko/AeroSpace) | Tiling window manager — keyboard-driven layouts |
| [Karabiner-Elements](https://karabiner-elements.pqrs.org) | Remap CapsLock → Hyper key for custom shortcuts |
| [OrbStack](https://orbstack.dev) | Docker runtime — replaces Docker Desktop + colima |

## Pinned packages

These packages are pinned via `brew pin` to prevent `brew upgrade` from updating them unexpectedly:

- `kubernetes-cli` — API compatibility matters
- `helm` — chart compatibility
- `awscli` — API stability
- `mise` — runtime manager stability
- `neovim` — plugin API stability

To upgrade a pinned package:

```sh
brew unpin kubernetes-cli
brew upgrade kubernetes-cli
brew pin kubernetes-cli
```
