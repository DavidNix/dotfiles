local M = {}

-- TODO: Unable to find luasnip module
-- M.setup = function()
--   -- Great tutorial: https://www.youtube.com/watch?v=FmHhonPjvvA
--   local ls = require("luasnip")
--   local s = ls.snippet
--   local t = ls.text_node
--   local i = ls.insert_node
--   local fmt = require("luasnip.extras.fmt").fmt
--
--   -- My custom go snippets
--   ls.add_snippets("go", {
--     -- Require no error
--     s("nerr", {
--       t("require.NoError(t, err)"),
--     }),
--     -- Require error
--     s("rerr", {
--       t({ "require.Error(t, err)", 'require.Error(t, err, "changeme")' }),
--     }),
--     -- Table driven test
--     s(
--       "ttable",
--       fmt(
--         [[
--     for _, tt := range []struct {{
--       {}
--     }}{{
--       {{}},
--     }} {{
--     }}
--   ]],
--         { i(1) }
--       )
--     ),
--   })
-- end

return M
