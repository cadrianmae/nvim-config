-- Customize conform.nvim formatting
return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      cql = { "sqlfluff" },
    },
    formatters = {
      sqlfluff = {
        args = { "format", "--dialect=postgres", "-" },
      },
    },
  },
}
