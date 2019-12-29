# Resources
#   - https://scriptingosx.com/2019/06/moving-to-zsh-part-3-shell-options/

export ZSH="/Users/davidnix/.oh-my-zsh"
ZSH_THEME="crunch"

# ZSH Options
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
setopt CORRECT
setopt CORRECT_ALL

# Order of operations important! Plugins must come before sourcing the script
plugins=(git osx vi-mode)
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