# Neovim for code review

Requires Neovim 0.12+, Git, and the tools in the root `Brewfile`. Run `make pkgs`
from the repository root to install them. Neovim installs seven plugins through
its built-in `vim.pack` manager on first launch. Keep `nvim-pack-lock.json` tracked.

Tree-sitter installs the parser list in `init.lua` when its plugin is first
installed, and updates those parsers when the plugin updates. This needs
`tree-sitter-cli` and the Xcode command-line tools. Run `:TSInstallConfigured` to
retry installation or install newly added parsers. Ordinary file opening never
downloads parsers. Large files skip Tree-sitter highlighting and folding.

## Navigation

The leader is **Space**. Herdr owns **Ctrl+h/j/k/l**; use **Ctrl+w**, then
**h/j/k/l** inside Neovim, including diff splits.

| Key | Action |
| --- | --- |
| `Space Space`, `Space sf` | Find files |
| `Space sg` | Search project text |
| `Space sw` | Search word under cursor |
| `Space sb` | Find open buffers |
| `Space s.` | Recent files |
| `Space sr` | Resume last search |
| `Space /` | Search current buffer |
| `Space e`, `Ctrl+n` | Browse directory with netrw |
| `gd`, `grd` | Go to definition |
| `grr`, `gri`, `grt` | References, implementations, type definition |
| `gO`, `gW` | Document / workspace symbols |
| `K` | Documentation |
| `Ctrl+o`, `Ctrl+i` | Back / forward through jumps |
| `an`, `in` in Visual mode | Expand / shrink structural selection |
| `za`, `zc`, `zo` | Toggle / close / open a fold (files start unfolded) |
| `Space sk` | Search keybindings |

## Git review

| Key | Action |
| --- | --- |
| `Space gg` | Changed-file picker with diff previews |
| `Space gh` | Git hunk picker |
| `]c`, `[c` | Next / previous change; native navigation in diff windows |
| `Space gp`, `Space gi` | Popup / inline hunk preview |
| `Space gd` | Diff current buffer against the index |
| `Space gD` | Diff current buffer against HEAD (staged + unstaged edits) |
| `Space gb` | Blame current line |

The root `.gitconfig` integrates Neovim's native directory diff viewer:

```sh
git difftool --dir-diff                 # Unstaged changes
git difftool --dir-diff --cached        # Staged changes
git difftool --dir-diff main...HEAD     # Branch changes; replace main with the target branch
```

Use the changed-file list to select a comparison. Open working-tree files for
project-wide LSP navigation; Git's temporary revision files lack project context.

## Language servers

Servers start for matching filetypes and roots. Run `:checkhealth vim.lsp` to
check attachment and executables; use `:lsp restart` after changing environments.

| Files | Server | Homebrew formula |
| --- | --- | --- |
| Go | `gopls` | `gopls` |
| Python | `pyright` | `pyright` |
| JavaScript / TypeScript | `tsc` | `typescript` (7+) |
| Lua | `lua_ls` | `lua-language-server` |
| CSS / SCSS / Less | `cssls` | `vscode-langservers-extracted` |
| HTML | `html` | `vscode-langservers-extracted` |
| JSON / JSONC | `jsonls` | `vscode-langservers-extracted` |
| Terraform | `terraformls` | `terraform-ls` |
| Ansible | `ansiblels` | `ansible-language-server` |
| Rust | `rust_analyzer` | `rust-analyzer` |
| Bash / sh | `bashls` | `bash-language-server` |
| YAML | `yamlls` | `yaml-language-server` |
| TOML | `taplo` | `taplo` |
| Dockerfile | `dockerls` | `dockerfile-language-server` |

- Python prefers the project-root `.venv`, then the active `VIRTUAL_ENV`.
- JavaScript/TypeScript uses TypeScript 7's native LSP. Older project-local
  compilers are skipped in favor of a compatible binary on `PATH`.
- Ansible playbooks, tasks, handlers, and inventory variable directories use
  `yaml.ansible`. For unusual layouts, run `:set filetype=yaml.ansible`.
  Ansible uses the Python interpreter from its script's shebang when available,
  including Homebrew's private environment. Automatic ansible-lint is disabled.
- Generic YAML gets GitHub Actions and conventional Kubernetes-directory schemas.
- Bash LSP does not attach to Zsh files.
- Rust needs the project's toolchain and standard-library sources. For rustup,
  install sources with `rustup component add rust-src`. Cargo check-on-save is off.

## Light editing and maintenance

Save with `:write`; leaving the window never saves. Formatting is explicit via
`Space f` when the server supports it. Use `Ctrl+x Ctrl+o` for manual completion,
`grn` to rename, and `gra` for code actions. Diagnostics are available through
`Space se` (popup), `Space sd` (picker), and the native statusline.

Update plugins with `:lua vim.pack.update()`, review the update buffer, then
`:write` to apply or `:quit` to cancel. Restart Neovim after updates. On another
machine with an existing installation, sync to the tracked revisions with
`:lua vim.pack.update(nil, { target = 'lockfile' })`.
