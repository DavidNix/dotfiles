-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Auto-closing pairs is annoying
vim.g.minipairs_disable = true

-- Snippets
-- Great tutorial: https://www.youtube.com/watch?v=FmHhonPjvvA
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

ls.add_snippets("go", {
  -- Require no error
  s("nerr", {
    t("require.NoError(t, err)"),
  }),
  -- Require error
  s("rerr", {
    t({ "require.Error(t, err)", 'require.Error(t, err, "changeme")' }),
  }),
  -- Table driven test
  s(
    "ttable",
    fmt(
      [[
    for _, tt := range []struct {{
      {}
    }}{{
      {{}},
    }} {{
    }}
  ]],
      { i(1) }
    )
  ),
})
