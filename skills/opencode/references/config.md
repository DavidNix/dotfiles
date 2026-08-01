# OpenCode Configuration

Use this reference for config files, model selection, providers, permissions, MCP servers, agents, commands, skills, and troubleshooting.

## Locations And Loading

| Scope | Path |
|---|---|
| Project config | `./opencode.json`, `./opencode.jsonc`, or `.opencode/opencode.json` |
| Global config | `~/.config/opencode/opencode.json` or `~/.config/opencode/opencode.jsonc` |
| Project agents | `.opencode/agent/<name>.md` or `.opencode/agents/<name>.md` |
| Global agents | `~/.config/opencode/agent/<name>.md` or `~/.config/opencode/agents/<name>.md` |
| Project commands | `.opencode/command/<name>.md` or `.opencode/commands/<name>.md` |
| Global commands | `~/.config/opencode/command/<name>.md` or `~/.config/opencode/commands/<name>.md` |
| Project skills | `.opencode/skill/<name>/SKILL.md` or `.opencode/skills/<name>/SKILL.md` |
| Global skills | `~/.config/opencode/skill/<name>/SKILL.md` or `~/.config/opencode/skills/<name>/SKILL.md` |

OpenCode supports JSON and JSONC. Config scopes are deep-merged, with project values overriding global values. Keep this declaration in each config so editors and agents can validate it:

```jsonc
{
  "$schema": "https://opencode.ai/config.json"
}
```

## Safe Edit Workflow

1. Use the path named by the user. Ask project or global only when no scope is clear.
2. Read the current file and identify the smallest affected object.
3. For model changes, run `opencode models` in the target project before editing.
4. Fetch `https://opencode.ai/config.json` when an exact field shape is not covered here.
5. Preserve comments, trailing-comma style, and unrelated settings.
6. Run `opencode debug config` and confirm the resolved value.
7. Restart OpenCode after saving.

## Models

Model values always use an exact `provider/model-id` returned by:

```bash
opencode models
```

Do not derive IDs from display names or assume a provider. The same model family may appear under several providers or variants.

```jsonc
{
  "model": "openai/gpt-5.6-sol-fast",
  "small_model": "openai/gpt-5.6-luna",
  "agent": {
    "explore": {
      "model": "openai/gpt-5.6-luna"
    }
  }
}
```

After editing, inspect the effective value rather than only checking syntax:

```bash
opencode debug config
```

## Common Config Shapes

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "model": "provider/model-id",
  "small_model": "provider/model-id",
  "default_agent": "plan",
  "share": "disabled",
  "autoupdate": "notify",
  "agent": {},
  "command": {},
  "provider": {},
  "mcp": {},
  "permission": {},
  "plugin": []
}
```

Important shapes:

- `agent`, `command`, `provider`, `mcp`, and `permission` are objects.
- `plugin` is singular and contains an array of npm specs, local paths, or `[spec, options]` tuples.
- `model` and `small_model` include a provider prefix.
- `mcp.<name>.command` is an array of strings for local servers.
- `autoupdate` accepts a boolean or `"notify"`.
- `share` accepts `"manual"`, `"auto"`, or `"disabled"`.

## Agents

Override a built-in agent inline for small changes:

```jsonc
{
  "agent": {
    "explore": {
      "model": "provider/model-id",
      "permission": {
        "task": "deny"
      }
    }
  }
}
```

Use a file for a non-trivial agent:

```markdown
---
description: Reviews changes for correctness.
mode: subagent
model: provider/model-id
permission:
  edit: deny
---

Review the requested changes and report findings with file references.
```

The file body is the prompt. Do not also add a `prompt` key to its frontmatter. Agent modes are `primary`, `subagent`, and `all`. Built-in agents include `build`, `plan`, `general`, and `explore`.

## Commands

Store non-trivial commands in `.opencode/command/<name>.md` or its global equivalent:

```markdown
---
description: Review a requested range.
agent: plan
---

Review $ARGUMENTS and report findings.
```

The body becomes the command template. `$ARGUMENTS` contains all input; `$1`, `$2`, and later variables contain positional arguments.

## Permissions

Actions are `allow`, `ask`, and `deny`.

```jsonc
{
  "permission": {
    "read": {
      "*": "allow",
      "*.env": "deny",
      "*.env.example": "allow"
    },
    "bash": {
      "*": "ask",
      "git *": "allow",
      "git push *": "deny"
    },
    "edit": "allow",
    "webfetch": "ask"
  }
}
```

Within a permission object, insertion order matters and the last matching rule wins. Put broad patterns first and narrow exceptions later. Per-agent permissions override top-level permissions.

Avoid top-level `"permission": "allow"` unless the user explicitly wants every tool allowed.

## MCP Servers

Local server:

```jsonc
{
  "mcp": {
    "browser": {
      "type": "local",
      "command": ["npx", "-y", "browser-mcp"],
      "enabled": true,
      "environment": {
        "TOKEN": "{env:BROWSER_TOKEN}"
      }
    }
  }
}
```

Remote server:

```jsonc
{
  "mcp": {
    "docs": {
      "type": "remote",
      "url": "https://example.com/mcp",
      "enabled": true,
      "headers": {
        "Authorization": "Bearer {env:DOCS_TOKEN}"
      }
    }
  }
}
```

Use `{env:VAR}` for secrets. Do not place credentials directly in tracked config.

## Skills And References

Register non-default skill locations with an object, not an array:

```jsonc
{
  "skills": {
    "paths": [".opencode/skills", "/absolute/path/to/skills"],
    "urls": ["https://example.com/.well-known/skills/"]
  }
}
```

Reference local or Git-hosted supporting context by alias:

```jsonc
{
  "references": {
    "docs": {
      "path": "../docs",
      "description": "Product behavior and terminology"
    },
    "sdk": {
      "repository": "owner/sdk",
      "branch": "main",
      "description": "SDK implementation details"
    }
  }
}
```

## Recovery And Validation

If invalid project config prevents startup, temporarily skip it:

```bash
OPENCODE_DISABLE_PROJECT_CONFIG=1 opencode
```

Other recovery variables:

- `OPENCODE_CONFIG=/path/to/file.json` loads an explicit config.
- `OPENCODE_CONFIG_CONTENT='{"$schema":"https://opencode.ai/config.json"}'` injects config content.
- `OPENCODE_DISABLE_DEFAULT_PLUGINS=1` skips default plugins.
- `OPENCODE_PURE=1` skips external plugins.

Before finishing:

- Run `opencode debug config` successfully.
- Confirm changed model IDs occur in `opencode models` output.
- Check that unrelated config remains unchanged.
- Restart OpenCode so config-time changes take effect.
