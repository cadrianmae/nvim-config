-- QML: used by the Plasma applet work. No AstroCommunity pack exists, and
-- qmlls ships with Qt rather than Mason, so the server is only registered when
-- it is actually on PATH.
---@type LazySpec
return {
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      config = {
        qmlls = {
          cmd = { "qmlls" },
          filetypes = { "qml" },
          -- `root_dir`, not `root_markers`: the latter belongs to the newer
          -- vim.lsp.config schema and this lspconfig version drops it silently.
          root_dir = require("lspconfig.util").root_pattern ".git",
        },
      },
      servers = vim.fn.executable "qmlls" == 1 and { "qmlls" } or {},
    },
  },
}
