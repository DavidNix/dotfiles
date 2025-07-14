#!/bin/sh

# Dotfiles

DFILES_DIR=~/src/dotfiles

tmux new-session -c"$DFILES_DIR" -d -s $(basename "$DFILES_DIR")

tmux rename-window "main"

tmux split-window -h

tmux select-pane -t 0

# Work

WORK_DIR=~/src/metarouter/roost

tmux new-session -c "$WORK_DIR" -d -s $(basename "$WORK_DIR")

tmux rename-window "main"

tmux split-window -c "$WORK_DIR" -h

tmux select-pane -t 0

# Side project

YND_DIR=~/src/your-next-domain

tmux new-session -c "$YND_DIR" -d -s $(basename "$YND_DIR")

tmux rename-window "main"

tmux split-window -c "$YND_DIR" -v -p 10

tmux select-pane -t 0

# Attach

tmux attach -t $(basename "$DFILES_DIR")
