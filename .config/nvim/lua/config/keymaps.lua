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

-- Go test files
function ToggleGoTestFile()
  local current_file = vim.fn.expand("%")

  if vim.fn.expand("%:e") == "go" then
    if vim.fn.match(current_file, "_test.go$") >= 0 then
      -- It's a test file, find the corresponding source file
      local source_file = vim.fn.substitute(current_file, "_test.go$", ".go", "")
      vim.api.nvim_command("edit " .. source_file)
    else
      -- It's a source file, find or create the corresponding test file
      local test_file = vim.fn.substitute(current_file, ".go$", "_test.go", "")
      if vim.fn.filereadable(test_file) == 0 then
        -- Create the test file if it doesn't exist
        vim.fn.system("gotests -w -exported " .. vim.fn.shellescape(current_file))
      end
      vim.api.nvim_command("edit " .. test_file)
    end
  else
    print("Not a Go file")
  end
end
map("n", "<leader>gt", ":lua ToggleGoTestFile()<CR>", defaults)
