-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Auto-closing pairs can be annoying
vim.g.minipairs_disable = false

require("config.snippets").setup()
