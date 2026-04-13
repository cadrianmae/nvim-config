return {
  dir = vim.fn.expand "~/git/github.com/cadrianmae/signals.nvim",
  event = "VeryLazy",
  opts = {
    player = "paplay",
    max_sounds = 10,
    debounce_ms = 150,
    signals = {
      inline_suggestion = { enabled = true },
    },
  },
}
