-- Which language tooling is installed up front, and which waits until first use.
--
-- `baseline` is editor-wide: installed regardless of which language bundles
-- exist, so the essentials keep working offline. A bundle in `plugins/lang/`
-- that wants its own tooling pre-installed calls `eager` at the top of the file.
-- Everything else arrives when a file of that type is first opened, via
-- treesitter's `auto_install` and the `FileType` installer at the bottom of
-- this file.
--
-- The resolved lists are applied by the overwrite specs at the end of
-- `lazy_setup.lua`. They must overwrite rather than append, because the
-- AstroCommunity packs add their own entries to the same lists.
--
-- Because those overwrites throw the packs' own lists away, every channel a
-- bundle can declare tooling through has to be read back into `declared`
-- first, or the declaration vanishes with no error. The channels currently
-- read, all in `lazy_setup.lua`:
--
--   * `mason-lspconfig.nvim`  `ensure_installed`  -> declared.lsp
--   * `AstroNvim/astrolsp`    `servers`           -> declared.lsp
--   * `mason-null-ls.nvim`    `ensure_installed`  -> declared.tools
--   * `mason-nvim-dap.nvim`   `ensure_installed`  -> declared.dap
--
-- Anything Mason can install but those integrations cannot map to a filetype
-- (spyglassmc, the gopher.nvim helpers, the `js` debug adapter) is attributed
-- to its filetypes explicitly with `on_demand`.

local M = {}

---@alias LangToolingCategory "treesitter"|"lsp"|"tools"|"dap"

-- Installed regardless of which language bundles are present.
--
-- `mermaid` is here rather than left to treesitter's `auto_install` because it
-- is an injected language inside markdown fences: `auto_install` only fires on
-- a buffer's own filetype, and no buffer is ever of filetype `mermaid`.
---@type table<LangToolingCategory, string[]>
M.baseline = {
  treesitter = { "lua", "vim", "vimdoc", "markdown", "markdown_inline", "mermaid", "bash" },
  lsp = { "lua_ls", "marksman" },
  tools = { "stylua", "prettierd", "markdownlint-cli2" },
  dap = {},
}

---@type table<LangToolingCategory, table<string, true>>
local registered = { treesitter = {}, lsp = {}, tools = {}, dap = {} }

-- What AstroCommunity packs asked for via their own `ensure_installed`
-- contributions, captured before the policy overwrite in `lazy_setup.lua`
-- discards them. Distinct from `baseline`/`eager` (what installs up front)
-- and `resolve` (what installs now): this is "what a pack says it needs",
-- used by the on-demand installer to know which servers a filetype's own
-- bundle actually wants, rather than every server lspconfig happens to know.
---@type table<LangToolingCategory, table<string, true>>
local declared = { treesitter = {}, lsp = {}, tools = {}, dap = {} }

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

-- Mason packages a bundle has attributed to particular filetypes by hand.
---@type table<string, table<string, true>>
local attributed = {}

--- Clear registered entries. Test-only.
function M._reset()
  registered = { treesitter = {}, lsp = {}, tools = {}, dap = {} }
  declared = { treesitter = {}, lsp = {}, tools = {}, dap = {} }
  attributed = {}
end

--- Attribute Mason packages to the filetypes that need them, installing them
--- when such a file is first opened.
---
--- This is the escape hatch for tooling the Mason integration plugins cannot
--- route themselves. They each map names to filetypes from a built-in table,
--- and those tables have holes: `spyglassmc_language_server` is absent from
--- mason-lspconfig's package mapping entirely, the gopher.nvim helpers
--- (`gotests` and friends) are Mason packages but not none-ls sources, and the
--- `js` debug adapter is missing from mason-nvim-dap's filetype table. Without
--- this, such a package is declared, matched against nothing, and silently
--- never installed.
---
--- Takes Mason package names as `:Mason` lists them, not lspconfig server or
--- none-ls source names -- there is no mapping step, they are installed as
--- given.
---@param filetypes string|string[]
---@param packages string[] Mason package names
function M.on_demand(filetypes, packages)
  if type(filetypes) == "string" then filetypes = { filetypes } end
  for _, filetype in ipairs(filetypes) do
    attributed[filetype] = attributed[filetype] or {}
    for _, name in ipairs(packages or {}) do
      attributed[filetype][name] = true
    end
  end
end

