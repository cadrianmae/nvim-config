-- R and Quarto: the Quarto pack provides the parsers, this adds the LSP.
-- On-demand: nothing installs until an .R or .qmd file is opened.
--
-- otter.nvim creates virtual .qmd.otter.R buffers, in memory by default.
-- lintr calls normalizePath() on the buffer's file URI, which fails because
-- the file does not exist on disk. write_to_disk writes the temp file before
-- the LSPs attach (see otter/init.lua: "write out once before lsps can
-- complain").
---@type LazySpec
return {
  { import = "astrocommunity.pack.quarto" },
  {
    "jmbuhr/otter.nvim",
    opts = {
      buffers = {
        write_to_disk = true,
      },
    },
  },
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      ---@diagnostic disable: missing-fields
      config = {
        r_language_server = {
          settings = {
            r = {
              lsp = {
                diagnostics = true,
                rich_documentation = false,
              },
            },
          },
        },
      },
    },
  },
}
