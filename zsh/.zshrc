# My Favorite Shell
eval "$(starship init zsh)"

# mise (polyglot runtime manager - node, pnpm, etc.)
eval "$(mise activate zsh)"

export EDITOR=cursor
export VISUAL=cursor

source $HOME/.envrc

# Shell Plugins
export ZPLUG_HOME=$HOME/.zplug
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

alias ..="cd .."
alias ...="cd ../.."

alias v="nvim"

alias k="kubectl"
alias kx="kubectl exec -it"

alias d="dk"

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
function avdnext() {
  local avds running_avds next_avd
  local -a stopped_avds

  echo "[avdnext] listando AVDs instaladas..."
  avds=("${(@f)$(emulator -list-avds 2>/dev/null)}")
  if (( ${#avds[@]} == 0 )); then
    echo "[avdnext] nenhuma AVD encontrada"
    return 1
  fi

  echo "[avdnext] detectando AVDs em execucao..."
  running_avds=("${(@f)$(ps -eo comm=,args= | awk '$1 ~ /^emulator$/ || $1 ~ /^qemu-system-x86/ { $1=""; sub(/^[[:space:]]+/, ""); print }' | sed -n -e 's/.*-avd[[:space:]]\([^[:space:]]\+\).*/\1/p' -e 's/.*@\([^[:space:]]\+\).*/\1/p' | sort -u)}")

  for avd in "${avds[@]}"; do
    if (( ${running_avds[(Ie)$avd]} == 0 )); then
      stopped_avds+=("$avd")
    fi
  done

  if (( ${#running_avds[@]} > 0 )); then
    echo "[avdnext] em execucao: ${running_avds[*]}"
  else
    echo "[avdnext] em execucao: nenhuma"
  fi

  if (( ${#stopped_avds[@]} == 0 )); then
    echo "[avdnext] todas as AVDs ja estao abertas. nao vou duplicar."
    return 0
  fi

  next_avd="${stopped_avds[1]}"
  echo "[avdnext] proxima AVD disponivel: $next_avd"
  nohup emulator -avd "$next_avd" >/tmp/avd-"$next_avd".log 2>&1 &
  disown
  echo "[avdnext] abrindo AVD: $next_avd"
}

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

copy() { wl-copy; }

# Android SDK
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ANDROID_AVD_HOME=$HOME/.config/.android/avd
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"

# Extra
export PATH="$PATH:$HOME/.bin"
# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

export PATH="$HOME/.local/bin:$PATH"
export PATH=$PATH:$HOME/.maestro/bin

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


. "$HOME/.local/share/../bin/env"
source /home/edu/.config/op/plugins.sh
