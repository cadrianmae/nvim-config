# Language Bundles and On-Demand Tooling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure this AstroNvim config so each language stack lives in one deletable file, and language tooling installs on first use instead of up front.

**Architecture:** A plain Lua module (`lua/lang_policy.lua`) holds an editor-wide baseline of tooling that must always be installed, plus an accumulator that language bundles register with when they want eager installation. Final `opts` functions in `lazy_setup.lua` overwrite the `ensure_installed` lists of nvim-treesitter, mason-lspconfig, mason-null-ls and mason-nvim-dap with the resolved result, beating the appends contributed by AstroCommunity packs. Language specs move from `lua/community.lua` and scattered `lua/plugins/*.lua` files into `lua/plugins/lang/<stack>.lua`.

**Tech Stack:** Neovim 0.11.6, AstroNvim v4, lazy.nvim, nvim-treesitter (master branch), mason-lspconfig v1.32.0, stylua, selene.

## Global Constraints

- Neovim 0.11.6; nvim-treesitter on `master` branch (has `auto_install`); mason-lspconfig v1.32.0 (has `automatic_installation`). Do not upgrade any of these as part of this work.
- Unix line endings only, enforced in `polish.lua`.
- Lua style per `.stylua.toml`: 120 column width, 2-space indent, double quotes preferred, `call_parentheses = "None"` — write `require "lang_policy"`, not `require("lang_policy")`, when the sole argument is a string or table literal.
- Lint per `selene.toml` with `std = "neovim"`.
- No emoji or non-keyboard characters in code or committed files. Use `[OK]`, `[WARN]`, `[INFO]`, `[ERROR]` tags if status output is needed.
- Plugin specs must use full `"author/repo"` paths, never shorthand.
- British English in comments and documentation.
- Every task ends with a commit. Work on a branch, not `main`.
- Startup is a regression guard: `~/.config/nvim` must stay at or below 101 ms, `snappy-fyp` at or below 130 ms. Measure with `nvim --startuptime <file> +qa </dev/null`, three-run average. `--startuptime` produces no output under `--headless`.

---

## File Structure

**Created:**
- `lua/lang_policy.lua` — baseline tooling lists, eager accumulator, resolver. Plain module, not a lazy spec. Must live outside `lua/plugins/lang/` because lazy imports every `.lua` in that directory as a spec.
- `tests/lang_policy_spec.lua` — assertion script for the resolver, run via `nvim -l`.
- `lua/plugins/lang/*.lua` — one file per language stack. Specs only.

**Modified:**
- `lua/lazy_setup.lua` — adds `{ import = "plugins.lang" }` and the four overwrite specs.
- `lua/community.lua` — language packs move out; non-language imports stay.
- `lua/plugins/mason.lua`, `lua/plugins/treesitter.lua` — language entries move into bundles.
- `lua/plugins/astrocore.lua` — receives the `exrc` option.

**Deleted:**
- `lua/plugins/godotdev.lua`, `lua/plugins/basedpyright.lua`, `lua/plugins/prolog.lua`, `lua/plugins/r.lua`, `lua/plugins/minecraft-datapack.lua`, `lua/plugins/cql-filetype.lua` — contents move into bundles.

---

## Task 1: Policy module with tests

**Files:**
- Create: `lua/lang_policy.lua`
- Test: `tests/lang_policy_spec.lua`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `M.baseline` — table with keys `treesitter`, `lsp`, `tools`, `dap`, each a `string[]`.
  - `M.eager(spec: table<string, string[]>)` — registers tooling for eager install. Errors on an unknown category key.
  - `M.resolve(key: string): string[]` — baseline plus registered eager entries for that category, deduplicated and sorted.
  - `M._reset()` — clears the accumulator. Test-only.

- [ ] **Step 1: Create the branch**

```bash
cd ~/.config/nvim
git checkout -b feat/language-bundles
```

- [ ] **Step 2: Write the failing test**

Create `tests/lang_policy_spec.lua`:

```lua
-- Run with: nvim -l tests/lang_policy_spec.lua
-- Exits non-zero on the first failed assertion.
vim.opt.rtp:prepend(vim.fn.getcwd())

local policy = require "lang_policy"

local failures = 0

local function check(name, got, want)
  if vim.deep_equal(got, want) then
    print("[OK]   " .. name)
  else
    failures = failures + 1
    print("[FAIL] " .. name)
    print("  want: " .. vim.inspect(want))
    print("  got:  " .. vim.inspect(got))
  end
end

local function check_error(name, fn)
  if pcall(fn) then
    failures = failures + 1
    print("[FAIL] " .. name .. " (expected an error, none raised)")
  else
    print("[OK]   " .. name)
  end
end

policy._reset()
policy.baseline = { treesitter = { "lua", "bash" }, lsp = { "lua_ls" }, tools = {}, dap = {} }

check("resolve returns the baseline when nothing is registered", policy.resolve "treesitter", { "bash", "lua" })

policy.eager { treesitter = { "c" }, lsp = { "clangd" } }
check("eager entries are added to the baseline", policy.resolve "treesitter", { "bash", "c", "lua" })
check("eager entries land in the right category", policy.resolve "lsp", { "clangd", "lua_ls" })

policy.eager { treesitter = { "c" } }
check("duplicate registrations are collapsed", policy.resolve "treesitter", { "bash", "c", "lua" })

check("an empty category resolves to an empty list", policy.resolve "dap", {})

check_error("registering an unknown category raises", function() policy.eager { nonsense = { "x" } } end)

policy._reset()
check("_reset clears registered entries", policy.resolve "treesitter", { "bash", "lua" })

if failures > 0 then
  print(("\n%d test(s) failed"):format(failures))
  vim.cmd "cquit 1"
end
print "\nall tests passed"
```

