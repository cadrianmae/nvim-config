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

if failures > 0 then
  print(("\n%d test(s) failed"):format(failures))
  vim.cmd "cquit 1"
end
print "\nall tests passed"
