---
name: image-gen
description: Use when generating image files from text prompts with the local Gemini image CLI. Trigger this when the user asks to create, generate, or render an AI image, artwork, ad image, book cover, mockup, visual asset, or says to use image-gen from the terminal. This skill runs the global `image-gen` executable from any repo.
---

# Image Generation (Gemini)

Generate images from text prompts using Google Gemini via the global `image-gen` CLI.

## Command

Run from any directory:

```bash
image-gen "your prompt here" [options]
```

Prompt is a positional argument, not a flag.

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

These are named tiers, not pixel dimensions. Do not use `1024x1024` or similar.

## Resize

Pass both `--width` and `--height` together to resize the output. Both are required for resize to take effect.

## Examples

```bash
# Basic generation
image-gen "a golden retriever puppy in autumn leaves"

# Widescreen, highest resolution, saved to output/
image-gen "mountain landscape at sunset" -a 16:9 -r 4K -o output

# Portrait with resize
image-gen "fashion portrait" -a 3:4 -r 2K --width 900 --height 1200
```

## After Running

The command outputs a timestamp filename, such as `2026-02-14T10-30-45.png`. Rename it to something descriptive based on the prompt, such as `golden-retriever-autumn.png`.

## Common Mistakes

- Using `--prompt` instead of a positional argument.
- Using pixel dimensions like `1024x1024` for resolution. Use `1K`, `2K`, or `4K`.
- Running repo-local image commands from another project.
- Forgetting that `--width` and `--height` must both be provided.
