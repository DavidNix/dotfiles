---
name: image-edit
description: Use when editing, modifying, or transforming existing image files with AI using the OpenAI CLI. Trigger this for style changes, object removal, background edits, text/layout fixes, color tweaks, or when the user says to use image-edit from the terminal. This skill runs the `openai images edit` command from any repo.
---

# Image Editing (OpenAI)

Edit existing images with text instructions using the official OpenAI CLI.

## Command

Run from any directory:

```bash
openai images edit --image /path/to/photo.png --prompt "edit instructions" [options]
```

Both `--image` and `--prompt` are flags. The original file is never modified.

The exact image file path is required. If the user did not provide one, ask
before running. Do not guess or assume a filename. Always resolve to an
absolute path before passing it to the command.

## Requirements

The CLI reads `OPENAI_API_KEY` from the environment. This dotfiles setup
exports it on every shell start from the macOS Keychain item `openai-api-key`
for account `$USER`.

Add the key to Keychain with:

```bash
security add-generic-password -U -a "$USER" -s openai-api-key -w "YOUR_OPENAI_API_KEY"
```

If the key is not set, the CLI prints setup instructions and exits.

## Options

| Flag | Default | Description |
|------|---------|-------------|
| `--image` | Required | Image file to edit (png, webp, or jpg under 50MB). Repeatable, up to 16 images |
| `--model` | `gpt-image-1.5` | Image model. Run `openai images models` to list exact names visible to your key |
| `--input-fidelity` | `low` | `high` preserves the input's style and facial features |
| `--mask` | None | PNG whose transparent areas select the region to edit; same dimensions as the first image |
| `--size` | `auto` | `1024x1024`, `1536x1024`, `1024x1536`, or arbitrary `WIDTHxHEIGHT` |
| `--quality` | `auto` | `low`, `medium`, `high` (plus `xhigh`, `max` on 2.5 models) |
| `--output-format` | `png` | `png`, `jpeg`, or `webp` |
| `--output-dir` | `~/Downloads/gpt-images/` | Existing directory to save into |
| `--name` | Timestamp | Filename stem (extension optional); duplicates get `-2`, `-3`, etc. |

## Size Rules

- Standard sizes: `1024x1024`, `1536x1024` (landscape), `1024x1536` (portrait).
- Arbitrary sizes: width and height must both be divisible by 16, aspect ratio
  between 1:3 and 3:1, maximum `3840x2160`.

There are no named resolution tiers (`1K`, `2K`). Do not use them.

## Examples

```bash
# Basic edit
openai images edit --image /absolute/path/to/photo.png --prompt "remove the background"

# Style transfer while preserving the subject's face
openai images edit --image /absolute/path/to/input.jpg \
  --prompt "make it look like a watercolor painting" \
  --input-fidelity high --name watercolor-portrait --output-dir output

# Masked edit
openai images edit --image /absolute/path/to/headshot.png \
  --mask /absolute/path/to/mask.png \
  --prompt "add a professional background" --name headshot-pro --output-dir output
```

## After Running

The command prints the saved file path, under `~/Downloads/gpt-images/` by
default. If no `--name` was given, rename the file to something descriptive
based on the task, such as `headshot-no-background.png`.

## Common Mistakes

- Passing file or prompt as positional arguments. Use `--image` and `--prompt`.
- Passing a relative path when the current directory is uncertain. Prefer an
  absolute path.
- Using named resolution tiers like `1K` or `2K`. Use pixel sizes instead.
- Expecting the input file to be modified. The edited copy is written to the
  output directory; the original is kept.
- Passing a non-existent `--output-dir`. The directory must already exist.