- [ ] **Step 3: Run the test to verify it fails**

```bash
cd ~/.config/nvim && nvim -l tests/lang_policy_spec.lua
```

Expected: failure loading `lang_policy` — the module does not exist yet.

- [ ] **Step 4: Write the implementation**

Create `lua/lang_policy.lua`:

```lua
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
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
cd ~/.config/nvim && nvim -l tests/lang_policy_spec.lua
```

Expected: seven `[OK]` lines and `all tests passed`.

- [ ] **Step 6: Lint and format**

```bash
cd ~/.config/nvim
stylua lua/lang_policy.lua tests/lang_policy_spec.lua --check
selene lua/lang_policy.lua
```

Expected: both clean. If stylua reports a diff, run it with `--write` and re-run the test.

- [ ] **Step 7: Commit**

```bash
cd ~/.config/nvim
git add lua/lang_policy.lua tests/lang_policy_spec.lua
git commit -m "feat(nvim): add lang_policy module for tooling install policy"
```

---

## Task 2: Wire the overwrite specs, changing no behaviour

The point of this task is to prove the overwrite beats the packs *before* anything depends on it. `ensure_installed` is populated with exactly what is installed today, so a correct implementation changes nothing observable.

**Files:**
- Modify: `lua/lazy_setup.lua`

**Interfaces:**
- Consumes: `lang_policy.baseline`, `lang_policy.resolve` from Task 1.
- Produces: four `opts` functions that set `ensure_installed` on `nvim-treesitter`, `mason-lspconfig.nvim`, `mason-null-ls.nvim` and `mason-nvim-dap.nvim`.

- [ ] **Step 1: Record the current state**

```bash
cd ~/.config/nvim
nvim --headless "+lua local r = require('mason-registry'); print(#r.get_installed_package_names())" +qa 2>&1 | tail -1
```

Write the number down. It should be 40. Then record startup:

```bash
cd ~/.config/nvim
for i in 1 2 3; do nvim --startuptime /tmp/st.log +qa </dev/null >/dev/null 2>&1; grep 'NVIM STARTED' /tmp/st.log | awk '{print $1}'; done
```

- [ ] **Step 2: Set the baseline to today's contents**

Edit `lua/lang_policy.lua` so `M.baseline` matches what is installed right now. This is temporary — Task 3 shrinks it.

```lua
M.baseline = {
  treesitter = { "lua", "vim", "vimdoc", "markdown", "markdown_inline", "bash", "c", "dockerfile", "gdscript", "mermaid" },
  lsp = { "lua_ls", "clangd", "dockerls", "marksman" },
  tools = { "stylua", "hadolint", "prettierd", "markdownlint-cli2" },
  dap = { "python", "codelldb" },
}
```

- [ ] **Step 3: Add the import line and overwrite specs**

In `lua/lazy_setup.lua`, replace the spec list passed to `require("lazy").setup` so it reads:

```lua
local policy = require "lang_policy"

require("lazy").setup({
  {
    "AstroNvim/AstroNvim",
    version = "^4",
    import = "astronvim.plugins",
    opts = {
      mapleader = " ",
      maplocalleader = ",",
      icons_enabled = true,
      pin_plugins = nil,
      update_notifications = true,
    },
  },
  { import = "community" },
  { import = "plugins" },
  { import = "plugins.lang" },

  -- Install policy, applied last so it overwrites the entries appended by the
  -- AstroCommunity packs. See lua/lang_policy.lua.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts) opts.ensure_installed = policy.resolve "treesitter" end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts) opts.ensure_installed = policy.resolve "lsp" end,
  },
  {
    "jay-babu/mason-null-ls.nvim",
    opts = function(_, opts) opts.ensure_installed = policy.resolve "tools" end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = function(_, opts) opts.ensure_installed = policy.resolve "dap" end,
  },
} --[[@as LazySpec]], {
```

Leave the second argument to `setup` (the `install`/`ui`/`performance` table) exactly as it is.

- [ ] **Step 4: Create the directory so the import resolves**

An import of an empty or missing module is an error in lazy. Create a placeholder bundle that does nothing yet:

```bash
cd ~/.config/nvim && mkdir -p lua/plugins/lang
```

Create `lua/plugins/lang/init.lua`:

```lua
-- Language bundles live in this directory, one file per language stack.
-- Adding a language means adding a file here; removing one means deleting it.
-- See docs/superpowers/specs/2026-07-25-language-bundles-design.md
return {}
```

- [ ] **Step 5: Verify nothing changed**

```bash
cd ~/.config/nvim
nvim --headless "+Lazy! check" +qa 2>&1 | tail -20
nvim --headless "+lua local r = require('mason-registry'); print(#r.get_installed_package_names())" +qa 2>&1 | tail -1
```

Expected: no errors, and the same package count recorded in Step 1.

Then confirm the overwrite actually took effect rather than silently doing nothing:

```bash
cd ~/.config/nvim
nvim --headless "+Lazy! load nvim-treesitter" "+lua print(vim.inspect(require('lazy.core.config').plugins['nvim-treesitter'].opts.ensure_installed))" +qa 2>&1 | tail -5
```

Expected: exactly the ten parsers from Step 2, in sorted order. If the list contains extra entries such as `go` or `typescript`, the packs are winning — see the fallback below.

**If the overwrite loses:** AstroLSP does its own Mason wiring. Move the `mason-lspconfig` and `mason-null-ls` overwrites into an `"AstroNvim/astrolsp"` spec's `opts` function instead, keeping the same `policy.resolve` calls. Record which insertion point worked in a comment.

