-- Markdown Table of Contents generator
-- Commands: :Mtoc (insert), :Mtoc update, :Mtoc remove
return {
  "hedyhli/markdown-toc.nvim",
  ft = "markdown",
  cmd = { "Mtoc" },
  opts = {
    -- Fences for auto-update detection
    fences = {
      enabled = true,
      start_text = "toc",
      end_text = "/toc",
    },
    -- TOC list appearance
    toc_list = {
      markers = "-",
      indent_size = 2,
    },
    -- Auto-update TOC on save
    auto_update = true,
  },
}
