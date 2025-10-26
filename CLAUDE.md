# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that manages shell configurations, editor settings, and macOS system preferences using symlinks. The repository uses a Makefile-based approach for installation and management, avoiding the complexity of tools like chezmoi in favor of direct symlinks that allow immediate changes.

## Common Commands

### Setup and Installation
```bash
make help              # Show all available make commands
make relink            # Create/update symbolic links for dotfiles to home directory
make setup             # Full setup for a new Mac (NOT idempotent)
make defaults          # Apply macOS system preferences (requires reboot)
```

### Package Management
```bash
make cli-apps          # Install command line tools via Homebrew
make krew              # Install kubectl krew plugins
```

## Architecture

### Symlink-Based Configuration Management

The core philosophy is to use symlinks instead of copying files, enabling direct editing without intermediary commands:

- Dotfiles (`.bash_profile`, `.zshrc`, `.gitconfig`, etc.) are symlinked from this repo to `~/`
- `.config/*` directories are symlinked to `~/.config/`
- Editor configurations (Cursor, Claude, Zed, Neovim) are symlinked to their respective locations
- Changes made to files in `~/` are immediately reflected in this repository

### Key Configuration Files

- **Makefile**: Primary orchestration for installation, linking, and macOS defaults
- **Brewfile**: Homebrew package manifest for CLI tools and casks
- **.zshrc**: Shell configuration with zplug plugin management, vi-mode keybindings, and tool aliases
- **.cursor/rules/**: Language-specific coding rules for Cursor editor (Go, Templ, HTMX, global)
- **.claude/**: Claude Code settings and custom commands
- **.config/zed/**: Zed editor configuration including tasks, keymaps, and prompts
- **.config/nvim/**: Neovim configuration (LazyVim-based)

### Editor Configurations

### Shell Environment

The `.zshrc` configures:
- **Plugin manager**: zplug for zsh plugins
- **Version manager**: mise (asdf replacement) for language runtimes
- **Package manager**: Homebrew (Apple Silicon optimized)
- **Editor**: Neovim as default ($VISUAL, $EDITOR)
- **Prompt**: Starship.rs
- **History**: Atuin for advanced shell history
- **Vi-mode**: Custom keybindings with `jk` to exit insert mode
- **Aliases**: Modern CLI tools (bat, lsd, ripgrep, etc.)

### macOS System Preferences

The `make defaults` target applies extensive macOS customizations:
- Finder preferences (show extensions, column view, no .DS_Store on network)
- Dock settings (size, autohide, Mission Control animations)
- Keyboard settings (fast repeat rate, full keyboard access)
- Safari developer tools
- Energy management
- Screenshot location and format

## Development Workflow

### Adding New Dotfiles
1. Add the file to this repository
2. Run `make relink` to create the symlink
3. Commit and push changes

### Updating Homebrew Packages
1. Edit `Brewfile` to add/remove packages
2. Run `make cli-apps` to install
3. Commit changes to Brewfile and Brewfile.lock.json

### Shell Configuration Changes
Changes to `.zshrc` or other shell files are immediately active in this repo. Reload with `source ~/.zshrc` or open a new shell.
