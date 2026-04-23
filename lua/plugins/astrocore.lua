-- AstroCore config enabled

-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics_mode = 3, -- diagnostic mode on start (0 = off, 1 = no signs/virtual text, 2 = no virtual text, 3 = on)
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        relativenumber = true, -- sets vim.opt.relativenumber
        number = true, -- sets vim.opt.number
        spell = false, -- sets vim.opt.spell
        signcolumn = "yes", -- sets vim.opt.signcolumn to yes
        wrap = true, -- sets vim.opt.wrap
        scrolloff = 2, -- keep 2 lines visible above/below cursor
        conceallevel = 2, -- required for obsidian.nvim UI (checkboxes, link concealment)
      },
      g = { -- vim.g.<key>
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
      },
    },
    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    mappings = {
      -- first key is the mode
      t = {
        ["jk"] = { "<C-\\><C-n>", desc = "Exit terminal mode" },
      },
      x = {
        ["<Leader>/"] = {
          "<Esc><Cmd>lua require('Comment.api').locked('toggle.blockwise')(vim.fn.visualmode())<CR>",
          desc = "Toggle block comment",
        },
      },
      n = {
        -- second key is the lefthand side of the map

        -- navigate buffer tabs
        ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        -- mappings seen under group name "Buffer"
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },

        -- Remap Terminal group from <Leader>t to <Leader>T, freeing <Leader>t for Tabs
        ["<Leader>T"] = { desc = require("astroui").get_icon("Terminal", 1, true) .. "Terminal" },
        ["<Leader>Tf"] = { "<Cmd>ToggleTerm direction=float<CR>", desc = "ToggleTerm float" },
        ["<Leader>Th"] = { "<Cmd>ToggleTerm size=10 direction=horizontal<CR>", desc = "ToggleTerm horizontal split" },
        ["<Leader>Tv"] = { "<Cmd>ToggleTerm size=80 direction=vertical<CR>", desc = "ToggleTerm vertical split" },
        ["<Leader>Tl"] = {
          function()
            local astro = require "astrocore"
            local worktree = astro.file_worktree()
            local flags = worktree and (" --work-tree=%s --git-dir=%s"):format(worktree.toplevel, worktree.gitdir) or ""
            astro.toggle_term_cmd { cmd = "lazygit " .. flags, direction = "float" }
          end,
          desc = "ToggleTerm lazygit",
        },
        ["<Leader>Tn"] = {
          function() require("astrocore").toggle_term_cmd "node" end,
          desc = "ToggleTerm node",
        },
        ["<Leader>Tp"] = {
          function() require("astrocore").toggle_term_cmd "python" end,
          desc = "ToggleTerm python",
        },
        ["<Leader>Tu"] = {
          function() require("astrocore").toggle_term_cmd { cmd = "gdu", direction = "float" } end,
          desc = "ToggleTerm gdu",
        },
        ["<Leader>Tt"] = {
          function() require("astrocore").toggle_term_cmd { cmd = "btm", direction = "float" } end,
          desc = "ToggleTerm btm",
        },
        -- Unbind remaining <Leader>t* terminal mappings with no tab replacement
        ["<Leader>tv"] = false,
        ["<Leader>tu"] = false,
        ["<Leader>tt"] = false,

        -- Tabs (window layouts) — <Leader>t prefix
        ["<Leader>t"] = { desc = require("astroui").get_icon("Tab", 1, true) .. "Tabs" },
        ["<Leader>tn"] = { "<Cmd>tabnew<CR>", desc = "New tab" },
        ["<Leader>tc"] = { "<Cmd>tabclose<CR>", desc = "Close tab" },
        ["<Leader>to"] = { "<Cmd>tabonly<CR>", desc = "Close other tabs" },
        ["<Leader>tl"] = { "<Cmd>tabnext<CR>", desc = "Next tab" },
        ["<Leader>th"] = { "<Cmd>tabprevious<CR>", desc = "Previous tab" },
        ["<Leader>tp"] = { "<Cmd>tabprevious<CR>", desc = "Previous tab" },
        ["<Leader>tf"] = { "<Cmd>tabfirst<CR>", desc = "First tab" },
        ["<Leader>tL"] = { "<Cmd>tablast<CR>", desc = "Last tab" },
        ["<Leader>t1"] = { "1gt", desc = "Go to tab 1" },
        ["<Leader>t2"] = { "2gt", desc = "Go to tab 2" },
        ["<Leader>t3"] = { "3gt", desc = "Go to tab 3" },
        ["<Leader>t4"] = { "4gt", desc = "Go to tab 4" },
        ["<Leader>t5"] = { "5gt", desc = "Go to tab 5" },
        ["<Leader>t6"] = { "6gt", desc = "Go to tab 6" },
        ["<Leader>t7"] = { "7gt", desc = "Go to tab 7" },
        ["<Leader>t8"] = { "8gt", desc = "Go to tab 8" },
        ["<Leader>t9"] = { "9gt", desc = "Go to tab 9" },
      },
    },
  },
}