- [ ] **Step 6: Check startup has not regressed**

```bash
cd ~/.config/nvim
for i in 1 2 3; do nvim --startuptime /tmp/st.log +qa </dev/null >/dev/null 2>&1; grep 'NVIM STARTED' /tmp/st.log | awk '{print $1}'; done
```

Expected: within a few ms of Step 1, and at or below 101 ms.

- [ ] **Step 7: Commit**

```bash
cd ~/.config/nvim
git add lua/lazy_setup.lua lua/lang_policy.lua lua/plugins/lang/init.lua
git commit -m "feat(nvim): apply tooling install policy from lazy_setup

No behaviour change: ensure_installed is populated with exactly what is
installed today. This proves the overwrite specs beat the entries appended
by the AstroCommunity packs before anything depends on that."
```

---

## Task 3: Flip to on-demand installation

**Files:**
- Modify: `lua/lang_policy.lua`, `lua/lazy_setup.lua`

**Interfaces:**
- Consumes: the overwrite specs from Task 2.
- Produces: `auto_install = true` on nvim-treesitter, `automatic_installation = true` on mason-lspconfig.

- [ ] **Step 1: Shrink the baseline to the eager tier**

In `lua/lang_policy.lua`, replace `M.baseline` with the final version:

```lua
M.baseline = {
  treesitter = { "lua", "vim", "vimdoc", "markdown", "markdown_inline", "bash" },
  lsp = { "lua_ls", "marksman" },
  tools = { "stylua", "prettierd", "markdownlint-cli2" },
  dap = {},
}
```

C tooling is not listed here — it is registered by `lua/plugins/lang/c.lua` in Task 6, which is what keeps clangd and codelldb eager.

- [ ] **Step 2: Enable on-demand installation**

In `lua/lazy_setup.lua`, extend two of the four overwrite specs:

```lua
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = policy.resolve "treesitter"
      opts.auto_install = true -- parsers compile on first open of that filetype
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = policy.resolve "lsp"
      opts.automatic_installation = true -- servers install on first attach
    end,
  },
```

- [ ] **Step 3: Verify the lists shrank**

```bash
cd ~/.config/nvim
nvim --headless "+Lazy! load nvim-treesitter" "+lua local o = require('lazy.core.config').plugins['nvim-treesitter'].opts; print(vim.inspect(o.ensure_installed)); print('auto_install:', o.auto_install)" +qa 2>&1 | tail -10
```

Expected: the six baseline parsers and `auto_install: true`.

- [ ] **Step 4: Verify on-demand actually installs**

Pick a language with no bundle yet and no installed server. Go is a good choice — its tooling is currently installed, so uninstall it first to get a true test:

```bash
cd ~/.config/nvim
nvim --headless "+MasonUninstall gopls" +qa 2>&1 | tail -3
cd /home/cadrianmae/git/github.com/cadrianmae/pur
nvim --headless "+e main.go" "+sleep 30" "+lua print('clients:', vim.inspect(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients())))" +qa 2>&1 | tail -5
```

Expected: gopls installs and appears in the client list. If it does not attach within 30 seconds, check `:MasonLog` — a slow download is not a failure, but a silent no-op is.

**If `automatic_installation` does not install:** the fallback is to keep a larger eager list. Add the servers you actually need to `M.baseline.lsp` and note in a comment that mason-lspconfig v1.32.0 did not honour the setting in this configuration.

- [ ] **Step 4b: Add the FileType-driven installer**

Amendment, added after Step 4 established that mason-lspconfig v1.32.0's
`automatic_installation` does not fire in this configuration. Its
`lspconfig_hook` only triggers for servers something already configures, and the
on-demand design is precisely what removed those declarations. The plan's
original fallback (a larger eager list) was rejected — it would abandon the
disk saving, which lives almost entirely in the servers.

The replacement is ours: when a filetype is first opened, install the Mason
package for any server that is *configured for that filetype but not installed*.
Bundles decide *which* server; this decides *when* it arrives.

Split it into a pure function and a thin autocmd, so the selection logic is
testable without running Mason.

Add to `lua/lang_policy.lua`:

```lua
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
```

Then wire it. The autocmd stays thin — it gathers the four inputs and calls the
pure function. Guard against repeat work with a per-filetype seen table, and
fail silently when Mason or mason-lspconfig is unavailable, so a broken install
never blocks opening a file.

Required behaviour:
- Runs on `FileType`, once per filetype per session.
- Installs asynchronously; opening a file must not block.
- Never installs a server the config does not configure.
- No error, notification storm, or stack trace when offline.

Test cases to add to `tests/lang_policy_spec.lua`, using a stub `to_package`:

```lua
local function to_package(server)
  return ({ gopls = "gopls", basedpyright = "basedpyright" })[server]
end

check(
  "installs a configured server that serves the filetype and is missing",
  policy.packages_to_install({ "gopls" }, { "gopls" }, {}, to_package),
  { "gopls" }
)
check(
  "skips a server that is already installed",
  policy.packages_to_install({ "gopls" }, { "gopls" }, { gopls = true }, to_package),
  {}
)
check(
  "skips a server that serves the filetype but is not configured",
  policy.packages_to_install({}, { "gopls" }, {}, to_package),
  {}
)
check(
  "skips a configured server that does not serve this filetype",
  policy.packages_to_install({ "basedpyright" }, { "gopls" }, {}, to_package),
  {}
)
check(
  "skips a server with no mason package",
  policy.packages_to_install({ "qmlls" }, { "qmlls" }, {}, to_package),
  {}
)
```

