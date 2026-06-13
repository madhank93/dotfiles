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

# ── Packages ──────────────────────────────────────────────────────────────────
# brew bundle needs a live terminal for cask .pkg installers that require
# interactive sudo. Cache sudo credentials upfront so pkg installers and
# cask adopt operations don't stall waiting for a password.

sudo -v
# Keep sudo token alive for the duration (brew bundle can take 10+ min on fresh install)
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE=$!
trap "kill $SUDO_KEEPALIVE 2>/dev/null" EXIT

brew bundle install --file="$DOTFILES/mac/Brewfile" --no-upgrade || {
  echo ""
  echo "  ⚠ brew bundle had failures — likely casks needing manual install."
  echo "  Run: brew bundle check --file=$DOTFILES/mac/Brewfile --verbose"
  echo "  Continuing with remaining setup steps..."
  echo ""
}

# Pin critical tools to prevent accidental brew upgrade
for pkg in kubernetes-cli helm awscli mise neovim; do
  brew pin "$pkg" 2>/dev/null || true
done

# ── Shell — register homebrew zsh + set as default ────────────────────────────
# (sudo token already cached above for brew bundle, so no extra prompt)

ZSH_PATH="$(command -v zsh)"

if ! grep -qx "$ZSH_PATH" /etc/shells; then
  echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
fi

# no-op if zsh is already the default shell (Catalina+)
[[ "$SHELL" == "$ZSH_PATH" ]] || sudo chsh -s "$ZSH_PATH" "$USER" || true

# ── Stow ──────────────────────────────────────────────────────────────────────

CONFLICTS=(
  "$HOME/.zprofile"
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
