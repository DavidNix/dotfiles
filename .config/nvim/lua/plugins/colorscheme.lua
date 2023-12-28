-- Change copilot suggestion color
vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = "#7CFC00" })

return {
  -- { "navarasu/onedark.nvim" },
  -- { "olimorris/onedarkpro.nvim" },
  { "projekt0n/github-nvim-theme" },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "github_dark_default",
    },
  },
}