Verify end to end, exactly as Step 4 did — uninstall gopls, open a Go file, and
confirm it reinstalls without manual intervention. Remember to clear orphaned
copilot processes after each headless run: `pkill -f 'nvim/lazy/copilo[t]'`.

- [ ] **Step 5: Check startup**

```bash
cd ~/.config/nvim
for i in 1 2 3; do nvim --startuptime /tmp/st.log +qa </dev/null >/dev/null 2>&1; grep 'NVIM STARTED' /tmp/st.log | awk '{print $1}'; done
```

Expected: at or below 101 ms.

- [ ] **Step 6: Commit**

```bash
cd ~/.config/nvim
git add lua/lang_policy.lua lua/lazy_setup.lua
git commit -m "feat(nvim): install language tooling on first use

ensure_installed now means 'must work offline' rather than 'everything I
might use'. Treesitter parsers compile and Mason servers install when a
file of that type is first opened."
```

---

## Task 4: Move the least-used languages into bundles

Least-used first, so early breakage lands on a language not in active use.

**Files:**
- Create: `lua/plugins/lang/prolog.lua`, `lua/plugins/lang/r.lua`, `lua/plugins/lang/sql.lua`, `lua/plugins/lang/minecraft.lua`
- Delete: `lua/plugins/prolog.lua`, `lua/plugins/r.lua`, `lua/plugins/cql-filetype.lua`, `lua/plugins/minecraft-datapack.lua`
- Modify: `lua/community.lua`, `lua/plugins/astrocore.lua`

**Interfaces:**
- Consumes: `lang_policy.eager` from Task 1 (unused in this task — all four are on-demand).
- Produces: four bundle files. No new symbols.

- [ ] **Step 1: Move Prolog**

```bash
cd ~/.config/nvim && git mv lua/plugins/prolog.lua lua/plugins/lang/prolog.lua
```

Add a header comment to the moved file explaining the bundle contract:

```lua
-- Prolog: SWI-Prolog LSP, hand-wired because AstroCommunity has no Prolog pack.
-- On-demand: nothing installs until a .pl, .pro or .P file is opened.
```

- [ ] **Step 2: Verify Prolog still works**

```bash
cd ~/.config/nvim
nvim --headless "+Lazy! check" +qa 2>&1 | tail -10
echo ':- initialization(main).' > /tmp/probe.pl
nvim --headless "+e /tmp/probe.pl" "+lua print('ft:', vim.bo.filetype)" +qa 2>&1 | tail -2
```

Expected: no errors, `ft: prolog`.

- [ ] **Step 3: Move R and Quarto**

```bash
cd ~/.config/nvim && git mv lua/plugins/r.lua lua/plugins/lang/r.lua
```

Move the Quarto pack import out of `lua/community.lua` — delete this line:

```lua
  { import = "astrocommunity.pack.quarto" }, -- Quarto + R treesitter
```

and add it at the top of the spec list returned by `lua/plugins/lang/r.lua`:

```lua
-- R and Quarto: otter.nvim handles embedded code blocks in .qmd files.
-- On-demand: nothing installs until an .R or .qmd file is opened.
return {
  { import = "astrocommunity.pack.quarto" },
  -- ... existing otter.nvim and astrolsp specs, unchanged ...
}
```

- [ ] **Step 4: Verify R**

```bash
cd ~/.config/nvim
nvim --headless "+Lazy! check" +qa 2>&1 | tail -10
echo 'x <- 1' > /tmp/probe.R
nvim --headless "+e /tmp/probe.R" "+lua print('ft:', vim.bo.filetype)" +qa 2>&1 | tail -2
```

Expected: no errors, `ft: r`.

- [ ] **Step 5: Move SQL and CQL**

```bash
cd ~/.config/nvim && git mv lua/plugins/cql-filetype.lua lua/plugins/lang/sql.lua
```

Delete from `lua/community.lua`:

```lua
  { import = "astrocommunity.pack.sql" },
```

Add to the top of the spec list in `lua/plugins/lang/sql.lua`:

```lua
-- SQL and CQL: SQL pack plus Cassandra CQL filetype detection.
-- On-demand: nothing installs until a .sql or .cql file is opened.
return {
  { import = "astrocommunity.pack.sql" },
  -- ... existing CQL filetype specs, unchanged ...
}
```

- [ ] **Step 6: Move the Minecraft datapack support, leaving `exrc` behind**

```bash
cd ~/.config/nvim && git mv lua/plugins/minecraft-datapack.lua lua/plugins/lang/minecraft.lua
```

`lua/plugins/lang/minecraft.lua` currently sets a global editor option. Remove the `exrc` entry from its astrocore `opts.options.opt` block, and add it to `lua/plugins/astrocore.lua` in that plugin's `opts.options.opt` table:

```lua
        exrc = true, -- read project-local .nvim.lua (cwd only, no upward search)
```

Leave everything else in the Minecraft file alone.

- [ ] **Step 7: Verify Minecraft and `exrc`**

```bash
cd ~/.config/nvim
nvim --headless "+Lazy! check" +qa 2>&1 | tail -10
nvim --headless "+lua print('exrc:', vim.o.exrc)" +qa 2>&1 | tail -2
mkdir -p /tmp/dp/data/test/function && echo 'say hi' > /tmp/dp/data/test/function/probe.mcfunction
nvim --headless "+e /tmp/dp/data/test/function/probe.mcfunction" "+lua print('ft:', vim.bo.filetype)" +qa 2>&1 | tail -2
```

Expected: no errors, `exrc: true`, and the mcfunction filetype detected.

- [ ] **Step 8: Lint and commit**

```bash
cd ~/.config/nvim
stylua lua/ --check && selene lua/
git add -A
git commit -m "refactor(nvim): move prolog, r, sql and minecraft into lang bundles

Each language stack now owns one file under lua/plugins/lang/. The global
exrc option moves from the minecraft file to astrocore, where it belongs."
```

