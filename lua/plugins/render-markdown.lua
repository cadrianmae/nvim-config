return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    ft = { 'markdown', 'quarto' },
    max_file_size = 5.0,
    debounce = 250,
    html = {
      comment = {
        conceal = false,  -- Show comments instead of hiding them
      },
    },
  },
}
