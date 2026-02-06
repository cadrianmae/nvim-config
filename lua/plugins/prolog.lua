-- Prolog language support configuration

---@type LazySpec
return {
  -- Treesitter support
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "prolog" })
      end
    end,
  },

  -- LSP support (manual setup - not available in Mason)
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
      servers = {
        "prolog_lsp",
      },
    },
  },

  -- Filetype detection
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      filetypes = {
        extension = {
          pl = "prolog",  -- .pl files
          pro = "prolog", -- .pro files
          P = "prolog",   -- .P files (XSB Prolog)
        },
      },
    },
  },
}
