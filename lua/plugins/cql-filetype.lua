-- Set up CQL filetype detection
return {
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
}