--- Mason packages attributed to a filetype by `on_demand`, deduplicated and
--- sorted.
---@param filetype string
---@return string[]
function M.get_on_demand(filetype)
  local out = {}
  for name in pairs(attributed[filetype] or {}) do
    out[#out + 1] = name
  end
  table.sort(out)
  return out
end

--- Record tooling a pack declared it wants, ahead of the policy overwrite
--- replacing `opts.ensure_installed` with the resolved eager list. Idempotent
--- and additive: repeat calls only add entries, never remove or replace.
---@param category LangToolingCategory
---@param names string[]
function M.declare(category, names)
  if not declared[category] then
    error(("lang_policy: unknown tooling category %q (expected treesitter, lsp, tools or dap)"):format(category))
  end
  for _, name in ipairs(names or {}) do
    declared[category][name] = true
  end
end

--- Everything declared for a category, deduplicated and sorted.
---@param category LangToolingCategory
---@return string[]
function M.get_declared(category)
  local out = {}
  for name in pairs(declared[category] or {}) do
    out[#out + 1] = name
  end
  table.sort(out)
  return out
end

--- Mason packages to install for a filetype: those serving it that are
--- configured but not yet installed. Pure, so it can be tested directly.
---@param configured string[] lspconfig server names this config sets up
---@param serving string[] lspconfig server names that handle the filetype
---@param installed table<string, true> mason package names already present
---@param to_package fun(server: string): string? lspconfig name to mason package name
---@return string[] mason package names, sorted
function M.packages_to_install(configured, serving, installed, to_package)
  local wanted, out = {}, {}
  for _, server in ipairs(serving) do
    wanted[server] = true
  end
  for _, server in ipairs(configured) do
    if wanted[server] then
      local package = to_package(server)
      if package and not installed[package] then out[#out + 1] = package end
    end
  end
  table.sort(out)
  return out
end

--- One bridge per Mason integration plugin, so `lsp`, `tools` and `dap` all
--- reach the same on-demand installer instead of only `lsp` having one.
---
--- `module` is checked against `package.loaded` before anything else: the
--- installer must never be the reason mason.nvim gets pulled into a session.
--- Nothing is lost by skipping an unloaded integration, because `declared` for
--- that category is populated by that same plugin's `opts` function and is
--- therefore empty until it loads.
---@alias LangInstallAdapter { module: string, serving: fun(filetype: string): string[], to_package: fun(name: string): string? }
---@type table<LangToolingCategory, LangInstallAdapter>
local adapters = {
  lsp = {
    module = "mason-lspconfig",
    serving = function(filetype)
      local ok, mason_lspconfig = pcall(require, "mason-lspconfig")
      if not ok then return {} end
      local ok_list, list = pcall(mason_lspconfig.get_available_servers, { filetype = filetype })
      return (ok_list and type(list) == "table") and list or {}
    end,
    to_package = function(name)
      local ok, mapping = pcall(require, "mason-lspconfig.mappings.server")
      if not ok then return nil end
      return mapping.lspconfig_to_package[name]
    end,
  },
  tools = {
    module = "mason-null-ls",
    serving = function(filetype)
      local ok, mapping = pcall(require, "mason-null-ls.mappings.filetype")
      if not ok then return {} end
      return type(mapping[filetype]) == "table" and mapping[filetype] or {}
    end,
    to_package = function(name)
      local ok, mapping = pcall(require, "mason-null-ls.mappings.source")
      if not ok then return nil end
      local ok_package, package_name = pcall(mapping.getPackageFromNullLs, name)
      return ok_package and package_name or nil
    end,
  },
  dap = {
    module = "mason-nvim-dap",
    -- mason-nvim-dap maps the other way round, adapter name to filetypes.
    serving = function(filetype)
      local ok, mapping = pcall(require, "mason-nvim-dap.mappings.filetypes")
      if not ok then return {} end
      local out = {}
      for adapter, filetypes in pairs(mapping) do
        if type(filetypes) == "table" and vim.tbl_contains(filetypes, filetype) then out[#out + 1] = adapter end
      end
      return out
    end,
    to_package = function(name)
      local ok, mapping = pcall(require, "mason-nvim-dap.mappings.source")
      if not ok then return nil end
      return mapping.nvim_dap_to_package[name]
    end,
  },
}

--- Every Mason package this filetype wants but does not have: the declared
--- entries of each loaded category that serve it, plus anything `on_demand`
--- attributed to it directly. Pure apart from the adapter calls, so it can be
--- tested by passing stub adapters.
---@param filetype string
---@param installed table<string, true> mason package names already present
---@param with LangInstallAdapter[]? defaults to the real integration bridges
---@return string[] mason package names, sorted
function M.resolve_installs(filetype, installed, with)
  local wanted = {}

  for category, adapter in pairs(adapters) do
    local active = with and with[category] or (package.loaded[adapter.module] and adapter or nil)
    if active then
      local packages =
        M.packages_to_install(M.get_declared(category), active.serving(filetype), installed, active.to_package)
      for _, name in ipairs(packages) do
        wanted[name] = true
      end
    end
  end

  for _, name in ipairs(M.get_on_demand(filetype)) do
    if not installed[name] then wanted[name] = true end
  end

  local out = {}
  for name in pairs(wanted) do
    out[#out + 1] = name
  end
  table.sort(out)
  return out
end

-- Filetypes already handled this session, so opening several buffers of the
-- same type only triggers the install scan once.
---@type table<string, true>
local seen_filetypes = {}

--- Wired to `FileType` (see `lua/plugins/astrocore.lua`). Works out what this
--- filetype is missing via `resolve_installs` and kicks off async installs.
---
--- The declared set is what an AstroCommunity pack or a bundle actually asked
--- for, captured in `lazy_setup.lua` before the policy overwrite replaces the
--- list. It is deliberately *not* "does lspconfig ship a default config for
--- this server": nearly every server lspconfig knows about would pass that
--- check, which is not "configured" in any meaningful sense -- it let one Go
--- file pull in `harper_ls`, a general grammar server with nothing to do with
--- Go. If nothing has been declared yet, this resolves to an empty set and
--- nothing installs.
---
--- Fails silently throughout: a broken Mason install, an offline machine, or a
--- missing integration plugin must never block opening a file or spam
--- notifications.
---@param filetype string
---@param bufnr integer the buffer that fired `FileType`
function M.install_for_filetype(filetype, bufnr)
  if filetype == "" or seen_filetypes[filetype] then return end

  -- Real files only. `help`, `lazy`, `TelescopePrompt` and every other
  -- scratch buffer fire FileType too, and a session that only ever opens
  -- those has no business touching Mason.
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return end
  if vim.bo[bufnr].buftype ~= "" or vim.api.nvim_buf_get_name(bufnr) == "" then return end

  -- Nothing can act yet: no integration has loaded and nothing is attributed
  -- to this filetype. Bail before touching mason-registry, which would drag
  -- mason.nvim in for no reason. Deliberately not marked seen -- an
  -- integration loading later must get another chance.
  local possible = #M.get_on_demand(filetype) > 0
  for _, adapter in pairs(adapters) do
    possible = possible or package.loaded[adapter.module] ~= nil
  end
  if not possible then return end

  local ok_registry, registry = pcall(require, "mason-registry")
  if not ok_registry then return end

  local ok_installed, installed_names = pcall(registry.get_installed_package_names)
  local installed = {}
  if ok_installed then
    for _, name in ipairs(installed_names) do
      installed[name] = true
    end
  end

  local packages = M.resolve_installs(filetype, installed)
  if #packages == 0 then
    seen_filetypes[filetype] = true
    return
  end

  -- Marked before installing so buffers opened while these are still running
  -- do not start a second batch; cleared again below if anything failed, so an
  -- offline first run can retry rather than poisoning the filetype until
  -- Neovim restarts.
  seen_filetypes[filetype] = true

  -- lspconfig only attaches on *future* FileType events, so a server that
  -- finishes installing after this buffer already opened would otherwise sit
  -- unused until the next file of the same type. Re-fire FileType on
  -- already-open buffers of this filetype once every install in this batch
  -- has settled (succeeded or failed) -- once, not once per package, so N
  -- servers for one filetype cost one extra pass over the buffer rather than
  -- N.
  local pending, failed = #packages, false
  local function settle()
    pending = pending - 1
    if pending > 0 then return end
    if failed then seen_filetypes[filetype] = nil end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == filetype then
        pcall(vim.api.nvim_exec_autocmds, "FileType", { buffer = buf, modeline = false })
      end
    end
  end

  for _, pkg_name in ipairs(packages) do
    local ok_pkg, pkg = pcall(registry.get_package, pkg_name)
    local started = false
    if ok_pkg then
      local ok_install, handle = pcall(function() return pkg:install() end)
      if ok_install and handle then
        handle:once(
          "closed",
          vim.schedule_wrap(function()
            local ok_check, is_installed = pcall(function() return pkg:is_installed() end)
            if not (ok_check and is_installed) then failed = true end
            settle()
          end)
        )
        started = true
      end
    end
    if not started then
      failed = true
      settle()
    end
  end
end

return M
