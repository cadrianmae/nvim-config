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

-- Filetypes already handled this session, so opening several buffers of the
-- same type only triggers the install scan once.
---@type table<string, true>
local seen_filetypes = {}

--- Wired to `FileType` (see `lua/plugins/astrocore.lua`). Gathers the four
--- `packages_to_install` inputs from mason-lspconfig/mason-registry and
--- kicks off async installs for anything missing.
---
--- "Configured" means lspconfig ships a default config for the server (the
--- same check AstroLSP's generic mason-lspconfig handler performs before
--- calling `lspconfig[server].setup(...)`), since that catch-all handler is
--- what actually brings a newly-installed server up -- see
--- `mason-lspconfig.setup_handlers`, which already listens for
--- `package:install:success` and needs nothing further from us here.
---
--- Fails silently throughout: a broken Mason install, an offline machine, or
--- a missing mason-lspconfig must never block opening a file or spam
--- notifications.
---@param filetype string
function M.install_for_filetype(filetype)
  if filetype == "" or seen_filetypes[filetype] then return end
  seen_filetypes[filetype] = true

  local ok_mlsp, mason_lspconfig = pcall(require, "mason-lspconfig")
  local ok_registry, registry = pcall(require, "mason-registry")
  local ok_mapping, server_mapping = pcall(require, "mason-lspconfig.mappings.server")
  if not (ok_mlsp and ok_registry and ok_mapping) then return end

  local ok_serving, serving = pcall(mason_lspconfig.get_available_servers, { filetype = filetype })
  if not ok_serving or not serving or #serving == 0 then return end

  local configured = {}
  for _, server in ipairs(serving) do
    local ok_cfg, config = pcall(require, "lspconfig.configs." .. server)
    if ok_cfg and config and config.default_config then configured[#configured + 1] = server end
  end

  local ok_installed, installed_names = pcall(registry.get_installed_package_names)
  local installed = {}
  if ok_installed then
    for _, name in ipairs(installed_names) do
      installed[name] = true
    end
  end

  local function to_package(server) return server_mapping.lspconfig_to_package[server] end

  local packages = M.packages_to_install(configured, serving, installed, to_package)
  for _, pkg_name in ipairs(packages) do
    local ok_pkg, pkg = pcall(registry.get_package, pkg_name)
    if ok_pkg then
      pcall(function()
        -- lspconfig only attaches on *future* FileType events, so a server
        -- that finishes installing after this buffer already opened would
        -- otherwise sit unused until the next file of the same type. Re-fire
        -- FileType on already-open buffers of this filetype once the
        -- install closes, so the buffer that triggered it benefits too.
        pkg:install():once(
          "closed",
          vim.schedule_wrap(function()
            if not pkg:is_installed() then return end
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == filetype then
                pcall(vim.api.nvim_exec_autocmds, "FileType", { buffer = buf, modeline = false })
              end
            end
          end)
        )
      end)
    end
  end
end

return M
