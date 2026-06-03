# Make dir and cd into it
mkcd() { mkdir -p "$1" && cd "$1" }

# Universal archive extractor
extract() {
  case $1 in
    *.tar.gz|*.tgz)  tar xzf "$1" ;;
    *.tar.bz2)       tar xjf "$1" ;;
    *.tar.xz)        tar xJf "$1" ;;
    *.zip)           unzip "$1" ;;
    *.7z)            7z x "$1" ;;
    *.gz)            gunzip "$1" ;;
    *.rar)           unrar e "$1" ;;
    *)               echo "unknown archive: $1" ;;
  esac
}

# fzf cd — fuzzy jump to any directory
fcd() {
  local dir
  dir=$(fd --type d --hidden --exclude .git | fzf --preview 'eza --tree --level=2 {}')
  [ -n "$dir" ] && cd "$dir"
}

# fzf git branch checkout
gco() {
  local branch
  branch=$(git branch --all | fzf | tr -d '[:space:]')
  [ -n "$branch" ] && git checkout "${branch#remotes/origin/}"
}

# Show what's using a port
port() { lsof -i ":$1" }

# Get public IP
myip() { curl -s https://api.ipify.org && echo }

# Quick HTTP server in current dir
serve() { python3 -m http.server "${1:-8000}" }

# fzf kill process
fkill() {
  local pid
  pid=$(procs | fzf --header-lines=1 | awk '{print $1}')
  [ -n "$pid" ] && kill -9 "$pid"
}
