# === Core ===
export EDITOR="nvim"
export VISUAL="nvim"
export LANG=en_US.UTF-8

# === ZSH modules ===
[ -f "$HOME/zsh/env.zsh" ]       && source "$HOME/zsh/env.zsh"
[ -f "$HOME/zsh/aliases.zsh" ]   && source "$HOME/zsh/aliases.zsh"
[ -f "$HOME/zsh/functions.zsh" ] && source "$HOME/zsh/functions.zsh"

# === History ===
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# === Zinit — plugin manager (replaces oh-my-zsh) ===
# Installed via: brew install zinit (3.14.0)
[[ ! -f /opt/homebrew/opt/zinit/zinit.zsh ]] && echo "zinit missing — run: brew install zinit" && return
source /opt/homebrew/opt/zinit/zinit.zsh
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Plugins loaded in parallel — faster startup vs oh-my-zsh
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light Aloxaf/fzf-tab            # fzf-powered tab completion

# OMZ snippets — picks specific parts, no full OMZ framework overhead
zinit snippet OMZP::git               # git aliases: ga, gst, gco, gp, gl…
zinit snippet OMZP::sudo              # ESC+ESC prepends sudo to last command
zinit snippet OMZP::kubectl           # k=kubectl + completions

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#f38ba8,underline"

# === Tool inits ===
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(mise activate zsh)"
eval "$(direnv hook zsh)"
eval "$(atuin init zsh --disable-up-arrow)"

# === FZF ===
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
# Catppuccin Mocha
export FZF_DEFAULT_OPTS=" \
  --height 40% --border \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

# fzf-tab: preview directory contents on tab-complete cd
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 {}'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --tree --level=2 {}'

# === Completions ===
autoload -Uz compinit && compinit
command -v kubectl &>/dev/null && source <(kubectl completion zsh)
