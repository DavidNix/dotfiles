#!/usr/bin/env bash

set -e

echo "Generating links.."
find $PWD -name ".[^.]*" -type f -print0 | xargs -0tJ % ln -sf %  ~

# Vim setup
mkdir -p ~/.vim
ln -sf $PWD/.vim/.vimrc ~/.vim/.vimrc
mkdir -p ~/.config/nvim
ln -sf $PWD/.config/nvim/init.vim ~/.config/nvim/init.vim

echo "Complete!"
