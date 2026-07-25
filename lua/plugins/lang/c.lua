-- C: clangd and codelldb. Eager rather than on-demand -- this is coursework
-- tooling that has to work without a network connection.
require("lang_policy").eager {
  lsp = { "clangd" },
  treesitter = { "c" },
  dap = { "codelldb" },
}

---@type LazySpec
return {
  { import = "astrocommunity.pack.cpp" },
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      config = {
        clangd = { capabilities = { offsetEncoding = "utf-8" } }, -- silence utf-16 offset warning
      },
    },
  },
}
