-- snacks.nvim - QoL plugin collection
return {
  "folke/snacks.nvim",
  keys = {
    {
      "<Leader>uI",
      function()
        local cfg = require("snacks.image").config.doc
        cfg.enabled = not cfg.enabled
        if cfg.enabled then
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) then
              vim.b[buf].snacks_image_attached = nil
              require("snacks.image.doc").attach(buf)
            end
          end
        else
          require("snacks.image.placement").clean()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            vim.b[buf].snacks_image_attached = nil
          end
        end
        vim.notify("Snacks image " .. (cfg.enabled and "enabled" or "disabled"))
      end,
      desc = "Toggle inline image rendering",
    },
  },
  opts = {
    -- Terminal with double-escape to normal mode (ESC ESC)
    terminal = {},
    -- Other useful features
    bigfile = { enabled = true },
    quickfile = { enabled = true },
    -- Image rendering (better tmux support than image.nvim)
    image = {
      enabled = true,
      doc = {
        -- auto_resize re-renders images when window splits/resizes (default is static)
        auto_resize = true,
        -- max_width/max_height as fallback when wins() returns empty (e.g. async load);
        -- actual constraint comes from the textoff-aware patch in config below
        max_width = 120,
        max_height = 60,
      },
    },
    words = { enabled = true },
    statuscolumn = { enabled = true },
  },
  config = function(_, opts)
    require("snacks").setup(opts)

    -- Patch placement.state to re-fit images against the text area width
    -- (nvim_win_get_width includes the gutter/textoff; images render in the text area only)
    local ok, placement = pcall(require, "snacks.image.placement")
    if not ok then return end

    local orig_state = placement.state
    placement.state = function(self)
      local state = orig_state(self)
      local text_width = math.huge
      for _, win in ipairs(self:wins()) do
        local info = vim.fn.getwininfo(win)[1]
        if info then
          text_width = math.min(text_width, info.width - info.textoff)
        end
      end
      if text_width ~= math.huge and text_width < state.loc.width then
        local util = require("snacks.image.util")
        local fitted = util.fit(self.img.file, { width = text_width, height = state.loc.height }, { info = self.img.info })
        state.loc.width = fitted.width
        state.loc.height = fitted.height
      end
      return state
    end
  end,
}
