---
name: opencode
description: Use when creating, editing, debugging, or reviewing OpenCode configuration and extensions. Trigger whenever the user mentions opencode.json, opencode.jsonc, OpenCode models or providers, agents, commands, skills, permissions, MCP servers, plugins, hooks, custom tools, or changing default OpenCode behavior.
compatibility: Requires the opencode CLI for model discovery and config validation.
---

# OpenCode

Configure and extend OpenCode without guessing strict config shapes or model identifiers.

## Route The Request

Read only the reference needed for the task:

| Request | Reference |
|---|---|
| Config, models, providers, permissions, MCP, agents, commands, or skills | `references/config.md` |
| Plugins, hooks, custom tools, or runtime extensions | `references/plugins.md` |

Read both references only when the task crosses both areas.

## Workflow

1. Determine the target scope. Use the path the user supplied; otherwise ask whether the change is project-local or global.
2. Read the existing file before proposing or applying changes. Preserve fields the user did not ask to change.
3. For every model change, run `opencode models` from the target project and select an exact `provider/model-id` from its output.
4. Check `https://opencode.ai/config.json` when a field or shape is uncertain. The schema is authoritative because invalid config can prevent OpenCode from starting.
5. Make the smallest correct change. Prefer dedicated agent, command, skill, and plugin files over large inline definitions.
6. Validate config with `opencode debug config`. Validate plugin syntax and repository-specific tests when plugin code changes.
7. Tell the user to restart OpenCode after config-time files change; running sessions do not hot-reload them.

## Model Discovery

`opencode models` is the source of truth for model IDs available to the user's current setup.

```bash
opencode models
```

- Never invent a provider prefix, model name, or suffix from memory or documentation.
- Match the user's wording against the model-id component. An exact component match takes precedence over suffixed variants.
- If no exact match exists and several entries are plausible, ask which model they want.
- Use the selected ID unchanged in `model`, `small_model`, agent, or command configuration.

Example: if the command prints `openai/gpt-5.6-luna`, configure exactly:

```jsonc
"model": "openai/gpt-5.6-luna"
```

## Sources Of Truth

- Config schema: <https://opencode.ai/config.json>
- Configuration docs: <https://opencode.ai/docs/config/>
- Plugin docs: <https://opencode.ai/docs/plugins/>
- SDK docs: <https://opencode.ai/docs/sdk/>

When this skill conflicts with the current schema or CLI output, follow the schema and CLI.
