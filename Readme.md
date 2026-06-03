# dotfiles

Personal dotfiles for macOS. Managed with [GNU Stow](https://www.gnu.org/software/stow/) + [Ansible](https://www.ansible.com/).

## Quick start

```sh
git clone <repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` runs: Homebrew → Ansible playbook → Stow symlinks.

## Structure

```
dotfiles/
├── .zshrc                    # shell entry point (sources zsh/ modules)
├── .gitconfig                # git config with delta pager
├── .config/
│   ├── alacritty/            # terminal: catppuccin theme + keybindings
│   ├── starship.toml         # prompt: git, k8s, language versions
│   ├── zellij/               # terminal multiplexer
│   └── mise/config.toml      # pinned runtime versions (node/python/go)
├── zsh/
│   ├── aliases.zsh           # all aliases
│   ├── env.zsh               # PATH and exports
│   └── functions.zsh         # shell functions (mkcd, extract, fcd…)
├── mac/
│   ├── setup.yml             # Ansible playbook
│   ├── Brewfile              # pinned package list with versions
│   └── README.md             # macOS setup guide
└── install.sh                # bootstrap script
```

## Day-to-day

| Task | Command |
|------|---------|
| Re-apply symlinks | `stow --target=$HOME --restow .` |
| Add a package | Edit `mac/Brewfile` → `brew bundle install --file=mac/Brewfile` |
| Check package drift | `brew bundle check --file=mac/Brewfile` |
| Update a runtime | `mise use --global node@<version>` |
| Upgrade pinned pkg | `brew unpin <pkg> && brew upgrade <pkg> && brew pin <pkg>` |

## Platforms

| Platform | Setup |
|----------|-------|
| macOS (Apple Silicon) | `./install.sh` |
| Linux (amd64) | `linux/linux_amd64.yml` |
| Windows | `windows/window-toggle.ahk` |

## Troubleshooting

- Slow shell startup: `zsh -i -c 'zprof'` (enable `zmodload zsh/zprof` at top of `.zshrc`)
- Stow conflicts: `stow --target=$HOME --restow --adopt .` then `git checkout .`
