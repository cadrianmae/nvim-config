return {
  {
    "catppuccin",
    opts = {
      flavour = "auto", -- latte, frappe, macchiato, mocha
      background = { -- :h background
        light = "latte",
        dark = "macchiato",
      },
      -- transparent_background = false, -- disables setting the background color.
      float = {
        transparent = false, -- enable transparent floating windows
        solid = false, -- use solid styling for floating windows, see |winborder|
      },
      show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
      term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
      dim_inactive = {
        enabled = false, -- dims the background color of inactive window
        shade = "dark",
        percentage = 0.15, -- percentage of the shade to apply to the inactive window
      },
      no_italic = false, -- Force no italic
      no_bold = false, -- Force no bold
      no_underline = false, -- Force no underline
      styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
        comments = { "italic" }, -- Change the style of comments
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
        -- miscs = {}, -- Uncomment to turn off hard-coded styles
      },
      lsp_styles = { -- Handles the style of specific lsp hl groups (see `:h lsp-highlight`).
        virtual_text = {
          errors = { "italic" },
          hints = { "italic" },
          warnings = { "italic" },
          information = { "italic" },
          ok = { "italic" },
        },
        underlines = {
          errors = { "underline" },
          hints = { "underline" },
          warnings = { "underline" },
          information = { "underline" },
          ok = { "underline" },
        },
        inlay_hints = {
          background = true,
        },
      },
      color_overrides = {
        latte = {
          -- text tiers
          text = "#3d4055",     -- 9.00:1 AAA (was 7.06:1)
          subtext1 = "#4d5064", -- 7.02:1 AAA (was 5.53:1)
          subtext0 = "#63667a", -- 5.00:1 AA  (was 4.37:1, failed AA)
          overlay2 = "#6a6d81", -- 4.51:1 AA  (was 3.49:1, failed AA)
          -- accents darkened to pass AA as text (red already passed)
          peach = "#bf4701",    -- 4.51:1 AA (was 2.64:1)
          yellow = "#996214",   -- 4.52:1 AA (was 2.31:1)
          green = "#327d22",    -- 4.54:1 AA (was 2.96:1)
          teal = "#137a80",     -- 4.50:1 AA (was 3.31:1)
          sky = "#0376a3",      -- 4.50:1 AA (was 2.47:1)
          blue = "#1962f5",     -- 4.52:1 AA (was 4.34:1)
          pink = "#c81f9b",     -- 4.50:1 AA (was 2.34:1)
        },
      },
      custom_highlights = {},
      default_integrations = true,
      auto_integrations = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        notify = false,
        mini = {
          enabled = true,
          indentscope_color = "",
        },
        -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
      },
    },
  },
}
