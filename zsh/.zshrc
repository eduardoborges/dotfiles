# My Favorite Shell
eval "$(starship init zsh)"

# mise (polyglot runtime manager - node, pnpm, etc.)
eval "$(mise activate zsh)"

export EDITOR='cursor'
export VISUAL='cursor'


# Shell Plugins
export ZPLUG_HOME=$HOME/.zplug
source $ZPLUG_HOME/init.zsh
zplug "tcnksm/docker-alias", use:zshrc
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

alias d="docker"
alias dc="docker-compose"

alias h="http-server"

alias n="npm"
alias nr="npm run"

alias pn="pnpm"
alias pnr="pnpm run"


# My functions
function f()    { find . -iname "*$1*" ${@:2} }
function r()    { grep "$1" ${@:2} -R . }
function size() { du -sh "$1" | awk '{print $1}' }
function cleanGit() { git clean -Xdf }


# Extra
export PATH="$PATH:$HOME/.bin"
# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/eduardo/.lmstudio/bin"
# End of LM Studio CLI section

export PATH="$HOME/.local/bin:$PATH"
