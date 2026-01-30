# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Overview

Personal dotfiles repository. Uses symlinks (not chezmoi) so edits in `~/` immediately reflect here.

## Commands

```bash
make help      # Show all commands
make relink    # Symlink dotfiles to ~/
make setup     # Full new Mac setup (NOT idempotent)
make defaults  # Apply macOS preferences (requires reboot)
make pkgs      # Install Homebrew packages
```

## Key Files

| File | Purpose |
|------|---------|
| `Makefile` | Installation, linking, macOS defaults |
| `Brewfile` | Homebrew packages |
| `.zshrc` | Shell config (plugins, aliases, vi-mode) |
| `.cursor/rules/` | Cursor editor rules |
| `.claude/` | Claude Code settings |
| `.config/zed/` | Zed editor config |
| `.config/nvim/` | Neovim config (LazyVim) |
| `bin/agent-init` | Claude Code skills/plugin installer |

Read these files directly for details.

## Workflow

**Add dotfiles:** Add file to repo, run `make relink`, commit.

**Update packages:** Edit `Brewfile`, run `make pkgs`, commit.

**Shell changes:** Edit `.zshrc`, reload with `source ~/.zshrc`.

## Agent Skills/Plugin Maintenance

When adding, removing, or updating Claude Code skills or plugins, update `bin/agent-init` to match. This script installs skills (via `npx skills`) and plugins on new machines and must stay in sync.
