source ~/.bash_completions

# Opens man pages in preview
psman()
{
man -t "${1}" | open -f -a /Applications/Preview.app/
}

# homebrew wants this first.
# export PATH="/usr/local/bin:$PATH"

# automatically add keys to ssh-agent
# note: for new keys run ssh-add -K <path to key> first
{ eval `ssh-agent`; ssh-add -A; } &>/dev/null

# get correct colorscheme on tmux
alias tmux="TERM=screen-256color-bce tmux"

export PATH=$PATH:/usr/local/sbin

# Go Env Vars
export GOPATH=$HOME/go
export GOROOT="/usr/local/go"
export PATH=$PATH:$GOPATH/bin
export GO15VENDOREXPERIMENT=1

VISUAL=vim; export VISUAL
EDITOR=vim; export EDITOR

# cirrus shortcuts
alias cirrus="cd ~/src/cirrusmd-web-app"
alias cirrusi="cd ~/src/cirrusmd-ios"
alias cirruspub="cd ~/src/cirrusmd-pubsub"
alias cirrusws="cd ~/go/src/github.com/CirrusMD/websocket-server/"
alias cirrusa="cd ~/src/cirrusmd-android"

# Make SSL work with charles
alias sslcharles="~/.scripts/install-charles-ca-cert-for-iphone-simulator.command"

# Postgres
alias pg-start="pg_ctl -D /usr/local/var/postgresql@9.4 -l /usr/local/var/postgresql@9.4/logfile start"
alias pg-stop="pg_ctl -D /usr/local/var/postgresql@9.4 stop -s -m fast"

export AWS_CONFIG_FILE='~/.awscli-config'

# Tell ls to be colorful
export CLICOLOR=1

# Tell grep to highlight matches
export GREP_OPTIONS='--color=auto'

export PS2="\[\033[1;92m\]\u@\h : \w > \[\033[0m\]"

################# COLOR SETTINGS ######################
#######################################################

# Color settings for bash
export TERM=xterm-256color
export GREP_OPTIONS='--color=auto' GREP_COLOR='0;36'
export CLICOLOR=1
 
# The order of the attributes are as follows (fgbg):
# 01. directory
# 02. symbolic link
# 03. socket
# 04. pipe
# 05. executable
# 06. block special
# 07. character special
# 08. executable with setuid bit set
# 09. executable with setgid bit set
# 10. directory writable to others, with sticky bit
# 11. directory writable to others, without sticky bit
#      LSCOLORS=0102030405060708091011
export LSCOLORS=excxgxfxbxdxbxbxbxexex
 
# Color          | Escaped    | ANSI
# -------------- | ---------- | ------------
# No Color       | \033[0m    | x (default foreground)
# Black          | \033[0;30m | a
# Grey           | \033[1;30m | A
# Red            | \033[0;31m | b
# Bright Red     | \033[1;31m | B
# Green          | \033[0;32m | c
# Bright Green   | \033[1;32m | C
# Brown          | \033[0;33m | d
# Yellow         | \033[1;33m | D
# Blue           | \033[0;34m | e
# Bright Blue    | \033[1;34m | E
# Magenta        | \033[0;35m | f
# Bright Magenta | \033[1;35m | F
# Cyan           | \033[0;36m | g
# Bright Cyan    | \033[1;36m | G
# Bright Grey    | \033[0;37m | h
# White          | \033[1;37m | H
 
parse_git_branch() {
  __git_ps1 " [%s]"
}
 
settitle() {
  echo -n -e "\033]0;$*\007"
}
 
export GIT_PS1_SHOWDIRTYSTATE='true'
export PS1="\[\033[35m\][\h\[\033[00m\]\[\033[35m\]] \[\033[34m\]\W\[\033[32m\]\[\033[31m\]\$(parse_git_branch)\[\033[00m\] \[\033[0m\]"
# export PS1="\[\033[35m\][\h\[\033[00m\]\[\033[35m\]] \[\033[34m\]\W\[\033[32m\]\$(parse_ruby_version)\[\033[31m\]\$(parse_git_branch)\[\033[00m\] \[\033[0m\]"
export PS2="\[\033[35m\]→ \[\033[0m\]"

eval "$(rbenv init -)"


# Setting PATH for Python 3.6
# The original version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.6/bin:${PATH}"
export PATH

# added by Anaconda3 4.2.0 installer
export PATH="/Users/david/anaconda/bin:$PATH"
