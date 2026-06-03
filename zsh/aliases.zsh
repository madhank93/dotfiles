# Shell
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'
alias cat='bat'
alias grep='grep --color=auto'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias zz='z -'

# Git
alias lg='lazygit'
alias gst='git status'
alias gd='git diff'
alias gds='git diff --staged'
alias glo='git log --oneline --graph --decorate'

# Kubernetes
alias k='kubectl'
alias kctx='kubectx'
alias kns='kubens'

# System
alias top='btm'
alias du='dust'
alias df='duf'
alias ps='procs'

# Tools
alias python='python3'
alias vim='nvim'
alias tmux='tmux -u'

# Starship toggle
alias gt='starship toggle gcloud disabled'
