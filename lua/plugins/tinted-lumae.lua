-- lumae theme via tinted-nvim, auto-following tinty (current_scheme).
-- Schemes generated from maebrand: lua/lumae-schemes.lua (regenerate with
-- `npm run build:themes` in maebrand, then copy dist/themes/tinted-nvim-lumae.lua).
---@type LazySpec
return {
  "tinted-theming/tinted-nvim",
  version = "1.0.*",
  priority = 1000,
  lazy = false,
  opts = {
    default_scheme = "base24-lumae-dusk",
    apply_scheme_on_startup = true,
    schemes = require("lumae-schemes"),
    capabilities = { truecolor = true },
    selector = {
      enabled = true,
      mode = "file",
      path = vim.fn.expand("~/.local/share/tinted-theming/tinty/current_scheme"),
      watch = true, -- auto-reload when tinty switches flavor
    },
  },
}
