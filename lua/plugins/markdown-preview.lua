-- Browser-based markdown preview
return {
  "iamcco/markdown-preview.nvim",
  config = function()
    vim.g.mkdp_auto_close = 0  -- Keep preview open when switching buffers
    vim.g.mkdp_browser = 'epiphany'
  end,
}
