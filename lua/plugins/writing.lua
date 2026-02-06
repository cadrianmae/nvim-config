-- Writing enhancements for markdown/tex files
return {
  -- Section word count (per-heading word counts)
  {
    "dimfeld/section-wordcount.nvim",
    ft = { "markdown", "asciidoc" },
    config = function()
      require("section-wordcount").setup({
        highlight = "Comment",
        virt_text_pos = "eol",
      })
      -- Enable for markdown
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown" },
        callback = function()
          require("section-wordcount").wordcounter({})
        end,
      })
    end,
  },

  -- Spell check for writing files
  {
    "AstroNvim/astrocore",
    opts = {
      autocmds = {
        spell_check = {
          {
            event = "FileType",
            pattern = { "markdown", "tex", "text" },
            callback = function()
              vim.opt_local.spell = true
              vim.opt_local.spelllang = "en_gb"
            end,
            desc = "Enable spell check for writing files",
          },
        },
      },
    },
  },
}
