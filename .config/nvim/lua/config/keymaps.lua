-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- inspriation https://github.com/bugb/dotfiles/blob/main/.config/nvim/core/options.lua
-- local builtin = require("telescope.builtin")
local map = vim.keymap.set
-- local set = vim.opt
local defaults = { noremap = true, silent = true }

-- Map jk to escape
map("i", "jk", "<esc>l", defaults)

-- Map command to ;
map("n", ";", ":", { noremap = true })

-- Remove trailing space
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  pattern = { "*" },
  command = [[%s/\s\+$//e]],
})
