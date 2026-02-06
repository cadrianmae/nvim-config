-- Hop.nvim with EasyMotion-style keybindings
-- All mappings use <leader><leader> prefix like classic EasyMotion

return {
  "smoka7/hop.nvim",
  opts = {},
  config = function(_, opts)
    local hop = require("hop")
    hop.setup(opts)  -- Initialize hop first

    local HintDirection = require("hop.hint").HintDirection

    vim.keymap.set({ "n", "x", "o" }, "<leader><leader>", "", {
      desc = require("astroui").get_icon("MotionHop", 1, true) .. "Hop"
    })

    -- Helper to set keymaps for multiple modes
    local function map(keys, func, desc)
      vim.keymap.set({ "n", "x", "o" }, keys, func, { desc = desc })
    end

    -- Word motions
    map("<leader><leader>w", function() hop.hint_words({ direction = HintDirection.AFTER_CURSOR }) end, "Hop word forward")
    map("<leader><leader>b", function() hop.hint_words({ direction = HintDirection.BEFORE_CURSOR }) end, "Hop word backward")
    map("<leader><leader>W", function() hop.hint_words() end, "Hop word anywhere")

    -- Vertical/line motions
    map("<leader><leader>j", function() hop.hint_vertical({ direction = HintDirection.AFTER_CURSOR }) end, "Hop column down")
    map("<leader><leader>k", function() hop.hint_vertical({ direction = HintDirection.BEFORE_CURSOR }) end, "Hop column up")

    map("<leader><leader>h", function() hop.hint_words({ direction = HintDirection.BEFORE_CURSOR, current_line_only = true }) end, "Hop word left on line")
    map("<leader><leader>l", function() hop.hint_words({ direction = HintDirection.AFTER_CURSOR, current_line_only = true }) end, "Hop word right on line")

    -- Character motions
    map("<leader><leader>f", function() hop.hint_char1({ direction = HintDirection.AFTER_CURSOR }) end, "Hop char forward")
    map("<leader><leader>F", function() hop.hint_char1({ direction = HintDirection.BEFORE_CURSOR }) end, "Hop char backward")

    -- Search (both directions)
    map("<leader><leader>s", function() hop.hint_char1() end, "Hop char anywhere")
    map("<leader><leader>/", function() hop.hint_patterns() end, "Hop pattern")

    -- Quick access
    map("<leader><leader><leader>", function() hop.hint_words() end, "Hop word")
  end,
}
