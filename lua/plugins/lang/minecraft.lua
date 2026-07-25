-- Minecraft: datapack support (beet / mecha / bolt) plus the Spyglass LSP.
-- Used by ~/git/github.com/cadrianmae/Advancement-Count.
--
-- mason-lspconfig has no entry mapping `spyglassmc_language_server` to its
-- Mason package, so naming the server alone would never install it. Attribute
-- the package to the filetype by hand.
require("lang_policy").on_demand("mcfunction", { "spyglassmc-language-server" })

---@type LazySpec
return {
  -- Filetype detection
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      filetypes = {
        extension = {
          bolt = "python", -- bolt = Python-superset DSL
          mcfunction = "mcfunction", -- Spyglass attaches here
        },
      },
    },
  },

  -- Handles .mcfunction, .json (advancements/tags/loot/etc), .mcmeta, .nbt, .snbt
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      servers = { "spyglassmc_language_server" },
    },
  },
}
