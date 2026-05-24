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
make vet       # Run all lint, type, and syntax checks
make bash-check FILE=bin/script # Validate a bash script
```

## Key Files

| File | Purpose |
|------|---------|
| `Makefile` | Installation, linking, macOS defaults |
| `Brewfile` | Homebrew packages |
| `.zshrc` | Shell config (plugins, aliases, vi-mode) |
| `.cursor/rules/` | Cursor editor rules |
| `claude/` | Claude Code settings, skills, agents |
| `.config/zed/` | Zed editor config |
| `.config/nvim/` | Neovim config (LazyVim) |
| `bin/agent-init` | Claude Code skills/plugin installer |

Read these files directly for details.

## Workflow

**Add dotfiles:** Add file to repo, run `make relink`, commit.

**Update packages:** Edit `Brewfile`, run `make pkgs`, commit.

**Shell changes:** Edit `.zshrc`, reload with `source ~/.zshrc`.

**Script changes:** After modifying any script, run `make vet`. For a single bash/zsh script, `make bash-check FILE=<file>` is available, but `make vet` is required before considering script work complete.

**New scripts:** When adding a new script, add it to the appropriate script list in `Makefile` (`SHELL_SCRIPTS` or `PYTHON_SCRIPTS`) so `make vet` checks it.

**Python dependencies:** Always pin Python package versions exactly in `pyproject.toml` and PEP 723 inline script metadata (use `==`, not `>=`) to reduce supply chain risk. Run `uv lock` after changing Python dependencies.

## Agent Skills/Plugin Maintenance

Custom skills live in `skills` and are installed with https://github.com/vercel-labs/skills. E.g. `npx skills add -g ./skills/` 

When adding, removing, or updating skills, update `bin/agent-init` to match.
