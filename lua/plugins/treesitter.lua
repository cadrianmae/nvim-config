-- Customize Treesitter

--- Normalise a query match to the pre-0.12 shape: one node per capture id.
---
--- Neovim 0.12 dropped the `all` option on `add_predicate`/`add_directive`, so
--- every handler now receives `TSNode[]` per capture. nvim-treesitter's master
--- branch still registers with `all = false` and indexes `match[id]` as a bare
--- node, so it calls `:range()` on a list and errors. Taking the first node
--- restores what `all = false` used to hand over.
---@param match table<integer, TSNode|TSNode[]|nil>
---@return table<integer, TSNode|nil>
local function first_node_per_capture(match)
  local single = {}
  for id, node in pairs(match) do
    -- A TSNode is userdata; only the 0.12 list wrapper is a table.
    single[id] = type(node) == "table" and node[1] or node
  end
  return single
end

---@type LazySpec
return {
  -- nvim-treesitter's master branch does not support Neovim 0.12 and never
  -- will -- 0.12 support lives on its `main` branch, which AstroNvim adopted in
  -- v6. AstroNvim v4 pins master (f8aaf5ce), so its six query handlers break on
  -- any buffer whose injections run them; markdown code fences hit
  -- `set-lang-from-info-string!` on every render-markdown pass.
  --
  -- Rather than reimplement the handlers, wrap them as they register: swap out
  -- the two registration functions for the duration of nvim-treesitter's load,
  -- then put the originals back so later plugins register against stock 0.12.
  -- Drop this whole block when the config moves off AstroNvim v4.
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      if vim.fn.has "nvim-0.12" == 0 then return end

      local query = require "vim.treesitter.query"
      local add_predicate, add_directive = query.add_predicate, query.add_directive

      ---@param register fun(name: string, handler: function, opts?: table)
      local function wrapping(register)
        return function(name, handler, opts)
          register(name, function(match, ...) return handler(first_node_per_capture(match), ...) end, opts)
        end
      end

      query.add_predicate = wrapping(add_predicate)
      query.add_directive = wrapping(add_directive)

      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyLoad",
        desc = "Restore stock treesitter query registration after nvim-treesitter loads",
        callback = function(args)
          if args.data ~= "nvim-treesitter" then return end
          query.add_predicate, query.add_directive = add_predicate, add_directive
          return true -- delete this autocmd
        end,
      })
    end,
  },
  -- No `ensure_installed` here: lazy_setup.lua overwrites that list with what
  -- lang_policy resolves, so anything added here would be discarded. Parsers
  -- belong in lang_policy's baseline, or arrive via treesitter's auto_install.
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    opts = {
      max_lines = 3,
      min_window_height = 20,
    },
  },
}