---

## Task 5: Move the mid-tier languages

**Files:**
- Create: `lua/plugins/lang/go.lua`, `lua/plugins/lang/godot.lua`, `lua/plugins/lang/web.lua`, `lua/plugins/lang/docker.lua`
- Delete: `lua/plugins/godotdev.lua`
- Modify: `lua/community.lua`, `lua/plugins/mason.lua`, `lua/plugins/treesitter.lua`

**Interfaces:**
- Consumes: nothing new.
- Produces: four bundle files. No new symbols.

- [ ] **Step 1: Create the Go bundle**

Create `lua/plugins/lang/go.lua`:

```lua
-- Go: gopls, delve, and the gopher.nvim helpers from the pack.
-- On-demand: nothing installs until a .go file is opened.
---@type LazySpec
return {
  { import = "astrocommunity.pack.go" },
}
```

Delete from `lua/community.lua`:

```lua
  { import = "astrocommunity.pack.go" },
```

- [ ] **Step 2: Create the Godot bundle and drop the dead file**

Create `lua/plugins/lang/godot.lua`:

```lua
-- Godot: gdscript LSP and gdtoolkit formatting.
-- On-demand: nothing installs until a .gd file is opened.
---@type LazySpec
return {
  { import = "astrocommunity.pack.godot" },
}
```

Delete from `lua/community.lua`:

```lua
  { import = "astrocommunity.pack.godot" },
```

Delete the dead override file, which has been short-circuited with `if true then return {} end` since it was written:

```bash
cd ~/.config/nvim && git rm lua/plugins/godotdev.lua
```

Also remove `"gdscript"` from `ensure_installed` in `lua/plugins/treesitter.lua` — the pack provides it, and it is on-demand now.

- [ ] **Step 3: Create the web bundle**

Create `lua/plugins/lang/web.lua`:

```lua
-- Web: TypeScript, JavaScript, HTML and CSS via vtsls.
-- On-demand: nothing installs until a .ts, .tsx, .js or .jsx file is opened.
---@type LazySpec
return {
  { import = "astrocommunity.pack.typescript" },
}
```

Delete from `lua/community.lua`:

```lua
  { import = "astrocommunity.pack.typescript" },
```

- [ ] **Step 4: Create the Docker bundle**

Docker tooling is currently declared directly in `lua/plugins/mason.lua` and
`lua/plugins/treesitter.lua`. Once the policy overwrite is in place those
entries are discarded, so Docker needs a bundle like any other stack.

Create `lua/plugins/lang/docker.lua`:

```lua
-- Docker: dockerls and hadolint for Dockerfile and Containerfile.
-- On-demand: nothing installs until a Dockerfile is opened.
---@type LazySpec
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then vim.list_extend(opts.ensure_installed, { "dockerfile" }) end
    end,
  },
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      servers = { "dockerls" },
    },
  },
}
```

Remove `"dockerls"` from the `mason-lspconfig.nvim` `ensure_installed` list in
`lua/plugins/mason.lua`, `"hadolint"` from the `mason-null-ls.nvim` list, and
`"dockerfile"` from `lua/plugins/treesitter.lua`. hadolint installs on demand
through none-ls when a Dockerfile is opened.

Verify:

```bash
cd ~/.config/nvim
printf 'FROM alpine\n' > /tmp/Dockerfile
nvim --headless "+e /tmp/Dockerfile" "+lua print('ft:', vim.bo.filetype)" +qa 2>&1 | tail -2
```

Expected: `ft: dockerfile`.

- [ ] **Step 5: Verify all three language bundles**

```bash
cd ~/.config/nvim
nvim --headless "+Lazy! check" +qa 2>&1 | tail -10
printf 'package main\n' > /tmp/probe.go
printf 'extends Node\n' > /tmp/probe.gd
printf 'const x: number = 1\n' > /tmp/probe.ts
for f in /tmp/probe.go /tmp/probe.gd /tmp/probe.ts; do
  nvim --headless "+e $f" "+lua print('$f ft:', vim.bo.filetype)" +qa 2>&1 | tail -1
done
```

Expected: no errors and `go`, `gdscript`, `typescript` respectively.

- [ ] **Step 6: Lint and commit**

```bash
cd ~/.config/nvim
stylua lua/ --check && selene lua/
git add -A
git commit -m "refactor(nvim): move go, godot, web and docker into lang bundles

Also removes plugins/godotdev.lua, which has been dead code behind an
'if true then return {} end' guard since it was added."
```

---

## Task 6: Move the daily-driver languages

These are the ones in active use, moved last. C is the only eager bundle.

**Files:**
- Create: `lua/plugins/lang/c.lua`, `lua/plugins/lang/python.lua`, `lua/plugins/lang/lua.lua`, `lua/plugins/lang/markdown.lua`
- Delete: `lua/plugins/basedpyright.lua`
- Modify: `lua/community.lua`, `lua/plugins/mason.lua`, `lua/plugins/treesitter.lua`

**Interfaces:**
- Consumes: `lang_policy.eager` from Task 1.
- Produces: four bundle files. `c.lua` registers `{ lsp = { "clangd" }, treesitter = { "c" }, dap = { "codelldb" } }`.

- [ ] **Step 1: Create the C bundle, eager**

Create `lua/plugins/lang/c.lua`:

```lua
-- C: clangd and codelldb. Eager rather than on-demand -- this is coursework
-- tooling that has to work without a network connection.
require("lang_policy").eager {
  lsp = { "clangd" },
  treesitter = { "c" },
  dap = { "codelldb" },
}

---@type LazySpec
return {
  { import = "astrocommunity.pack.cpp" },
}
```

