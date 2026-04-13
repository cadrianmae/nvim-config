-- Disable mini.animate cursor animation (using smear-cursor.nvim instead)
-- Keep scroll animation active
return {
  "echasnovski/mini.animate",
  opts = {
    cursor = { enable = false },
  },
}
