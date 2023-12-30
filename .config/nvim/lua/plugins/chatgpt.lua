local model = "gpt-4-1106-preview"
return {
  "jackMort/ChatGPT.nvim",
  event = "VeryLazy",
  config = function()
    -- For options see: https://github.com/jackMort/ChatGPT.nvim/blob/main/lua/chatgpt/config.lua
    require("chatgpt").setup({
      api_key_cmd = "op read op://Personal/OpenAINeovim/password --no-newline",
      openai_params = {
        model = model,
        frequency_penalty = 0,
        presence_penalty = 0,
        max_tokens = 4096,
        temperature = 0,
        top_p = 1,
        n = 1,
      },
      openai_edit_params = {
        model = model,
        frequency_penalty = 0,
        presence_penalty = 0,
        temperature = 0,
        top_p = 1,
        n = 1,
      },
    })
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
}