Delete from `lua/community.lua`:

```lua
  { import = "astrocommunity.pack.cpp" },
```

Remove `"clangd"` from `ensure_installed` in the `mason-lspconfig.nvim` spec in `lua/plugins/mason.lua`, `"codelldb"` from the `mason-nvim-dap.nvim` spec, and `"c"` from `lua/plugins/treesitter.lua`. They are now supplied by the eager registration above.

- [ ] **Step 2: Create the Python bundle**

Move the basedpyright override in:

```bash
cd ~/.config/nvim && git mv lua/plugins/basedpyright.lua lua/plugins/lang/python.lua
```

Delete from `lua/community.lua`:

```lua
  { import = "astrocommunity.pack.python" }, -- pyright + ruff + black
```

Add the pack import to `lua/plugins/lang/python.lua`, above the existing astrolsp spec, and update the header comment:

```lua
-- Python: the pack provides pyright, ruff and black; this overrides pyright
-- with basedpyright. See https://docs.astronvim.com/recipes/advanced_lsp/
-- On-demand: nothing installs until a .py file is opened.
---@type LazySpec
return {
  { import = "astrocommunity.pack.python" },
  -- ... existing astrolsp spec disabling pyright, unchanged ...
}
```

Remove `"python"` from the `mason-nvim-dap.nvim` `ensure_installed` list in `lua/plugins/mason.lua` — debugpy now installs on demand.

- [ ] **Step 3: Create the Lua bundle, eager by baseline**

Create `lua/plugins/lang/lua.lua`:

```lua
-- Lua: needed to edit this config, so lua_ls and stylua are in the
-- lang_policy baseline rather than registered here.
---@type LazySpec
return {
  { import = "astrocommunity.pack.lua" },
}
```

Delete from `lua/community.lua`:

```lua
  { import = "astrocommunity.pack.lua" },
```

Remove `"lua_ls"` from `ensure_installed` in `lua/plugins/mason.lua` and `"stylua"` from the `mason-null-ls.nvim` list — both are in the baseline. Remove `"lua"` and `"vim"` from `lua/plugins/treesitter.lua` for the same reason.

- [ ] **Step 4: Create the Markdown bundle**

Create `lua/plugins/lang/markdown.lua`:

```lua
-- Markdown: the pack plus the render, preview and TOC plugins. Parsers and
-- marksman are in the lang_policy baseline -- markdown is used in nearly every
-- repo, so it must work offline.
--
-- The `ft` keys that used to sit on these import blocks were no-ops: lazy's
-- Spec:import reads only `import`, `name`, `cond` and `enabled`, and discards
-- everything else. Lazy-loading is whatever each pack declares internally.
---@type LazySpec
return {
  { import = "astrocommunity.pack.markdown" },
  { import = "astrocommunity.markdown-and-latex.render-markdown-nvim" },
  { import = "astrocommunity.markdown-and-latex.glow-nvim" },
  { import = "astrocommunity.markdown-and-latex.markdown-preview-nvim" },
}
```

Delete those four imports from `lua/community.lua`, including their now-removed `ft` keys. Leave `astrocommunity.note-taking.obsidian-nvim` and `astrocommunity.editing-support.zen-mode-nvim` in `community.lua` — they are note-taking and editing plugins, not language support — but delete their `ft` keys, which are equally inert.

Remove `"markdownlint-cli2"` and `"prettierd"` from `lua/plugins/mason.lua` if present; they are in the baseline.

- [ ] **Step 5: Verify the eager registration resolved**

```bash
cd ~/.config/nvim
nvim --headless "+lua local p = require 'lang_policy'; print('lsp:', vim.inspect(p.resolve 'lsp')); print('dap:', vim.inspect(p.resolve 'dap')); print('ts:', vim.inspect(p.resolve 'treesitter'))" +qa 2>&1 | tail -6
```

Expected: `lsp` contains `clangd`, `lua_ls`, `marksman`; `dap` contains `codelldb`; `treesitter` contains `c` alongside the baseline six.

- [ ] **Step 6: Verify each language opens**

```bash
cd ~/.config/nvim
nvim --headless "+Lazy! check" +qa 2>&1 | tail -10
printf 'int main(void){return 0;}\n' > /tmp/probe.c
printf 'x = 1\n' > /tmp/probe.py
printf '# hi\n' > /tmp/probe.md
for f in /tmp/probe.c /tmp/probe.py /tmp/probe.md; do
  nvim --headless "+e $f" "+sleep 3" "+lua print('$f', vim.bo.filetype, vim.inspect(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients { bufnr = 0 })))" +qa 2>&1 | tail -1
done
```

Expected: `c` with clangd attached, `python` with basedpyright, `markdown` with marksman.

- [ ] **Step 7: Check startup and package count**

```bash
cd ~/.config/nvim
for i in 1 2 3; do nvim --startuptime /tmp/st.log +qa </dev/null >/dev/null 2>&1; grep 'NVIM STARTED' /tmp/st.log | awk '{print $1}'; done
nvim --headless "+lua local r = require('mason-registry'); print(#r.get_installed_package_names())" +qa 2>&1 | tail -1
```

Expected: startup at or below 101 ms. The package count will still be high — nothing has been uninstalled yet; Task 8 does that.

- [ ] **Step 8: Lint and commit**

```bash
cd ~/.config/nvim
stylua lua/ --check && selene lua/
git add -A
git commit -m "refactor(nvim): move c, python, lua and markdown into lang bundles

C registers its tooling as eager via lang_policy so clangd and codelldb stay
installed for offline coursework. Also drops the inert ft keys from import
blocks -- lazy's Spec:import discards every key except import, name, cond
and enabled."
```

