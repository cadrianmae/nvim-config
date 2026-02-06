-- snacks.nvim - QoL plugin collection
return {
  "folke/snacks.nvim",
  opts = {
    -- Terminal with double-escape to normal mode (ESC ESC)
    terminal = {},
    -- Other useful features
    bigfile = { enabled = true },
    quickfile = { enabled = true },
    -- Image rendering (better tmux support than image.nvim)
    image = { enabled = true },
    words = { enabled = true },
    statuscolumn = { enabled = true },
  },
}
