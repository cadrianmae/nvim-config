local policy = require "lang_policy"

require("lazy").setup({
  {
    "AstroNvim/AstroNvim",
    version = "^4", -- Remove version tracking to elect for nightly AstroNvim
    import = "astronvim.plugins",
    opts = { -- AstroNvim options must be set here with the `import` key
      mapleader = " ", -- This ensures the leader key must be configured before Lazy is set up
      maplocalleader = ",", -- This ensures the localleader key must be configured before Lazy is set up
      icons_enabled = true, -- Set to false to disable icons (if no Nerd Font is available)
      pin_plugins = nil, -- Default will pin plugins when tracking `version` of AstroNvim, set to true/false to override
      update_notifications = true, -- Enable/disable notification about running `:Lazy update` twice to update pinned plugins
    },
  },
  { import = "community" },
  { import = "plugins" },
  { import = "plugins.lang" },

  -- Install policy, applied last so it overwrites the entries appended by the
  -- AstroCommunity packs. See lua/lang_policy.lua.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = policy.resolve "treesitter"
      opts.auto_install = true -- parsers compile on first open of that filetype
    end,
  },
  -- Every overwrite below records what it is about to discard, so the
  -- FileType installer in lang_policy.lua can still install it on first use.
  -- Overwriting without a matching `declare` is pure deletion, and silent.
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      -- Packs (e.g. astrocommunity/pack/go) declare servers by appending to
      -- this list. See lua/lang_policy.lua's `declare`/`get_declared`.
      policy.declare("lsp", opts.ensure_installed)
      opts.ensure_installed = policy.resolve "lsp"
    end,
  },
  {
    "AstroNvim/astrolsp",
    ---@param opts AstroLSPOpts
    opts = function(_, opts)
      -- The other channel a bundle can name a server through: docker.lua and
      -- minecraft.lua both use it. Read it too, so choosing either channel
      -- works rather than one of them silently never installing. Servers with
      -- no Mason package (prolog_lsp, qmlls) map to nil and are skipped.
      policy.declare("lsp", opts.servers)
    end,
  },
  {
    "jay-babu/mason-null-ls.nvim",
    opts = function(_, opts)
      policy.declare("tools", opts.ensure_installed)
      opts.ensure_installed = policy.resolve "tools"
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = function(_, opts)
      policy.declare("dap", opts.ensure_installed)
      opts.ensure_installed = policy.resolve "dap"
    end,
  },
} --[[@as LazySpec]], {
  -- Configure any other `lazy.nvim` configuration options here
  install = { colorscheme = { "astrotheme", "habamax" } },
  ui = { backdrop = 100 },
  performance = {
    rtp = {
      -- disable some rtp plugins, add more to your liking
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "zipPlugin",
      },
    },
  },
} --[[@as LazyConfig]])
