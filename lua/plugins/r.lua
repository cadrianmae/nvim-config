-- R language support (LSP + otter.nvim fix)
-- Quarto pack provides R treesitter, this adds LSP.
--
-- otter.nvim creates virtual .qmd.otter.R buffers (in-memory by default).
-- lintr calls normalizePath() on the buffer's file URI, which fails because
-- the file doesn't exist on disk. write_to_disk=true writes the temp file
-- before LSPs attach (see otter/init.lua: "write out once before lsps can complain").
return {
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
