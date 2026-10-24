---
name: image-gen
description: Use when generating image files from text prompts with the OpenAI CLI. Trigger this when the user asks to create, generate, or render an AI image, artwork, ad image, book cover, mockup, visual asset, or says to use image-gen from the terminal. This skill runs the `openai images generate` command from any repo.
---

# Image Generation (OpenAI)

Generate images from text prompts using the official OpenAI CLI.

## Command

Run from any directory:

```bash
openai images generate --prompt "your prompt here" [options]
```

Prompt is a flag (`--prompt`), not a positional argument.

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
| `--model` | `gpt-image-2.5-sunburst` | Image model. Run `openai images models` to list exact names visible to your key |
| `--size` | `auto` | `1024x1024`, `1536x1024`, `1024x1536`, or arbitrary `WIDTHxHEIGHT` |
| `--quality` | `auto` | `low`, `medium`, `high` (plus `xhigh`, `max` on 2.5 models) |
| `--output-format` | `png` | `png`, `jpeg`, or `webp` |
| `--background` | `auto` | `auto`, `opaque`, or `transparent` (transparent requires png or webp) |
| `--count` | `1` | Number of images, 1–10 |
| `--output-dir` | `~/Downloads/gpt-images/` | Existing directory to save into |
| `--name` | Timestamp | Filename stem (extension optional); duplicates get `-2`, `-3`, etc. |

## Size Rules

- Standard sizes: `1024x1024`, `1536x1024` (landscape), `1024x1536` (portrait).
- Arbitrary sizes: width and height must both be divisible by 16, aspect ratio
  between 1:3 and 3:1, maximum `3840x2160`.

There are no named resolution tiers (`1K`, `2K`). Do not use them.

## Examples

```bash
# Basic generation
openai images generate --prompt "a golden retriever puppy in autumn leaves"

# Widescreen, highest quality, named file in output/
openai images generate --prompt "mountain landscape at sunset" \
  --size 1536x1024 --quality high --name mountain-sunset --output-dir output

# Transparent background, webp
openai images generate --prompt "minimal robot mascot sticker" \
  --background transparent --output-format webp --name robot-sticker
```

## After Running

The command prints the saved file path, under `~/Downloads/gpt-images/` by
default. If no `--name` was given, rename the file to something descriptive
based on the prompt, such as `golden-retriever-autumn.png`.

## Common Mistakes

- Passing the prompt as a positional argument. Use `--prompt`.
- Using named resolution tiers like `1K` or `2K`. Use pixel sizes instead.
- Using an arbitrary size whose sides are not divisible by 16.
- Using `--background transparent` with jpeg output. Use png or webp.
- Passing a non-existent `--output-dir`. The directory must already exist.
