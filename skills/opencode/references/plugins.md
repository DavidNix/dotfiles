# OpenCode Plugins

Use this reference for plugins, hooks, custom tools, provider integrations, and runtime behavior that configuration alone cannot express.

## Choose The Smallest Mechanism

Use a plugin when the task needs to:

- Add a custom tool.
- Intercept or transform chat, command, tool, permission, or compaction behavior.
- Inject environment variables into tool execution.
- Integrate an external service or provider.

Do not create a plugin for a one-off shell command, a simple config setting, or project instructions that belong in `AGENTS.md`.

## Locations And Loading

Auto-discovered local plugins:

| Scope | Location |
|---|---|
| Project | `.opencode/plugin/*.ts`, `.opencode/plugin/*.js`, `.opencode/plugins/*.ts`, or `.opencode/plugins/*.js` |
| Global | `~/.config/opencode/plugin/*.ts`, `~/.config/opencode/plugin/*.js`, `~/.config/opencode/plugins/*.ts`, or `~/.config/opencode/plugins/*.js` |

Configured plugins use the singular `plugin` key:

```jsonc
{
  "plugin": [
    "opencode-package",
    "opencode-package@1.2.3",
    "./local-plugin.ts",
    ["opencode-package", { "option": "value" }]
  ]
}
```

Use a pinned package version when reproducibility matters. Local paths are relative to the config file that declares them.

## Minimal Plugin

```typescript
import type { Plugin } from "@opencode-ai/plugin"

export default (async ({ client, directory, $ }) => {
  return {
    "tool.execute.before": async (input, output) => {
      // Inspect input and mutate output.args in place.
    },
  }
}) satisfies Plugin
```

A plugin exports an async function and returns a hooks object. Return `{}` when there are no hooks to register. Do not export the hooks object directly.

The plugin input can provide the SDK client, project metadata, current directory, worktree, and Bun shell helper. Use only the values the plugin needs.

## Common Hooks

Stable hooks include:

- `event`
- `config`
- `chat.message`
- `chat.params`
- `chat.headers`
- `permission.ask`
- `command.execute.before`
- `tool.execute.before`
- `tool.execute.after`
- `tool.definition`
- `shell.env`

Experimental hooks include:

- `experimental.chat.messages.transform`
- `experimental.chat.system.transform`
- `experimental.provider.small_model`
- `experimental.session.compacting`
- `experimental.compaction.autocontinue`
- `experimental.text.complete`

Experimental hooks can change between OpenCode releases. Confirm their current signatures in the plugin API before using them.

Hook callbacks mutate the supplied output object and normally return `void`.

## Custom Tool

```typescript
import { type Plugin, tool } from "@opencode-ai/plugin"

export const CustomToolsPlugin: Plugin = async () => {
  return {
    tool: {
      lookup: tool({
        description: "Look up a record by ID",
        args: {
          id: tool.schema.string(),
        },
        async execute(args, context) {
          return `Looked up ${args.id} from ${context.directory}`
        },
      }),
    },
  }
}
```

Custom tools take precedence over built-in tools with the same name. Choose a distinct name unless overriding a built-in tool is deliberate and documented.

## Inject Environment Variables

```typescript
import type { Plugin } from "@opencode-ai/plugin"

export const EnvironmentPlugin: Plugin = async () => {
  return {
    "shell.env": async (input, output) => {
      output.env.PROJECT_ROOT = input.cwd
    },
  }
}
```

Never hard-code secrets in tracked plugin files. Read them from the process environment or use `{env:VAR}` in supported config fields.

## Modify Live Config

```typescript
import type { Plugin } from "@opencode-ai/plugin"

export const ConfigPlugin: Plugin = async () => {
  return {
    config: async (config) => {
      config.instructions ??= []
      config.instructions.push("Follow the repository instructions.")
    },
  }
}
```

Prefer static `opencode.jsonc` settings when they can express the same behavior. Runtime config mutation is harder to inspect and debug.

## Dependencies

Place plugin dependencies in `package.json` in the relevant config directory, not inside the plugin directory:

```json
{
  "dependencies": {
    "@opencode-ai/plugin": "1.2.3"
  }
}
```

OpenCode runs Bun install at startup. Follow the repository's dependency pinning policy when one exists.

## Validation

Use the narrowest checks supported by the repository:

- JavaScript syntax: `node --check path/to/plugin.js`
- Node tests: `node --test path/to/plugin.test.js`
- TypeScript: the repository's type-check command
- Effective config: `opencode debug config`

Also inspect the diff and restart OpenCode. A running session will not reload config-time plugin changes.

## Common Mistakes

| Mistake | Correction |
|---|---|
| Using `plugins` in config | Use singular `plugin` with an array value. |
| Exporting a plain hooks object | Export an async plugin function that returns hooks. |
| Guessing a hook signature | Check the current `@opencode-ai/plugin` type or official docs. |
| Putting dependencies under `plugins/` | Put `package.json` in the config directory. |
| Logging with unstructured `console.log` | Prefer `client.app.log` when logs should appear in OpenCode diagnostics. |
| Overriding a built-in tool accidentally | Use a unique custom tool name. |
| Expecting hot reload | Restart OpenCode after plugin changes. |

## Sources

- Plugin docs: <https://opencode.ai/docs/plugins/>
- SDK docs: <https://opencode.ai/docs/sdk/>
- Plugin types: `@opencode-ai/plugin`
