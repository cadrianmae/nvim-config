-- Customize Treesitter

---@type LazySpec
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "lua",
        "vim",
        "mermaid",
        "gdscript",
        "c", -- C source files
        "dockerfile", -- Containerfile syntax
        "bash", -- setup_env.sh / public_test.sh
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    opts = {
      max_lines = 3,
      min_window_height = 20,
    },
  },
}
