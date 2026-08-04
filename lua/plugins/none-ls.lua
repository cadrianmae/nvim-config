-- Customize None-ls sources

---@type LazySpec
return {
  "nvimtools/none-ls.nvim",
  -- AstroNvim's v4 lazy_snapshot pins none-ls to a117163 (Mar 2025), which
  -- reads `vim.lsp.protocol._request_name_to_capability`. Neovim 0.12 removed
  -- both that field and its `vim.lsp` fallback, so every `supports_method`
  -- call errors -- entering any buffer with a none-ls source floods the screen
  -- with stack traces. Upstream fixed it in e057efc; the v4 line never picked
  -- it up (v4.32.3, the last v4 tag, still pins a117163), so unpin this one
  -- plugin and track main. Drop this when the config moves off AstroNvim v4.
  commit = false,
  version = false,
  pin = false,
  opts = function(_, opts)
    -- opts variable is the default configuration table for the setup function call
    -- local null_ls = require "null-ls"

    -- Check supported formatters and linters
    -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/formatting
    -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics

    -- Only insert new sources, do not replace the existing ones
    -- (If you wish to replace, use `opts.sources = {}` instead of the `list_insert_unique` function)
    opts.sources = require("astrocore").list_insert_unique(opts.sources, {
      -- Set a formatter
      -- null_ls.builtins.formatting.stylua,
      -- null_ls.builtins.formatting.prettier,
    })
  end,
}
