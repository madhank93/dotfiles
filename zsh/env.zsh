# Homebrew (Apple Silicon)
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Local bin
export PATH="$HOME/.local/bin:$PATH"

# Pulumi
export PATH="$PATH:$HOME/.pulumi/bin"
