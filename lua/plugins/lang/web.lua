-- Web: TypeScript, JavaScript, HTML and CSS via vtsls.
-- On-demand: nothing installs until a .ts, .tsx, .js or .jsx file is opened.
--
-- The pack's `js` debug adapter is absent from mason-nvim-dap's filetype
-- table, so it is attributed by hand.
require("lang_policy").on_demand(
  { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  { "js-debug-adapter" }
)

---@type LazySpec
return {
  { import = "astrocommunity.pack.typescript" },
}
