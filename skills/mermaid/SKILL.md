---
name: mermaid
description: Use when the user asks to create or render a Mermaid or Merman chart, mentions merman-cli, or wants an ASCII terminal diagram. Render it with `merman-cli`.
compatibility: Requires `merman-cli`, installed with Homebrew formula `merman-cli`.
---

# Mermaid ASCII Rendering

Render Mermaid diagrams as terminal-safe text with `merman-cli`.

Rendering a chart as response output is allowed in plan mode because it does not modify project files.

## Workflow

1. Use Mermaid source supplied by the user or create concise Mermaid source from their description.
2. Render inline source through stdin unless an input file already exists or the user wants to save the result.
3. Run `merman-cli`; do not draw or approximate the rendered chart manually.
4. Default to strict ASCII. Use Unicode only when the user explicitly requests it.
5. Return the rendered output in a fenced `text` block. Include the Mermaid source only when requested or useful for fixing it later.

## Commands

Prefer rendering inline source through stdin:

```bash
merman-cli render --format ascii - <<'EOF'
flowchart LR
  A[Request] --> B{Valid?}
  B -->|Yes| C[Process]
  B -->|No| D[Reject]
EOF
```

Render an existing Mermaid file:

```bash
merman-cli render --format ascii path/to/diagram.mmd
```

Save the result when the user asks for a file:

```bash
merman-cli render --format ascii --output path/to/diagram.txt path/to/diagram.mmd
```

For Unicode box-drawing characters, replace `ascii` with `unicode`.

## Errors

- If parsing fails, correct generated Mermaid syntax and rerun the command.
- If user-supplied source fails, report the exact error and suggest the smallest correction.
- ASCII and Unicode rendering support flowcharts, sequence diagrams, class diagrams, ER diagrams, and XY charts. If another diagram type is unsupported, explain the limitation rather than inventing output.
