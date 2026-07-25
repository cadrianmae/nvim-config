-- Minecraft datapack support (beet / mecha / bolt + Spyglass LSP)
-- Used by: ~/git/github.com/cadrianmae/Advancement-Count

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

  -- Register Spyglass LSP (install via :MasonInstall spyglassmc-language-server)
  -- Handles: .mcfunction, .json (advancements/tags/loot/etc), .mcmeta, .nbt, .snbt
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      servers = { "spyglassmc_language_server" },
    },
  },
}
