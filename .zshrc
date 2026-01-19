# Resources
#   - https://scriptingosx.com/2019/06/moving-to-zsh-part-3-shell-options/
#   - https://github.com/manilarome/the-glorious-dotfiles

# ==============================================================================
# Zinit Setup
# ==============================================================================
source /opt/homebrew/opt/zinit/zinit.zsh

# ==============================================================================
# Immediate Plugins (needed before prompt)
# ==============================================================================
zinit snippet OMZP::vi-mode

# ==============================================================================
# Turbo Mode Plugins (load after prompt)
# ==============================================================================
# Completions - load early in turbo
zinit ice wait"0" lucid
zinit light zsh-users/zsh-completions

zinit ice wait"0" lucid
zinit light zsh-users/zsh-autosuggestions

# OMZ plugins with turbo mode
zinit ice wait"0" lucid
zinit snippet OMZP::kubectl

zinit ice wait"0" lucid
zinit snippet OMZP::colored-man-pages

zinit ice wait"0" lucid
zinit snippet OMZP::jsontools

# zoxide (smarter alternative to z)
eval "$(zoxide init zsh)"

zinit ice wait"0" lucid
zinit snippet OMZP::tmux

# Fast syntax highlighting (faster than zsh-syntax-highlighting)
zinit ice wait"0" lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# ==============================================================================
# ZSH Options
# ==============================================================================
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
setopt mark_dirs                # Append a trailing '/' to all directory names resulting from filename generation (globbing).
setopt nomatch                  # If a pattern for filename generation has no matches, print an error, instead of leaving it unchanged in the argument list
setopt share_history            # Share history between multiple shells

# Turn off _approximate autocompletion
# https://stackoverflow.com/questions/27012295/really-turn-off-zsh-autocorrect#27018690
zstyle ':completion*' completer _expand _complete

# advanced completions
autoload -Uz compinit && compinit
# load bashcompinit for some old bash completions
autoload bashcompinit && bashcompinit

# ==============================================================================
# Environment Variables
# ==============================================================================
# Point to Colima's docker socket
export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"

# Make neovim default editor
export VISUAL=nvim
export EDITOR="$VISUAL"

# See: https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# ==============================================================================
# PATH Modifications
# ==============================================================================
export PATH="/usr/local/bin:/usr/local/sbin:$HOME/.cargo/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin"

# Homebrew for silicon (cached)
export PATH="/opt/homebrew/bin:$PATH"
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}"
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

# makes homebrew gmake to just make
export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"
# krew kubectl plugin manager
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# vim fzf needs this
export PATH="$PATH:$HOME/.vim/pack/bundle/start/fzf/bin"

# LM Studio CLI (lms)
export PATH="$PATH:/Users/davidnix/.lmstudio/bin"

# ==============================================================================
# Tool Initialization (using cache where possible)
# ==============================================================================
# Mise version manager (formerly rtx)
# See: https://github.com/jdx/mise
eval "$(mise activate zsh)"

# kubectl completions (deferred)
zinit ice wait"1" lucid
zinit light-mode for \
  id-as"kubectl-completion" \
  as"completion" \
  atload"complete -F __start_kubectl k" \
  has"kubectl" \
  run-atpull \
  atclone"kubectl completion zsh > _kubectl" \
  atpull"%atclone" \
  pick"_kubectl" \
  zdharma-continuum/null

# direnv (if available)
if which direnv &> /dev/null; then
  eval "$(direnv hook $SHELL)"
fi

# ==============================================================================
# Custom Vim Keybindings
# ==============================================================================
# 1 - Enable vi keymaps
bindkey -v
# 2 - Let combos wait a bit longer (ms) for the second key
KEYTIMEOUT=100               # default is 40
# 3 - In the vi-insert map, send jk -> command mode (same as <Esc>)
bindkey -M viins 'jk' vi-cmd-mode

# ==============================================================================
# Aliases
# ==============================================================================
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

# ==============================================================================
# Google Cloud SDK
# ==============================================================================
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/davidnix/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/davidnix/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/davidnix/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/davidnix/google-cloud-sdk/completion.zsh.inc'; fi

# ==============================================================================
# Prompt and History Tools
# ==============================================================================
# starship.rs
if command -v starship &> /dev/null; then eval "$(starship init zsh)"; fi

# atuin shell history
eval "$(atuin init zsh --disable-up-arrow)"

# ==============================================================================
# Load Environment File
# ==============================================================================
source "$HOME/.envrc" || print -P "%F{yellow}%BFailed to source ~/.envrc%b%f"
