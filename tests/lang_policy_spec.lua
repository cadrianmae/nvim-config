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

local function to_package(server) return ({ gopls = "gopls", basedpyright = "basedpyright" })[server] end

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
check("skips a server with no mason package", policy.packages_to_install({ "qmlls" }, { "qmlls" }, {}, to_package), {})

policy._reset()
policy.declare("lsp", { "gopls" })
check("declare records what a pack asked for", policy.get_declared "lsp", { "gopls" })

policy.declare("lsp", { "basedpyright" })
check("repeat declare calls are additive, not replacing", policy.get_declared "lsp", { "basedpyright", "gopls" })

policy.declare("lsp", { "gopls" })
check("declaring the same entry twice does not duplicate it", policy.get_declared "lsp", { "basedpyright", "gopls" })

check_error("declaring an unknown category raises", function() policy.declare("nonsense", { "x" }) end)

policy._reset()
check("get_declared is empty until something declares", policy.get_declared "lsp", {})

-- Regression coverage for the bug this fix addresses: "configured" must come
-- from what a pack actually declared, not from "does lspconfig know this
-- server at all" (which is true for nearly everything, including servers
-- with nothing to do with the filetype in question, e.g. a general grammar
-- checker showing up for a Go file).
policy._reset()
policy.declare("lsp", { "gopls" })
local function to_package_go(server) return ({ gopls = "gopls", harper_ls = "harper-ls" })[server] end
check(
  "selection uses the declared set: an undeclared server that merely serves "
    .. "the filetype (e.g. a general-purpose server lspconfig also knows about) is excluded",
  policy.packages_to_install(policy.get_declared "lsp", { "gopls", "harper_ls" }, {}, to_package_go),
  { "gopls" }
)

-- on_demand: Mason packages a bundle attributes to filetypes by hand, for
-- tooling the integration plugins' own mapping tables cannot route.
policy._reset()
check("get_on_demand is empty for an unattributed filetype", policy.get_on_demand "go", {})

policy.on_demand("go", { "gotests", "impl" })
check("on_demand records packages against a filetype", policy.get_on_demand "go", { "gotests", "impl" })

policy.on_demand("go", { "iferr", "gotests" })
check("repeat on_demand calls are additive and deduplicated", policy.get_on_demand "go", { "gotests", "iferr", "impl" })

policy.on_demand({ "typescript", "javascript" }, { "js-debug-adapter" })
check("on_demand accepts a list of filetypes", policy.get_on_demand "typescript", { "js-debug-adapter" })
check("on_demand applies to every filetype in the list", policy.get_on_demand "javascript", { "js-debug-adapter" })
check("on_demand does not leak to an unrelated filetype", policy.get_on_demand "lua", {})

-- resolve_installs unions every category plus the hand-attributed packages.
-- Stub adapters stand in for mason-lspconfig/mason-null-ls/mason-nvim-dap.
local function stub(serving_by_filetype, packages)
  return {
    module = "stub",
    serving = function(filetype) return serving_by_filetype[filetype] or {} end,
    to_package = function(name) return packages[name] end,
  }
end

policy._reset()
policy.declare("lsp", { "gopls" })
policy.declare("tools", { "goimports" })
policy.declare("dap", { "delve" })
policy.on_demand("go", { "gotests" })

local go_adapters = {
  lsp = stub({ go = { "gopls" } }, { gopls = "gopls" }),
  tools = stub({ go = { "goimports", "gofumpt" } }, { goimports = "goimports", gofumpt = "gofumpt" }),
  dap = stub({ go = { "delve" } }, { delve = "delve" }),
}

check(
  "resolve_installs unions lsp, tools, dap and hand-attributed packages",
  policy.resolve_installs("go", {}, go_adapters),
  { "delve", "goimports", "gopls", "gotests" }
)

check(
  "resolve_installs skips packages already installed, including attributed ones",
  policy.resolve_installs("go", { gopls = true, delve = true, gotests = true }, go_adapters),
  { "goimports" }
)

check(
  "resolve_installs excludes a tool that serves the filetype but nothing declared",
  policy.resolve_installs("go", { goimports = true, gopls = true, delve = true, gotests = true }, go_adapters),
  {}
)

check("resolve_installs returns nothing for an unrelated filetype", policy.resolve_installs("lua", {}, go_adapters), {})

-- The tools/dap regression this fix addresses: before the matching `declare`
-- calls existed, the overwrite in lazy_setup.lua deleted these lists outright
-- and nothing could reinstate them.
policy._reset()
check(
  "an undeclared tools category installs nothing, even when a tool serves the filetype",
  policy.resolve_installs("go", {}, go_adapters),
  {}
)

if failures > 0 then
  print(("\n%d test(s) failed"):format(failures))
  vim.cmd "cquit 1"
end
print "\nall tests passed"
