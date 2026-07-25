-- Set up CQL filetype detection
-- SQL and CQL: SQL pack plus Cassandra CQL filetype detection.
-- On-demand: nothing installs until a .sql or .cql file is opened.
return {
  { import = "astrocommunity.pack.sql" },
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      options = {
        opt = {
          -- Add custom filetype detection
        },
      },
      filetypes = {
        extension = {
          cql = "sql", -- Treat .cql files as SQL
        },
      },
    },
  },
}