---

## Task 7: Add the JVM and QML bundles

**Files:**
- Create: `lua/plugins/lang/jvm.lua`, `lua/plugins/lang/qml.lua`

**Interfaces:**
- Consumes: nothing new.
- Produces: two bundle files. No new symbols.

- [ ] **Step 1: Create the JVM bundle**

Create `lua/plugins/lang/jvm.lua`:

```lua
-- JVM: Java, Kotlin and Gradle, for Minecraft mod work. One bundle rather than
-- two files because they arrive together and share the build tooling -- a
-- build.gradle.kts belongs to both.
-- On-demand: jdtls is one of the largest Mason packages, so it stays
-- uninstalled until a .java or .kt file is opened.
---@type LazySpec
return {
  { import = "astrocommunity.pack.java" },
  { import = "astrocommunity.pack.kotlin" },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then vim.list_extend(opts.ensure_installed, { "groovy" }) end
    end,
  },
}
```

Note: the `groovy` parser is for `build.gradle`. The `kotlin` parser for `build.gradle.kts` comes from the Kotlin pack. This `opts` function appends rather than overwrites, and runs before the policy overwrite in `lazy_setup.lua` — so `groovy` will be dropped unless it is also eager. That is intended: it installs on demand when a `.gradle` file is opened.

- [ ] **Step 2: Verify the JVM bundle loads**

```bash
cd ~/.config/nvim
nvim --headless "+Lazy! check" +qa 2>&1 | tail -10
printf 'public class P {}\n' > /tmp/probe.java
printf 'fun main() {}\n' > /tmp/probe.kt
for f in /tmp/probe.java /tmp/probe.kt; do
  nvim --headless "+e $f" "+lua print('$f ft:', vim.bo.filetype)" +qa 2>&1 | tail -1
done
```

Expected: no errors, `java` and `kotlin`.

- [ ] **Step 3: Create the QML bundle**

There is no AstroCommunity QML pack, so this is hand-wired like Prolog. `qmlls` ships with Qt rather than Mason, so it is configured only if present on `PATH`.

Create `lua/plugins/lang/qml.lua`:

```lua
-- QML: used by the Plasma applet work. No AstroCommunity pack exists, and
-- qmlls ships with Qt rather than Mason, so the server is only registered when
-- it is actually on PATH.
---@type LazySpec
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then vim.list_extend(opts.ensure_installed, { "qmljs" }) end
    end,
  },
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      config = {
        qmlls = {
          cmd = { "qmlls" },
          filetypes = { "qml" },
          root_markers = { ".git" },
        },
      },
      servers = vim.fn.executable "qmlls" == 1 and { "qmlls" } or {},
    },
  },
}
```

- [ ] **Step 4: Verify QML**

```bash
cd ~/.config/nvim
nvim --headless "+Lazy! check" +qa 2>&1 | tail -10
printf 'import QtQuick\nItem {}\n' > /tmp/probe.qml
nvim --headless "+e /tmp/probe.qml" "+lua print('ft:', vim.bo.filetype, 'qmlls on PATH:', vim.fn.executable 'qmlls' == 1)" +qa 2>&1 | tail -2
```

Expected: no errors and `ft: qml`. If `qmlls` is not on `PATH`, the server is simply not registered — that is the designed behaviour, not a failure.

- [ ] **Step 5: Lint and commit**

```bash
cd ~/.config/nvim
stylua lua/ --check && selene lua/
git add -A
git commit -m "feat(nvim): add jvm and qml language bundles

JVM covers java, kotlin and gradle together for upcoming Minecraft mod work.
QML is hand-wired -- no AstroCommunity pack exists and qmlls ships with Qt,
so it registers only when the binary is on PATH."
```

---

## Task 8: Clean up orphans and verify the whole thing

**Files:**
- Modify: `lua/community.lua` (final tidy), `CLAUDE.md`
- Delete: stale `*.cloning` directories, orphaned Mason packages

**Interfaces:**
- Consumes: everything above.
- Produces: nothing new.

- [ ] **Step 1: Confirm `community.lua` has no language packs left**

```bash
cd ~/.config/nvim && grep -n "pack\." lua/community.lua
```

Expected: no output. Every `astrocommunity.pack.*` import should now live in a bundle.

- [ ] **Step 2: Remove stale clone directories**

```bash
ls -d ~/.local/share/nvim/lazy/*.cloning 2>/dev/null
```

Inspect what is listed, then remove them — they are leftovers from interrupted clones:

```bash
rm -rf ~/.local/share/nvim/lazy/*.cloning
```

- [ ] **Step 3: Uninstall orphaned Mason packages**

List what is installed but no longer required:

```bash
cd ~/.config/nvim
nvim --headless "+lua local r = require('mason-registry'); local n = r.get_installed_package_names(); table.sort(n); print(table.concat(n, ' '))" +qa 2>&1 | tail -2
```

Uninstall anything for a language with no bundle and no current use. Based on the design's evidence, that is the Java tooling only if the mod work has not started, and nothing else — Go, SQL, TypeScript, R and Prolog all have bundles and will reinstall on demand. Uninstall deliberately, one at a time:

```bash
cd ~/.config/nvim && nvim --headless "+MasonUninstall <package>" +qa
```

Do not batch-uninstall. Removing a package for a language with a bundle is harmless (it reinstalls on next open) but wastes a download.

- [ ] **Step 4: Full verification against the spec's targets**

