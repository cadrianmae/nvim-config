-- Go: gopls, delve, and the gopher.nvim helpers from the pack.
-- On-demand: nothing installs until a .go file is opened.
--
-- The gopher.nvim helpers are Mason packages but not none-ls sources, so
-- mason-null-ls cannot route them to a filetype. gopls and delve need no such
-- help: the pack declares them and both integrations map them to `go`.
require("lang_policy").on_demand("go", { "gomodifytags", "gotests", "iferr", "impl" })

---@type LazySpec
return {
  { import = "astrocommunity.pack.go" },
}
