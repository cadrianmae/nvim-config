-- Pandoc citation + cross-reference completion for markdown/pandoc files.
-- Completes @citekey from the `bibliography:` path in the YAML frontmatter.
-- Works with the reports/*/references -> docs/references symlink pattern in
-- the snappy-fyp repo.
--
-- Usage: in a markdown file, type '@' to trigger citation completion.
--
-- Note: cmp-pandoc-references resolves the bibliography path via
-- vim.fn.filereadable(), which uses nvim's cwd — not the buffer's
-- directory. We install a BufEnter autocmd to lcd into the file's
-- directory so the relative path in the frontmatter resolves correctly.

---@type LazySpec
return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "jc-doyle/cmp-pandoc-references",
    },
    opts = function(_, opts)
      local cmp = require "cmp"
      cmp.setup.filetype({ "markdown", "pandoc", "rmd" }, {
        sources = cmp.config.sources({
          { name = "pandoc_references" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })

      -- Window-local chdir so the plugin finds references.bib relative
      -- to the markdown file (it calls filereadable() against cwd).
      vim.api.nvim_create_autocmd({ "BufEnter", "BufRead" }, {
        pattern = { "*.md", "*.markdown", "*.rmd" },
        callback = function(args)
          local dir = vim.fn.fnamemodify(args.file, ":p:h")
          if dir and dir ~= "" then
            vim.cmd("silent! lcd " .. vim.fn.fnameescape(dir))
          end
        end,
        desc = "lcd to markdown file directory for cmp-pandoc-references",
      })

      return opts
    end,
  },
}
