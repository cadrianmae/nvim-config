-- Customize conform.nvim formatting
return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      cql = { "sqlfluff" },
      markdown = { "prettierd" },
    },
    formatters = {
      sqlfluff = {
        args = { "format", "--dialect=postgres", "-" },
      },
      prettierd = {
        env = {
          PRETTIERD_DEFAULT_CONFIG = vim.fn.expand("~/.config/nvim/prettier.config.json"),
        },
      },
    },
  },
}
