# My Favorite Shell
if [[ "$OSTYPE" == darwin* ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

eval "$(starship init zsh)"

# mise (polyglot runtime manager - node, pnpm, etc.)
eval "$(mise activate zsh)"

export EDITOR="code --wait"
export VISUAL="code --wait"
export GIT_EDITOR="code --wait"

source $HOME/.envrc

# Shell Plugins
if [[ "$OSTYPE" == darwin* ]]; then
  export ZPLUG_HOME=/opt/homebrew/opt/zplug
else
  export ZPLUG_HOME=$HOME/.zplug
fi
source $ZPLUG_HOME/init.zsh
zplug "plugins/git", from:oh-my-zsh
zplug "zdharma-continuum/fast-syntax-highlighting"
zplug "zsh-users/zsh-autosuggestions"
zplug "remcohaszing/zsh-node-bin"

if ! zplug check; then
  zplug install
fi
zplug load

# My aliases
alias p="cd ~/Projects"

alias g="git"
alias gs="git status"
alias ga="git add"
alias gcm="git commit -m"
alias gca="git commit -am"
alias gco="git checkout"
alias gpl="git pull"
alias gpu="git push"
alias gbr="git branch"
alias gcl="git clone"

alias c="clear"
alias l="ls -la"
alias ll="ls -l"
alias la="ls -A"

alias claude-work="CLAUDE_CONFIG_DIR=~/.claude-work claude"

alias ..="cd .."
alias ...="cd ../.."

alias v="nvim"

alias k="kubectl"
alias kx="kubectl exec -it"

alias d="docker"
alias dup="docker compose up -d"
alias ddown="docker compose down"
alias dbuild="docker compose build"
alias drebuild="docker compose build --no-cache"
alias drestart="docker compose down && docker compose up -d"
alias dlogs="docker compose logs -f"
alias dexec="docker compose exec"
alias dssh="docker compose exec /bin/sh"

alias h="http-server"

alias n="npm"
alias nr="npm run"

alias pn="pnpm"
alias pnr="pnpm run"

# Rede: função que retorna todos os IPs da máquina (um por linha)
# (usa "function name {" para não conflitar com alias "ips" do docker-alias)
function ips {
  if command -v ip &>/dev/null; then
    ip -o addr show | awk '/inet / {gsub(/\/[0-9]+/, "", $4); print $4}'
  else
    hostname -I 2>/dev/null | tr ' ' '\n' | grep -v '^$'
  fi
}

# My functions
function f()    { find . -iname "*$1*" ${@:2} }
function r()    { grep "$1" ${@:2} -R . }
function size() { du -sh "$1" | awk '{print $1}' }
function cleanGit() { git clean -Xdf }

function killatport() {
  if [ -z "$1" ]; then
    echo "Usage: killatport <port>"
    return 1
  fi
  pids=$(lsof -t -i:"$1" 2>/dev/null)
  if [ -z "$pids" ]; then
    echo "No process found on port $1"
    return 1
  fi
  echo "$pids" | xargs kill -9
  echo "Killed process(es) on port $1: $pids"
}

# Clipboard: pbcopy on macOS, wl-copy on Wayland/Linux
if [[ "$OSTYPE" == darwin* ]]; then
  copy() { pbcopy; }
elif command -v wl-copy &>/dev/null; then
  copy() { wl-copy; }
elif command -v xclip &>/dev/null; then
  copy() { xclip -selection clipboard; }
fi

# Android SDK (different default locations per OS)
if [[ "$OSTYPE" == darwin* ]]; then
  export ANDROID_HOME=$HOME/Library/Android/sdk
else
  export ANDROID_HOME=$HOME/Android/Sdk
fi
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ANDROID_AVD_HOME=$HOME/.config/.android/avd
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/eduardo/.lmstudio/bin"
# End of LM Studio CLI section

# pnpm
export PNPM_HOME="/Users/eduardo/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
