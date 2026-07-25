-- Which language tooling is installed up front, and which waits until first use.
--
-- `baseline` is editor-wide: installed regardless of which language bundles
-- exist, so the essentials keep working offline. A bundle in `plugins/lang/`
-- that wants its own tooling pre-installed calls `eager` at the top of the file.
-- Everything else arrives when a file of that type is first opened, via
-- treesitter's `auto_install` and mason-lspconfig's `automatic_installation`.
--
-- The resolved lists are applied by the overwrite specs at the end of
-- `lazy_setup.lua`. They must overwrite rather than append, because the
-- AstroCommunity packs add their own entries to the same lists.

local M = {}

---@alias LangToolingCategory "treesitter"|"lsp"|"tools"|"dap"

-- Installed regardless of which language bundles are present.
---@type table<LangToolingCategory, string[]>
M.baseline = {
  treesitter = { "lua", "vim", "vimdoc", "markdown", "markdown_inline", "bash" },
  lsp = { "lua_ls", "marksman" },
  tools = { "stylua", "prettierd", "markdownlint-cli2" },
  dap = {},
}

---@type table<LangToolingCategory, table<string, true>>
local registered = { treesitter = {}, lsp = {}, tools = {}, dap = {} }

--- Register tooling for eager installation. Called by a language bundle that
--- must work without a network connection.
---@param spec table<LangToolingCategory, string[]>
function M.eager(spec)
  for category, names in pairs(spec) do
    if not registered[category] then
      error(("lang_policy: unknown tooling category %q (expected treesitter, lsp, tools or dap)"):format(category))
    end
    for _, name in ipairs(names) do
      registered[category][name] = true
    end
  end
end

--- Baseline plus everything registered for that category, deduplicated.
--- Sorted so the result is stable across runs.
---@param category LangToolingCategory
---@return string[]
function M.resolve(category)
  local seen, out = {}, {}
  for _, name in ipairs(M.baseline[category] or {}) do
    if not seen[name] then
      seen[name] = true
      out[#out + 1] = name
    end
  end
  for name in pairs(registered[category] or {}) do
    if not seen[name] then
      seen[name] = true
      out[#out + 1] = name
    end
  end
  table.sort(out)
  return out
end

--- Clear registered entries. Test-only.
function M._reset() registered = { treesitter = {}, lsp = {}, tools = {}, dap = {} } end

return M
