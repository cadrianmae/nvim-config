-- Prolog: SWI-Prolog LSP, hand-wired because AstroCommunity has no Prolog pack
-- and swipl is not a Mason package -- it comes from the system.
---@type LazySpec
return {
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      config = {
        prolog_lsp = {
          cmd = {
            "swipl",
            "-g",
            "use_module(library(lsp_server))",
            "-g",
            "lsp_server:main",
            "-t",
            "halt",
            "--",
            "stdio",
          },
          filetypes = { "prolog" },
          root_dir = require("lspconfig.util").root_pattern("pack.pl", ".git"),
        },
      },
      servers = { "prolog_lsp" },
    },
  },

  -- Filetype detection
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      filetypes = {
        extension = {
          pl = "prolog", -- .pl files
          pro = "prolog", -- .pro files
          P = "prolog", -- .P files (XSB Prolog)
        },
      },
    },
  },
}
