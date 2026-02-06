-- Override astrocommunity.pack.python to use basedpyright instead of pyright
-- Based on: https://docs.astronvim.com/recipes/advanced_lsp/
-- and: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/basedpyright.lua
---@type LazySpec
return {
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      -- Disable pyright, enable basedpyright
      handlers = {
        pyright = false,
      },
      servers = { "basedpyright" },
      config = {
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
              },
            },
          },
        },
      },
    },
  },

  -- Ensure mason installs basedpyright (not pyright)
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      -- Remove pyright if present
      opts.ensure_installed = vim.tbl_filter(function(server)
        return server ~= "pyright"
      end, opts.ensure_installed)
      -- Add basedpyright
      table.insert(opts.ensure_installed, "basedpyright")
    end,
  },

  -- Make venv-selector work with basedpyright
  {
    "linux-cultist/venv-selector.nvim",
    optional = true,
    opts = {
      settings = {
        options = {
          notify_user_on_venv_activation = true,
        },
      },
    },
  },
}