```bash
cd ~/.config/nvim
echo "=== mason package count ==="
nvim --headless "+lua local r = require('mason-registry'); print(#r.get_installed_package_names())" +qa 2>&1 | tail -1
echo "=== mason disk ==="
du -sh ~/.local/share/nvim/mason
echo "=== startup, nvim config ==="
for i in 1 2 3; do nvim --startuptime /tmp/st.log +qa </dev/null >/dev/null 2>&1; grep 'NVIM STARTED' /tmp/st.log | awk '{print $1}'; done
echo "=== startup, snappy-fyp ==="
cd /home/cadrianmae/git/github.com/cadrianmae/snappy-fyp
for i in 1 2 3; do nvim --startuptime /tmp/st.log +qa </dev/null >/dev/null 2>&1; grep 'NVIM STARTED' /tmp/st.log | awk '{print $1}'; done
echo "=== policy test ==="
cd ~/.config/nvim && nvim -l tests/lang_policy_spec.lua
echo "=== lazy health ==="
nvim --headless "+Lazy! check" +qa 2>&1 | tail -20
```

Record the results against the spec targets: Mason at roughly 10 packages, startup at or below 101 ms and 130 ms respectively, policy tests passing, no lazy errors.

If startup regressed, find the cause before proceeding — `nvim --startuptime` output sorted by the second column shows the expensive lines.

- [ ] **Step 5: Document the new layout**

Add a section to `CLAUDE.md` under "Plugin Configuration Patterns":

```markdown
### Language Bundles

Each language stack owns one file in `lua/plugins/lang/`. Adding a language
means adding a file; removing one means deleting it. Nothing about a language
lives anywhere else.

```lua
-- lua/plugins/lang/rust.lua
---@type LazySpec
return {
  { import = "astrocommunity.pack.rust" },
}
```

Tooling installs on first use — opening a `.rs` file installs rust-analyzer and
compiles the parser. A bundle that must work offline registers itself eagerly
instead:

```lua
require("lang_policy").eager { lsp = { "clangd" }, treesitter = { "c" } }
```

Editor-wide tooling that is not tied to one language goes in `M.baseline` in
`lua/lang_policy.lua`.

Project-specific overrides use `.neoconf.json`, which `neoconf.nvim` finds by
searching upward from the file — so it applies from any subdirectory of the
project:

```json
{
  "lspconfig": {
    "sqls": false,
    "basedpyright": {
      "python.analysis.typeCheckingMode": "off"
    }
  }
}
```

Worked example — `~/git/github.com/cadrianmae/tu856-4/.neoconf.json`, applying
to every module directory beneath it:

```json
{
  "lspconfig": {
    "sqlfluff": {
      "dialect": "postgres"
    },
    "basedpyright": {
      "python.analysis.typeCheckingMode": "basic",
      "python.analysis.diagnosticSeverityOverrides": {
        "reportMissingImports": "warning"
      }
    }
  }
}
```

Use `.neoconf.json` for settings and for disabling a server in one project. Do
not move language *bundles* into a project's `.lazy.lua`: on-demand
installation already makes an unused global bundle free, while a project-scoped
spec is removed by `:Lazy sync` (which cleans) whenever Neovim is opened
elsewhere, and churns `lazy-lock.json` in this repository. Reserve `.lazy.lua`
for a plugin that genuinely only ever applies to one project.

Note: `ft`, `event` and `keys` do nothing on an `{ import = ... }` block. Lazy's
`Spec:import` reads only `import`, `name`, `cond` and `enabled`.

A project that needs its own plugin specs uses `.lazy.lua`, which lazy finds by
walking upward from the cwd, so it applies from any subdirectory:

```lua
-- <project>/.lazy.lua
vim.opt.rtp:prepend(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h"))
return { { import = "myprojplugins" } }   -- <project>/lua/myprojplugins/*.lua
```

Three constraints: only the first `.lazy.lua` found is used (no merging of
nested files); it is read through `vim.secure.read`, so the first open prompts
for trust; and the module directory must not be named `plugins`, because import
specs are deduplicated by module name and this config already imports `plugins`
— a collision is skipped silently, with no error.
```

- [ ] **Step 6: Commit and merge**

```bash
cd ~/.config/nvim
stylua lua/ --check && selene lua/
git add -A
git commit -m "chore(nvim): clean up orphans and document language bundles"
git checkout main
git merge --no-ff feat/language-bundles -m "feat(nvim): language bundles with on-demand tooling"
```

---

## Self-Review

**Spec coverage:**

| Spec section | Task |
|---|---|
| Language bundles, `plugins/lang/` layout | 4, 5, 6, 7 |
| `{ import = "plugins.lang" }` import line | 2 |
| Install policy, `auto_install` / `automatic_installation` | 3 |
| Overwrite mechanism beating pack appends | 2 (proved), 3 (relied on) |
| `lang_policy.lua` baseline plus accumulator | 1 |
| Per-bundle `eager` flag | 6 (C is the only eager bundle) |
| Project overrides via neoconf | 8 (documented; no code required) |
| Migration mapping table | 4, 5, 6 |
| `exrc` moves to astrocore | 4 |
| `godotdev.lua` deleted | 5 |
| Stale `*.cloning` directories removed | 8 |
| Mason orphans uninstalled | 8 |
| Verification metrics | 8 |
| Resolved `ft`-on-import finding | 6 (inert keys removed), 8 (documented) |

**Risks carried from the spec, each with an in-plan fallback:** AstroLSP re-adding servers (Task 2 Step 5), `automatic_installation` not firing (Task 3 Step 4), offline first-open (the eager tier), first-open pause (accepted).

**Not covered, deliberately:** the `copilot.lua` 771 MB finding. It is 71% of the lazy directory but unrelated to language support, so it is out of scope for this plan and left for a separate decision.
