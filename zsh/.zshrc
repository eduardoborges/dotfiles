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

# rustup: shims do homebrew (cargo, rustc) nao entram no PATH sozinhos
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

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

# herdr-automatic-rename: renomeia a aba assim que um comando inicia
for _f in ${HOME}/.config/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.zsh(N); do
  source $_f; break
done

# creditos restantes da conta Enterprise (perfil ~/.claude-work)
claude-work-credits() {
  python3 - <<'PY'
import json, os, subprocess, sys, urllib.request

home = os.path.expanduser("~")
cfgdir = home + "/.claude-work"

import hashlib
svc = "Claude Code-credentials-" + hashlib.sha256(cfgdir.encode()).hexdigest()[:8]
tok = None
r = subprocess.run(["security", "find-generic-password", "-s", svc, "-w"],
                   capture_output=True, text=True)
if r.returncode == 0:
    try:
        tok = json.loads(r.stdout.strip())["claudeAiOauth"]["accessToken"]
    except Exception:
        pass
if not tok and os.path.exists(cfgdir + "/.credentials.json"):
    tok = json.load(open(cfgdir + "/.credentials.json"))["claudeAiOauth"]["accessToken"]
if not tok:
    sys.exit("token nao encontrado (keychain nem .credentials.json)")

def get(url):
    req = urllib.request.Request(url, headers={
        "Authorization": "Bearer " + tok,
        "Content-Type": "application/json",
        "anthropic-beta": "oauth-2025-04-20",
    })
    try:
        return json.load(urllib.request.urlopen(req, timeout=10))
    except Exception as e:
        return {"_err": str(e)}

u = get("https://api.anthropic.com/api/oauth/usage")
if "_err" in u:
    sys.exit("falha em /api/oauth/usage: " + u["_err"])

for key, label in (("five_hour", "sessao 5h"), ("seven_day", "semana 7d")):
    w = u.get(key)
    if w and w.get("utilization") is not None:
        print(f"{label}: {w['utilization']:.0f}% usado, reseta {w.get('resets_at')}")

x = u.get("extra_usage")
if x and x.get("is_enabled"):
    lim, used = x.get("monthly_limit"), x.get("used_credits") or 0
    cur = x.get("currency") or "USD"
    if lim:
        print(f"creditos: {used/100:.2f} de {lim/100:.2f} {cur} (restam {(lim-used)/100:.2f})")
    else:
        print(f"creditos usados no mes: {used/100:.2f} {cur} (sem limite)")
else:
    print("extra_usage: nao exposto para esta conta (alocacao gerida pelo admin da org)")

org = json.load(open(cfgdir + "/.claude.json")).get("oauthAccount", {}).get("organizationUuid")
if org:
    b = get(f"https://api.anthropic.com/api/oauth/organizations/{org}/prepaid/credits")
    if isinstance(b.get("amount"), (int, float)):
        print(f"saldo prepago da org: {b['amount']/100:.2f} {b.get('currency', 'USD')}")
PY
}

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

# cmux: aponta o wrapper direto pro claude real (fix "claude not found in PATH")
export CMUX_CUSTOM_CLAUDE_PATH="$HOME/.local/bin/claude"
export PATH=$PATH:$HOME/.maestro/bin
