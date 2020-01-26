# Resources
#   - https://scriptingosx.com/2019/06/moving-to-zsh-part-3-shell-options/

export ZSH="/Users/davidnix/.oh-my-zsh"
ZSH_THEME="crunch"

# ZSH Options
# http://zsh.sourceforge.net/Doc/Release/Options.html
# auto cd into directories
setopt AUTO_CD
# case insensitive globbing
setopt NO_CASE_GLOB
# History file config
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
SAVEHIST=5000
HISTSIZE=2000
# share history across multiple zsh sessions
setopt SHARE_HISTORY
# ask before subbing commands via !!
setopt HIST_VERIFY
# append to history
setopt APPEND_HISTORY
# adds commands as they are typed, not at shell exit
setopt INC_APPEND_HISTORY
# expire duplicates first
setopt HIST_EXPIRE_DUPS_FIRST
# do not store duplications
setopt HIST_IGNORE_DUPS
#ignore duplicates when searching
setopt HIST_FIND_NO_DUPS
# removes blank lines from history
setopt HIST_REDUCE_BLANKS
# Autocorrection
# Try to correct spelling of commands
# setopt CORRECT
# Try to correct spelling of all arguments
# setopt CORRECT_ALL
setopt ALWAYS_TO_END
# Append a trailing ‘/’ to all directory names resulting from filename generation (globbing).
setopt MARK_DIRS
# If a pattern for filename generation has no matches, print an error, instead of leaving it unchanged in the argument list
setopt NOMATCH

# Turn off _approximate autocompletion
# https://stackoverflow.com/questions/27012295/really-turn-off-zsh-autocorrect#27018690
zstyle ':completion*' completer _expand _complete

# Order of operations important! Plugins must come before sourcing the script
# https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins#extract
plugins=(
    asdf
    git 
    jsontools
    kubectl
    osx 
    ssh-agent
    sublime
    tmux
    vi-mode
    web-search
    z
    zsh-autosuggestions
    zsh-completions
)
source $ZSH/oh-my-zsh.sh

# advanced completions
autoload -Uz compinit && compinit
# load bashcompinit for some old bash completions
autoload bashcompinit && bashcompinit

export EDITOR='vim'

# Go specific
export GOPATH=$HOME/go

# Useful Aliases
alias k="kubectl"
alias c="clear"

# Work related aliases
alias cirrusweb="cd ~/src/cirrusmd/cirrusmd-web-app"
alias cirrusws="cd ~/src/cirrusmd/websocket-server/"
alias cirrusetl="cd ~/src/cirrusmd/etl-platform/"
alias splitcsv="~/src/cirrusmd/etl-platform/script/splitcsv"

# PATH modifications
export PATH="/usr/local/bin:/usr/local/sbin:$GOPATH/bin:$HOME/.cargo/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/flutter/bin"
export PATH="/usr/local/heroku/bin:$PATH"

# ASDF https://asdf-vm.com/#/core-manage-asdf-vm
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash

# Kubernetes
alias kctx="kubectx"
alias kns="kubens"

# zsh plugin creates the k alias for kubectl
complete -F __start_kubectl k
source <(kubectl completion zsh)
# stern is a k8s log helper
source <(stern --completion=zsh)

# awscli wants this

export PATH="$PATH:$HOME/.local/bin"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/davidnix/src/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/davidnix/src/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/davidnix/src/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/davidnix/src/google-cloud-sdk/completion.zsh.inc'; fi
