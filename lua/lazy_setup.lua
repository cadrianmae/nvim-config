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
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      -- Packs (e.g. astrocommunity/pack/go) declare servers by appending to
      -- this list. Record what they asked for before overwriting it, so the
      -- on-demand installer still knows which servers a filetype's bundle
      -- actually wants. See lua/lang_policy.lua's `declare`/`get_declared`.
      policy.declare("lsp", opts.ensure_installed)
      opts.ensure_installed = policy.resolve "lsp"
      opts.automatic_installation = true -- servers install on first attach
    end,
  },
  {
    "jay-babu/mason-null-ls.nvim",
    opts = function(_, opts) opts.ensure_installed = policy.resolve "tools" end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = function(_, opts) opts.ensure_installed = policy.resolve "dap" end,
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
