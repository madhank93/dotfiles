#!/usr/bin/env zsh
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# ── Xcode Command Line Tools ───────────────────────────────────────────────────

if ! xcode-select -p &>/dev/null; then
  echo "Xcode Command Line Tools not found."
  echo "Run: xcode-select --install"
  echo "Then re-run this script."
  exit 1
fi

# ── Homebrew ──────────────────────────────────────────────────────────────────

# Detect brew path (Apple Silicon vs Intel)
if [[ "$(uname -m)" == "arm64" ]]; then
  BREW_BIN="/opt/homebrew/bin/brew"
else
  BREW_BIN="/usr/local/bin/brew"
fi

if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

eval "$($BREW_BIN shellenv)"

# ── Ansible ───────────────────────────────────────────────────────────────────

if ! command -v ansible &>/dev/null; then
  brew install ansible
fi

# --ask-become-pass: prompts once for sudo password (needed for chsh + /etc/shells)
ansible-playbook "$DOTFILES/mac/setup.yml" \
  -i "$DOTFILES/mac/inventory.ini" \
  --ask-become-pass

# ── Stow ──────────────────────────────────────────────────────────────────────
# Backs up any real files that conflict with stow symlinks.
# Safe to re-run — skips files already symlinked.

CONFLICTS=(
  "$HOME/.zshrc"
  "$HOME/.gitconfig"
  "$HOME/.config/starship.toml"
  "$HOME/zsh/aliases.zsh"
  "$HOME/.config/alacritty/alacritty.toml"
  "$HOME/.config/alacritty/catppuccin-mocha.toml"
  "$HOME/.config/alacritty/key-bindings.toml"
  "$HOME/.config/zellij/config.kdl"
)

for f in "${CONFLICTS[@]}"; do
  if [[ -f "$f" && ! -L "$f" ]]; then
    echo "  Backing up: $f → $f.pre-stow"
    mv "$f" "$f.pre-stow"
  fi
done

stow --target="$HOME" --restow --dir="$DOTFILES" .

# ── mise runtimes ─────────────────────────────────────────────────────────────
# Activate mise in this script's shell, then install pinned runtimes.
# Config is now stowed at ~/.config/mise/config.toml (node, python, go).
MISE_BIN="$(brew --prefix)/bin/mise"
if command -v "$MISE_BIN" &>/dev/null; then
  eval "$("$MISE_BIN" activate zsh)" 2>/dev/null || true
  "$MISE_BIN" install
else
  echo "mise not found — run manually: mise install"
fi

echo ""
echo "Done. Open a new shell."
echo "zinit plugins will auto-clone on first shell open (~5s, needs internet)."
