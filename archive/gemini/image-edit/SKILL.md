---
name: image-edit
description: Use when editing, modifying, or transforming existing image files with AI using the local Gemini image-edit CLI. Trigger this for style changes, object removal, background edits, text/layout fixes, color tweaks, or when the user says to use image-edit from the terminal. This skill runs the global `image-edit` executable from any repo.
---

# Image Editing (Gemini)

Edit existing images with text instructions using Google Gemini via the global `image-edit` CLI.

## Command

Run from any directory:

```bash
image-edit <file> "edit instructions" [options]
```

Use two positional arguments in order: file path, then prompt.

The exact image file path is required. If the user did not provide one, ask before running. Do not guess or assume a filename. Always resolve to an absolute path before passing it to the command.

## Requirements

The CLI uses `GEMINI_API_KEY` if it is set. If not, it automatically reads the key from macOS Keychain item `gemini-api-key` for account `$USER`.

Add the key to Keychain with:

```bash
security add-generic-password -U -a "$USER" -s gemini-api-key -w "YOUR_GEMINI_API_KEY"
```

If neither source exists, the CLI prints these setup instructions and exits.

## Options

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--output-dir` | `-o` | `.` | Output directory |
| `--aspect-ratio` | `-a` | `1:1` | Aspect ratio |
| `--resolution` | `-r` | `1K` | Resolution |
| `--width` | | None | Target width for resize |
| `--height` | | None | Target height for resize |

## Valid Aspect Ratios

`1:1`, `2:3`, `3:2`, `3:4`, `4:3`, `4:5`, `5:4`, `9:16`, `16:9`, `21:9`

## Valid Resolutions

`1K`, `2K`, `4K`

These are named tiers, not pixel dimensions.

## Resize

Pass both `--width` and `--height` together to resize the output. Both are required for resize to take effect.

## Examples

```bash
# Basic edit
image-edit /absolute/path/to/photo.png "remove the background"

# Edit with options
image-edit /absolute/path/to/input.jpg "make it look like a watercolor painting" -a 3:4 -r 4K -o output

# Edit with resize
image-edit /absolute/path/to/headshot.png "add a professional background" -r 2K --width 800 --height 800 -o output
```

## After Running

The command outputs a timestamp filename, such as `2026-02-14T10-30-45.png`. Rename it to something descriptive based on the task, such as `headshot-no-background.png`.

## Common Mistakes

- Reversing argument order. Use file path first, prompt second.
- Passing a relative path when the current directory is uncertain. Prefer an absolute path.
- Using pixel dimensions like `1024x1024` for resolution. Use `1K`, `2K`, or `4K`.
- Running repo-local image commands from another project.
- Forgetting that `--width` and `--height` must both be provided.
