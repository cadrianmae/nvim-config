return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      terminal = {
        provider = "none", -- Disable terminal, use MCP IDE mode only
      },
    },
    keys = {
      { "<leader>a", nil, desc = require("astroui").get_icon("AI", 1, true) .. "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
      },
      -- Diff management
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
  },
  -- Configure auto-save to exclude claudecode diff buffers
  -- Prevents auto-save from immediately accepting Claude's proposed changes
  {
    "okuuva/auto-save.nvim",
    optional = true,
    opts = {
      condition = function(buf)
        local bufname = vim.fn.bufname(buf)

        -- Exclude claudecode diff buffers by name pattern
        if bufname:match("%(proposed%)") or bufname:match("%(NEW FILE %- proposed%)") then
          return false
        end

        -- Exclude buffers with claudecode variables
        if vim.b[buf].claudecode_diff then
          return false
        end

        -- Exclude acwrite buffer type (used by claudecode diffs)
        if vim.fn.getbufvar(buf, "&buftype") == "acwrite" then
          return false
        end

        -- Allow auto-save for all other buffers
        return true
      end,
    },
  },
}
