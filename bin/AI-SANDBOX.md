# AI Sandbox for Apple Container

An attempt to mimic [Docker's AI Sandbox](https://docs.docker.com/ai/sandboxes/) using [Apple Container](https://github.com/apple/container) for running AI agents in isolated environments on Apple Silicon Macs.

## Goal

Run AI coding agents (starting with Claude Code) in an isolated container with:
- Project directory mounted at the same absolute path as host
- Git identity injected
- Claude authentication persisted
- Bypass permissions mode (`--dangerously-skip-permissions`)

## Files Created

### `bin/ai-sandbox`
Main launcher script that:
- Builds the container image if it doesn't exist
- Mounts project directory at same absolute path
- Mounts `~/.claude` (read-write) for auth/plugins/settings
- Sets `HOME` to `/home/sandbox` and uses XDG dirs inside the container
- Forwards SSH agent via `--ssh`
- Injects Git identity via environment variables

### `bin/Dockerfile.ai-sandbox`
Ubuntu 24.04 based image with:
- Node.js 22 LTS
- Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)
- mise (installed to `/usr/local/bin/mise`)
- Dev tools: git, zsh, vim, ripgrep, fd, fzf, jq, build-essential
- Non-root `sandbox` user

## Commands

```bash
ai-sandbox claude    # Run Claude Code
ai-sandbox shell     # Open interactive shell
ai-sandbox build     # Rebuild the image
ai-sandbox delete    # Remove sandbox for current directory
```

## Key Design Decisions

### Directory Mounting
- Project dir mounted at same absolute path (e.g., `/Users/davidnix/src/project`)
- This matches Docker sandbox behavior for familiar error messages and hardcoded paths

### Home Directory
- Set `HOME=/home/sandbox` (container home) via env var
- Container user is `sandbox` with home at `/home/sandbox`
- XDG dirs point inside the container:
  - `XDG_CONFIG_HOME=/home/sandbox/.config`
  - `XDG_CACHE_HOME=/home/sandbox/.cache`
  - `XDG_DATA_HOME=/home/sandbox/.local/share`
- Other writable tool dirs:
  - `MISE_DATA_DIR=/home/sandbox/.local/share/mise`
  - `MISE_STATE_DIR=/home/sandbox/.local/state/mise`
  - `MISE_CACHE_DIR=/home/sandbox/.cache/mise`
  - `GNUPGHOME=/home/sandbox/.gnupg`

### Git Identity
- Mounted `~/.gitconfig` initially, but Apple Container only mounts directories (not files)
- Switched to environment variables: `GIT_AUTHOR_NAME`, `GIT_COMMITTER_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_EMAIL`

### Read-only Mounts
- Apple Container uses `--mount source=...,target=...,readonly` syntax
- Docker-style `:ro` suffix doesn't work

## Current Issue: Claude Hangs

### Symptom
- `ai-sandbox shell` works - interactive shell comes up
- `ai-sandbox claude` hangs indefinitely - no output, no error
- Running `claude --dangerously-skip-permissions` from inside the shell also hangs
- `claude --version` and `claude -h` work fine

### Debugging Steps Taken

1. **TTY flags**: Changed `-it` to `--interactive --tty` - no change

2. **zsh wrapper**: Initially used `zsh -c "claude ..."` which didn't pass TTY properly
   - Tried `zsh -ic` (interactive)
   - Removed wrapper entirely, running claude directly - still hangs

3. **Readonly mount**: `~/.claude` was mounted readonly
   - Changed to read-write - still hangs
   - Reverted to readonly

4. **mise integration**: Temporarily commented out all mise-related code to simplify

5. **Verbose logging**: To try next:
   ```bash
   claude --dangerously-skip-permissions --verbose
   # or
   CLAUDE_DEBUG=1 claude --dangerously-skip-permissions
   ```

### Theories

1. **Authentication**: Claude might be waiting for authentication in a way that doesn't work in the container
2. **stdin handling**: Claude might be reading stdin in a way that blocks
3. **Network**: Claude might be trying to connect to something that times out silently
4. **Missing dependency**: Some system library or service Claude needs

### Next Steps to Try

1. Run with verbose/debug logging
2. Check if `claude -p "test" --dangerously-skip-permissions` (non-interactive) works
3. Strace/trace the claude process to see what it's blocking on
4. Compare with Docker sandbox to see what they do differently
5. Check Claude Code source/docs for container requirements

## Apple Container Quirks Discovered

1. **Only mounts directories**: Can't bind mount individual files like `.gitconfig`
2. **Mount syntax**: Uses `--mount source=...,target=...,readonly` not `-v path:path:ro`
3. **Volumes**: Named volumes supported with `container volume create/delete`
4. **Networking**: Enabled by default, no explicit configuration needed
