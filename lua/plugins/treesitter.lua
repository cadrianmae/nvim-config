-- Customize Treesitter

---@type LazySpec
return {
  -- No `ensure_installed` here: lazy_setup.lua overwrites that list with what
  -- lang_policy resolves, so anything added here would be discarded. Parsers
  -- belong in lang_policy's baseline, or arrive via treesitter's auto_install.
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    opts = {
      max_lines = 3,
      min_window_height = 20,
    },
  },
}
