-- AstroNvim's v4 lazy_snapshot pins aerial to `^2.2`. Its treesitter backend
-- reads query matches in the pre-0.12 shape, so on Neovim 0.12 the markdown
-- extension's `get_parent` calls `:type()` on a nil and every markdown buffer
-- throws on attach. aerial 4.0 ("drop support for nvim <0.12 to match
-- nvim-treesitter") is the fix, so unpin this one plugin and track master.
-- Drop this when the config moves off AstroNvim v4.
---@type LazySpec
return {
  "stevearc/aerial.nvim",
  version = false,
  commit = false,
  pin = false,
}
