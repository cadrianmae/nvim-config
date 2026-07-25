-- QML: used by the Plasma applet work. No AstroCommunity pack exists, and
-- qmlls ships with Qt rather than Mason, so the server is only registered when
-- it is actually on PATH.
---@type LazySpec
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then vim.list_extend(opts.ensure_installed, { "qmljs" }) end
    end,
  },
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      config = {
        qmlls = {
          cmd = { "qmlls" },
          filetypes = { "qml" },
          root_markers = { ".git" },
        },
      },
      servers = vim.fn.executable "qmlls" == 1 and { "qmlls" } or {},
    },
  },
}
