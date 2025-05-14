return {
  {
    "AstroNvim/astrocore",
    --@type AstroCoreOpts
    opts = {
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
