-- vim-table-mode — interactive markdown table editing
-- https://github.com/dhruvasagar/vim-table-mode
return {
  "dhruvasagar/vim-table-mode",
  ft = { "markdown", "quarto", "rmd", "org", "rst" },
  cmd = { "TableModeToggle", "TableModeEnable", "TableModeDisable", "TableModeRealign", "Tableize" },
  init = function()
    vim.g.table_mode_corner = "|" -- GitHub-flavoured markdown corners
    vim.g.table_mode_corner_corner = "|"
    vim.g.table_mode_header_fillchar = "-"

    -- Rebind the plugin's <Leader>t* namespace to <Leader>m* (Tabs owns <Leader>t)
    vim.g.table_mode_map_prefix = "<Leader>m" -- used only for toggle concat
    vim.g.table_mode_toggle_map = "m" -- final: <Leader>mm (prefix + this)
    -- The rest are absolute; set them full so they ignore map_prefix
    vim.g.table_mode_delete_row_map = "<Leader>mr"
    vim.g.table_mode_delete_column_map = "<Leader>mc"
    vim.g.table_mode_insert_column_after_map = "<Leader>mi"
    vim.g.table_mode_insert_column_before_map = "<Leader>mI"
    vim.g.table_mode_realign_map = "<Leader>ma"
    vim.g.table_mode_tableize_map = "<Leader>mt"
    vim.g.table_mode_tableize_d_map = "<Leader>mT"
  end,
  specs = {
    {
      "AstroNvim/astrocore",
      ---@type AstroCoreOpts
      opts = {
        mappings = {
          n = {
            ["<Leader>m"] = { desc = "󰓫 Markdown tables" },
            ["<Leader>mm"] = { "<Cmd>TableModeToggle<CR>", desc = "Toggle table mode" },
            ["<Leader>ma"] = { "<Plug>(table-mode-realign)", desc = "Realign table", remap = true },
            ["<Leader>mr"] = { "<Plug>(table-mode-delete-row)", desc = "Delete row", remap = true },
            ["<Leader>mc"] = { "<Plug>(table-mode-delete-column)", desc = "Delete column", remap = true },
            ["<Leader>mi"] = { "<Plug>(table-mode-insert-column-after)", desc = "Insert column after", remap = true },
            ["<Leader>mI"] = { "<Plug>(table-mode-insert-column-before)", desc = "Insert column before", remap = true },
            ["<Leader>mt"] = { "<Plug>(table-mode-tableize)", desc = "Tableize line/selection", remap = true },
          },
          x = {
            ["<Leader>mt"] = { "<Plug>(table-mode-tableize)", desc = "Tableize selection", remap = true },
            ["<Leader>mT"] = { "<Plug>(table-mode-tableize-delimiter)", desc = "Tableize by delimiter", remap = true },
          },
        },
      },
    },
  },
}
