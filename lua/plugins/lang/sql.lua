-- SQL and CQL: the SQL pack plus Cassandra CQL filetype detection.
-- On-demand: nothing installs until a .sql or .cql file is opened.
---@type LazySpec
return {
  { import = "astrocommunity.pack.sql" },
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      filetypes = {
        extension = {
          cql = "sql", -- Treat .cql files as SQL
        },
      },
    },
  },
}
