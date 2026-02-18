-- godotdev.nvim - Comprehensive Godot 4.x integration
-- https://github.com/Mathijs-Bakker/godotdev.nvim
if true then return {} end -- Disabled in favour for AstroNvim community pack.

---@type LazySpec
return {
  {
    "Mathijs-Bakker/godotdev.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
      "nvim-treesitter/nvim-treesitter",
    },
    ft = { "gdscript", "gdshader" },
    opts = {
      editor_host = "127.0.0.1",
      editor_port = 6005, -- LSP port
      debug_port = 6006,  -- DAP port
      csharp = false,     -- Set to true if using C#
      autostart_editor_server = false, -- Let Godot handle it
    },
  },

  -- Ensure GDScript and GDShader in Tree-sitter
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = require("astrocore").list_insert_unique(
          opts.ensure_installed,
          { "gdscript", "gdshader" }
        )
      end
    end,
  },
}
