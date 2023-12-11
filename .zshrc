# Resources
#   - https://scriptingosx.com/2019/06/moving-to-zsh-part-3-shell-options/
#   - https://github.com/manilarome/the-glorious-dotfiles

export ZSH="/Users/davidnix/.oh-my-zsh"
# Using starship for command prompt instead
# ZSH_THEME="crunch"

# Standard Plugins
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Zplug plugins
[ ! -d ~/.zplug ] && git clone https://github.com/zplug/zplug ~/.zplug
source ~/.zplug/init.zsh

zplug 'zplug/zplug', hook-build:'zplug --self-manage'

zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-autosuggestions"
zplug "felixr/docker-zsh-completion"


# Trying https://github.com/jdxcode/rtx in place of asdf
# zplug "plugins/asdf",                   from:oh-my-zsh

zplug "plugins/brew",                   from:oh-my-zsh
zplug "plugins/colored-man-pages",      from:oh-my-zsh
zplug "plugins/git",                    from:oh-my-zsh
zplug "plugins/jsontools",              from:oh-my-zsh
zplug "plugins/kubectl",                from:oh-my-zsh
zplug "plugins/osx",                    from:oh-my-zsh
zplug "plugins/ssh-agent",              from:oh-my-zsh
zplug "plugins/tmux",                   from:oh-my-zsh
zplug "plugins/vi-mode",                from:oh-my-zsh
zplug "plugins/z",                      from:oh-my-zsh

zplug load

# ZSH Options
# http://zsh.sourceforge.net/Doc/Release/Options.html
# auto cd into directories
setopt AUTO_CD
# case insensitive globbing
setopt NO_CASE_GLOB
# History file config
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
SAVEHIST=100000
HISTSIZE=100000

setopt always_to_end #     If a completion is performed with the cursor within a word, and a full completion is inserted, the cursor is moved to the end of the word. That is, the cursor is moved to the end of the word if either a single match is inserted or menu completion is performed.
setopt append_history           # Dont overwrite history
setopt autocd                   # Allow changing directories without `cd`
setopt extended_history         # Also record time and duration of commands.
setopt hist_expire_dups_first   # Clear duplicates when trimming internal hist.
setopt hist_find_no_dups        # Dont display duplicates during searches.
setopt hist_ignore_all_dups     # Remember only one unique copy of the command.
setopt hist_ignore_dups         # Ignore consecutive duplicates.
setopt hist_reduce_blanks       # Remove superfluous blanks.
setopt hist_save_no_dups        # Omit older commands in favor of newer ones.
setopt hist_verify              # ask before subbing commands via !!
setopt inc_append_history       # adds commands as they are typed, not at shell exit
setopt mark_dirs # Append a trailing ‘/’ to all directory names resulting from filename generation (globbing).
setopt nomatch                  # If a pattern for filename generation has no matches, print an error, instead of leaving it unchanged in the argument list
setopt share_history            # Share history between multiple shells

# Turn off _approximate autocompletion
# https://stackoverflow.com/questions/27012295/really-turn-off-zsh-autocorrect#27018690
zstyle ':completion*' completer _expand _complete

# advanced completions
autoload -Uz compinit && compinit
# load bashcompinit for some old bash completions
autoload bashcompinit && bashcompinit

# Be explicit about docker host. Some tools change it.
export DOCKER_HOST=unix:///var/run/docker.sock

# Make neovim default editor
export VISUAL=nvim
export EDITOR="$VISUAL"

# Go specific
export GOPATH=$HOME/go

# PATH modifications
export PATH="$GOPATH/bin:/usr/local/bin:/usr/local/sbin:$HOME/.cargo/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin/flutter/bin"

# Homebrew for silicon
export PATH="/opt/homebrew/bin:$PATH"
eval "$(/opt/homebrew/bin/brew shellenv)"

# makes homebrew gmake to just make
export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"
# krew kubectl plugin manager
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Trying rtx instead
# ASDF https://asdf-vm.com/#/core-manage-asdf-vm
# . $HOME/.asdf/asdf.sh
# . $HOME/.asdf/completions/asdf.bash

# RTX is a different version manager compatible with asdf
# See: https://github.com/jdxcode/rtx for install instructions.
# I modified the install command via:
eval "$(/usr/local/bin/rtx activate zsh)"

# zsh plugin creates the k alias for kubectl
complete -F __start_kubectl k
source <(kubectl completion zsh)

# vim fzf needs this
export PATH="$PATH:$HOME/.vim/pack/bundle/start/fzf/bin"

if which direnv &> /dev/null; then
  eval "$(direnv hook $SHELL)"
fi

# Useful Aliases
alias ag="agrind" # angle-grinder
alias c="clear"
alias cat="bat"
alias cloc="tokei"
alias du="dust"
# alias find="fd"
alias k="kubectl"
# alias ls="exa"
alias ps="procs"
# alias sed="sd"
alias time="hyperfine"
alias top="ytop"
alias vi="nvim"
alias vim="nvim"
alias ls="lsd"

# M1 Terminal Helpers
alias arm="env /usr/bin/arch -arm64 /bin/zsh --login"
alias intel="env /usr/bin/arch -x86_64 /bin/zsh --login"

# find the current public ip address
alias myip="curl ifconfig.me"

# Alias python3 to python
alias python=$(which python3)
alias pip=$(which pip3)

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/davidnix/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/davidnix/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/davidnix/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/davidnix/google-cloud-sdk/completion.zsh.inc'; fi

# Mcfly advanced shell history https://github.com/cantino/mcfly
# export MCFLY_KEY_SCHEME=vim
export MCFLY_FUZZY=true
if command -v mcfly &> /dev/null; then eval "$(mcfly init zsh)"; fi

# starship.rs
if command -v starship &> /dev/null; then eval "$(starship init zsh)"; fi

# See: https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

