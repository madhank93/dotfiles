# Login shell profile — sourced by login shells and macOS GUI apps (VSCode, etc.)
# .zshrc is NOT sourced by GUI apps, so tool activation goes here.

# Homebrew
[[ "$(uname -m)" == "arm64" ]] && eval "$(/opt/homebrew/bin/brew shellenv)" || eval "$(/usr/local/bin/brew shellenv)"

# mise — activates version-managed tools (Go, Node, Python…) for GUI apps
eval "$(/opt/homebrew/bin/mise activate zsh)"

# uv tools — Python CLIs installed via `uv tool install` (aider, …)
export PATH="$HOME/.local/bin:$PATH"

# OrbStack (added by OrbStack installer — keep for container/VM tooling)
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
