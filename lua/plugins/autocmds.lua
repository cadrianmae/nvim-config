return {
  {
    "AstroNvim/astrocore",
    --@type AstroCoreOpts
    opts = {
      -- Map non-standard filenames to filetypes (drives LSP + linter attach)
      filetypes = {
        filename = {
          Containerfile = "dockerfile", -- so dockerls + hadolint attach
        },
      },
      autocmds = {
        man_line_numbers = {
          {
            event = "FileType",
            pattern = "man",
            desc = "Enable relative line numbers in man pages",
            callback = function()
              vim.opt_local.number = true
              vim.opt_local.relativenumber = true
              vim.opt_local.wrap = false
            end,
          },
        },
      },
    },
  },
}
